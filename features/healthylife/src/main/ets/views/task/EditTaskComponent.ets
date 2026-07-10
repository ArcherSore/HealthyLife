/*
 *
 *  * Copyright (c) 2025 Huawei Device Co., Ltd.
 *  * Licensed under the Apache License, Version 2.0 (the "License");
 *  * you may not use this file except in compliance with the License.
 *  * You may obtain a copy of the License at
 *  *
 *  *     http://www.apache.org/licenses/LICENSE-2.0
 *  *
 *  * Unless required by applicable law or agreed to in writing, software
 *  * distributed under the License is distributed on an "AS IS" BASIS,
 *  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  * See the License for the specific language governing permissions and
 *  * limitations under the License.
 *
 */

import { HomeStore, updateTaskList } from '../../viewmodel/HomeStore';
import { AchievementStore, syncStreaksFromDb, syncTaskOverAchievementDb } from '../../viewmodel/AchievementStore';
import TaskInfoApi from 'common/src/main/ets/database/tables/TaskInfoApi';
import { openTargetSettingCustomDialog } from '../dialog/TargetSettingDialog';
import { openReminderSettingCustomDialog } from '../dialog/ReminderSettingDialog';
import { openRepeatSettingCustomDialog } from '../dialog/RepeatSettingDialog';
import { TargetSettingDialogParams } from '../../viewmodel/dialog/TargetSettingDialogParams';
import {
  ReminderSettingDialogParams,
  ReminderSettingType
} from '../../viewmodel/dialog/ReminderSettingDialogParams';
import { RepeatSettingDialogParams } from '../../viewmodel/dialog/RepeatSettingDialogParams';
import {
  AgentUtils,
  CommonConstants as Const,
  PickerType,
  RequestAuthorization,
  TaskBaseInfo,
  taskBaseInfoList,
  TaskInfo
} from 'common';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'EditTaskComponent'

@Builder
export function editTaskBuilder(_name: string, param: TaskInfo) {
  EditTaskComponent({
    taskInfo: param,
    originalInfo: param.deepClone(),
    taskBaseInfo: taskBaseInfoList[param.taskId]
  });
}

@Extend(Text)
function targetValueStyle(isOpen: boolean, pickerType: PickerType) {
  .fontSize($r('app.float.default_16'))
  .fontColor((isOpen && pickerType !== PickerType.NONE) ? $r('sys.color.font_primary') : $r('sys.color.font_tertiary'))
  .padding({
    right: $r('app.float.default_6')
  })
}

@Component
export struct EditTaskComponent {
  @Consume('pathStack') pageStack: NavPathStack;
  @Consume homeStore: HomeStore;
  @Consume achievementStore: AchievementStore;
  @Provide taskInfo: TaskInfo = new TaskInfo(0, false, '', '', false, false, '', '', '', -1);
  @Provide taskBaseInfo: TaskBaseInfo = taskBaseInfoList[this.taskInfo.taskId];
  originalInfo: TaskInfo = this.taskInfo;

  aboutToAppear(): void {
    this.ensureReminderDefaults();
    this.originalInfo = this.taskInfo.deepClone();
  }

  private ensureReminderDefaults() {
    if (!this.taskBaseInfo.supportReminder) {
      return;
    }
    this.taskInfo.alertStartTime =
      this.taskInfo.alertStartTime || (this.taskBaseInfo.pickerType === PickerType.TIME ? this.taskInfo.targetValue : '08:00');
    this.taskInfo.alertFrequency = this.taskInfo.alertFrequency || Const.REMINDER_FREQUENCY_DAILY;
  }

  private async syncReminderAgent() {
    if (!this.taskBaseInfo.supportReminder || !this.taskInfo.isOpen) {
      return;
    }
    this.ensureReminderDefaults();
    let shouldSchedule = AgentUtils.shouldScheduleReminder(this.taskInfo, this.homeStore.currentDate);
    if (this.taskInfo.isAlert && shouldSchedule) {
      let isRequestSuccess = await RequestAuthorization.requestNotification(this.getUIContext());
      if (!isRequestSuccess) {
        return;
      }
      if (this.taskInfo.reminderId !== -1) {
        let updateResult = await AgentUtils.updateAgent(this.taskInfo, this.taskBaseInfo, this.homeStore.currentDate,
          this.getUIContext());
        if (updateResult) {
          hilog.info(0x0000, TAG, `update reminderId successed, reminderId is ${this.taskInfo.reminderId}`);
          return;
        }
        if (!await AgentUtils.deleteAgent(this.taskInfo.reminderId)) {
          return;
        }
        this.taskInfo.reminderId = -1;
      }
      let reminderId = await AgentUtils.creatAgent(this.taskInfo, this.taskBaseInfo, this.homeStore.currentDate,
        this.getUIContext());
      this.taskInfo.reminderId = reminderId;
      await TaskInfoApi.update(this.taskInfo.taskId, this.taskInfo);
      hilog.info(0x0000, TAG, `create reminderId successed, reminderId is ${reminderId}`);
      return;
    }
    if (this.taskInfo.reminderId !== -1) {
      let reminderId = this.taskInfo.reminderId;
      if (await AgentUtils.deleteAgent(reminderId)) {
        hilog.info(0x0000, TAG, `delete reminderId successed, reminderId is ${reminderId}`);
        this.taskInfo.reminderId = -1;
        await TaskInfoApi.update(this.taskInfo.taskId, this.taskInfo);
      }
    }
  }

  async finishTaskEdit() {
    this.ensureReminderDefaults();
    if (this.originalInfo.isTaskEqual(this.taskInfo)) {
      this.pageStack.clear(true);
      return;
    }
    if (!this.taskInfo.isOpen) {
      if (this.originalInfo.isOpen) {
        await TaskInfoApi.closeTask(this.homeStore.currentDate, this.taskInfo.taskId);
        this.taskInfo.isAlert = false;
        this.taskInfo.reminderId = -1;
      } else {
        await TaskInfoApi.update(this.taskInfo.taskId, this.taskInfo);
      }
    } else {
      if (!this.originalInfo.isOpen) {
        this.taskInfo.scheduleStartDate = this.homeStore.currentDate;
        this.taskInfo.finValue = '';
        this.taskInfo.isDone = false;
      }
      await TaskInfoApi.saveTaskPlan(this.homeStore.currentDate, this.taskInfo);
      await this.syncReminderAgent();
    }
    await updateTaskList(this.homeStore);
    await syncStreaksFromDb(this.achievementStore, this.getUIContext());
    await syncTaskOverAchievementDb(this.achievementStore, this.getUIContext(), this.taskInfo.taskId);
    this.pageStack.clear(true);
  }

  build() {
    NavDestination() {
      Column({
        space: $r('app.float.default_12')
      }) {
        Row() {
          Text(this.taskBaseInfo.name)
            .fontWeight(FontWeight.Medium)
            .fontSize($r('app.float.default_18'))

          Toggle({
            type: ToggleType.Switch,
            isOn: this.taskInfo.isOpen
          })
            .width($r('app.float.default_36'))
            .height($r('app.float.default_20'))
            .onChange((isOn) => {
              this.taskInfo.isOpen = isOn;
              if (!isOn && this.taskBaseInfo.supportReminder) {
                this.taskInfo.isAlert = false;
              }
            })
        }
        .width(Const.THOUSANDTH_940)
        .justifyContent(FlexAlign.SpaceBetween)
        .backgroundColor($r('sys.color.background_primary'))
        .height($r('app.float.default_56'))
        .borderRadius($r('app.float.default_16'))
        .padding({
          left: $r('app.float.default_12'),
          right: $r('app.float.default_12')
        })

        Row() {
          Text($r('app.string.target_setting'))
            .fontWeight(FontWeight.Medium)
            .fontSize($r('app.float.default_18'))

          Blank()

          Text(this.taskInfo.targetValue)
            .targetValueStyle(this.taskInfo.isOpen, this.taskBaseInfo.pickerType)

          if (this.taskBaseInfo.unit !== '') {
            Text(this.taskBaseInfo.unit)
              .targetValueStyle(this.taskInfo.isOpen, this.taskBaseInfo.pickerType)

            Text($r('app.string.unit_pre_day'))
              .targetValueStyle(this.taskInfo.isOpen, this.taskBaseInfo.pickerType)
          }

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontColor([$r('sys.color.icon_secondary')])
            .fontSize($r('app.float.default_28'))
        }
        .width(Const.THOUSANDTH_940)
        .height($r('app.float.default_56'))
        .borderRadius($r('app.float.default_16'))
        .backgroundColor($r('sys.color.background_primary'))
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({
          left: $r('app.float.default_12'),
          right: $r('app.float.default_12')
        })
        .enabled(true)
        .onClick(() => {
          if (this.taskInfo.isOpen && this.taskBaseInfo.pickerType !== PickerType.NONE) {
            let params = new TargetSettingDialogParams(this.taskInfo, this.taskBaseInfo);
            openTargetSettingCustomDialog(this.getUIContext(), params);
          }
        })

        Row() {
          Text($r('app.string.repeat_setting'))
            .fontWeight(FontWeight.Medium)
            .fontSize($r('app.float.default_18'))

          Blank()

          Text(this.getRepeatSummary())
            .fontSize($r('app.float.default_16'))
            .fontColor(this.taskInfo.isOpen ? $r('sys.color.font_primary') : $r('sys.color.font_tertiary'))
            .padding({ right: $r('app.float.default_6') })

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontColor([this.taskInfo.isOpen ? $r('sys.color.icon_secondary') : $r('sys.color.font_tertiary')])
            .fontSize($r('app.float.default_28'))
        }
        .width(Const.THOUSANDTH_940)
        .height($r('app.float.default_56'))
        .borderRadius($r('app.float.default_16'))
        .backgroundColor($r('sys.color.background_primary'))
        .padding({ left: $r('app.float.default_12'), right: $r('app.float.default_12') })
        .enabled(this.taskInfo.isOpen)
        .opacity(this.taskInfo.isOpen ? Const.ANIMATE_OPACITY_1 : 0.4)
        .onClick(() => {
          if (this.taskInfo.isOpen) {
            openRepeatSettingCustomDialog(this.getUIContext(), new RepeatSettingDialogParams(this.taskInfo));
          }
        })

        if (this.taskBaseInfo.supportReminder) {
          Row() {
            Text($r('app.string.reminder_enable'))
              .fontWeight(FontWeight.Medium)
              .fontSize($r('app.float.default_18'))

            Toggle({
              type: ToggleType.Switch,
              isOn: this.taskInfo.isAlert
            })
              .width($r('app.float.default_36'))
              .height($r('app.float.default_20'))
              .enabled(this.taskInfo.isOpen)
              .onChange((isOn) => {
                this.taskInfo.isAlert = isOn;
                if (isOn) {
                  this.ensureReminderDefaults();
                }
              })
          }
          .width(Const.THOUSANDTH_940)
          .justifyContent(FlexAlign.SpaceBetween)
          .backgroundColor($r('sys.color.background_primary'))
          .height($r('app.float.default_56'))
          .borderRadius($r('app.float.default_16'))
          .padding({
            left: $r('app.float.default_12'),
            right: $r('app.float.default_12')
          })
          .opacity(this.taskInfo.isOpen ? Const.ANIMATE_OPACITY_1 : 0.4)

          if (this.taskInfo.isAlert) {
            this.reminderRowBuilder($r('app.string.reminder_time'), ReminderSettingType.TIME)
          }
        }

        Button() {
          Text($r('app.string.complete'))
            .fontSize($r('app.float.default_18'))
        }
        .buttonStyle(ButtonStyleMode.NORMAL)
        .width(Const.THOUSANDTH_940)
        .height($r('app.float.default_40'))
        .backgroundColor($r('sys.color.button_background_color_transparent'))
        .position({
          x: Const.THOUSANDTH_30,
          y: Const.THOUSANDTH_880
        })
        .onClick(async () => {
          await this.finishTaskEdit();
        })
      }
      .width(Const.THOUSANDTH_1000)
      .justifyContent(FlexAlign.Center)
      .margin($r('app.float.default_8'))
    }
    .size({
      width: Const.THOUSANDTH_1000,
      height: Const.THOUSANDTH_1000
    })
    .title($r('app.string.edit_task'))
    .padding({
      top: $r('app.float.default_40'),
      left:$r('app.float.default_6'),
      right:$r('app.float.default_6')
    })
    .backgroundColor($r('sys.color.background_secondary'))
  }

  private getRepeatSummary(): ResourceStr {
    switch (this.taskInfo.repeatDays) {
      case Const.REPEAT_DAYS_ONCE:
        return $r('app.string.repeat_once');
      case Const.REPEAT_DAYS_DAILY:
        return $r('app.string.repeat_daily');
      case Const.REPEAT_DAYS_WEEKDAY:
        return $r('app.string.repeat_weekday');
      case Const.REPEAT_DAYS_WEEKEND:
        return $r('app.string.repeat_weekend');
      default:
        return this.getCustomRepeatSummary();
    }
  }

  private getCustomRepeatSummary(): string {
    let labels: string[] = [];
    const days: number[] = [1, 2, 3, 4, 5, 6, 0];
    try {
      for (let index = 0; index < days.length; index++) {
        if ((this.taskInfo.repeatDays & (1 << days[index])) !== 0) {
          labels.push(this.getUIContext().getHostContext()?.resourceManager
            .getStringSync(Const.WEEK_SHORTHAND_LIST[index].id) || '');
        }
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Get repeat summary failed: ${error}`);
    }
    return labels.join('、');
  }

  @Builder
  reminderRowBuilder(label: Resource, settingType: ReminderSettingType) {
    Row() {
      Text(label)
        .fontWeight(FontWeight.Medium)
        .fontSize($r('app.float.default_18'))

      Blank()

      Text(this.taskInfo.alertStartTime)
        .fontSize($r('app.float.default_16'))
        .fontColor((this.taskInfo.isOpen && this.taskInfo.isAlert) ? $r('sys.color.font_primary') :
          $r('sys.color.font_tertiary'))
        .padding({
          right: $r('app.float.default_6')
        })

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontColor([(this.taskInfo.isOpen && this.taskInfo.isAlert) ? $r('sys.color.icon_secondary') :
          $r('sys.color.font_tertiary')])
        .fontSize($r('app.float.default_28'))
    }
    .width(Const.THOUSANDTH_940)
    .height($r('app.float.default_56'))
    .borderRadius($r('app.float.default_16'))
    .backgroundColor($r('sys.color.background_primary'))
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({
      left: $r('app.float.default_12'),
      right: $r('app.float.default_12')
    })
    .enabled(this.taskInfo.isOpen && this.taskInfo.isAlert)
    .onClick(() => {
      if (!this.taskInfo.isOpen || !this.taskInfo.isAlert) {
        return;
      }
      let params = new ReminderSettingDialogParams(this.taskInfo, settingType);
      openReminderSettingCustomDialog(this.getUIContext(), params);
    })
  }
}
