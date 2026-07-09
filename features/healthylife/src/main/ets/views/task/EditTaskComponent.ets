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
import TaskInfoApi from 'common/src/main/ets/database/tables/TaskInfoApi';
import { openTargetSettingCustomDialog } from '../dialog/TargetSettingDialog';
import { openReminderSettingCustomDialog } from '../dialog/ReminderSettingDialog';
import DayTaskInfoApi from 'common/src/main/ets/database/tables/DayTaskInfoApi';
import { TargetSettingDialogParams } from '../../viewmodel/dialog/TargetSettingDialogParams';
import {
  ReminderSettingDialogParams,
  ReminderSettingType
} from '../../viewmodel/dialog/ReminderSettingDialogParams';
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
    if (this.taskInfo.isAlert) {
      let isRequestSuccess = await RequestAuthorization.requestNotification(this.getUIContext());
      if (!isRequestSuccess) {
        return;
      }
      if (this.taskInfo.reminderId !== -1) {
        await AgentUtils.updateAgent(this.taskInfo, this.taskBaseInfo, this.getUIContext());
        hilog.info(0x0000, TAG, `update reminderId successed, reminderId is ${this.taskInfo.reminderId}`);
        return;
      }
      let reminderId = await AgentUtils.creatAgent(this.taskInfo, this.taskBaseInfo, this.getUIContext());
      this.taskInfo.reminderId = reminderId;
      await TaskInfoApi.update(this.taskInfo.taskId, this.taskInfo);
      hilog.info(0x0000, TAG, `create reminderId successed, reminderId is ${reminderId}`);
      return;
    }
    if (this.taskInfo.reminderId !== -1) {
      AgentUtils.deleteAgent(this.taskInfo.reminderId);
      hilog.info(0x0000, TAG, `delete reminderId successed, reminderId is ${this.taskInfo.reminderId}`);
      this.taskInfo.reminderId = -1;
      await TaskInfoApi.update(this.taskInfo.taskId, this.taskInfo);
    }
  }

  async finishTaskEdit() {
    this.ensureReminderDefaults();
    if (this.originalInfo.isTaskEqual(this.taskInfo)) {
      this.pageStack.clear(true);
      return;
    }
    const statusUnchanged =
      (this.originalInfo.isOpen && this.taskInfo.isOpen) || (!this.originalInfo.isOpen && !this.taskInfo.isOpen);
    if (statusUnchanged) {
      // the task status has not changed, and only the other information of the task needs to be updated.
      await TaskInfoApi.update(this.taskInfo.taskId, this.taskInfo);
      if (this.originalInfo.isOpen) {
        // the current task is open, need to synchronize the update day task information.
        await DayTaskInfoApi.queryKeyByDateAndTaskId(this.homeStore.currentDate, this.taskInfo.taskId)
          .then(async (key: number) => {
            await DayTaskInfoApi.update(key, this.taskInfo.convert2DayTask(this.homeStore.currentDate));
          })
        await this.syncReminderAgent();
      }
    } else {
      // the task status has changed, need to update the task information before modifying the task status.
      this.taskInfo.isOpen = this.originalInfo.isOpen;
      if (!this.originalInfo.isTaskEqual(this.taskInfo)) {
        await TaskInfoApi.update(this.taskInfo.taskId, this.taskInfo);
      }
      if (!this.taskInfo.isOpen) {
        await TaskInfoApi.openTask(this.homeStore.currentDate, this.taskInfo.taskId);
        this.taskInfo.isOpen = true;
        await this.syncReminderAgent();
      } else {
        await TaskInfoApi.closeTask(this.homeStore.currentDate, this.taskInfo.taskId);
        // Check the reminderId, if it exists, the proxy reminder needs to be turned off.
        if (this.taskBaseInfo.supportReminder) {
          let taskInfo = await TaskInfoApi.queryByKey(this.taskInfo.taskId);
          if (taskInfo && taskInfo.reminderId !== -1) {
            AgentUtils.deleteAgent(taskInfo.reminderId);
            hilog.info(0x0000, TAG, `delete reminderId successed, reminderId is ${taskInfo.reminderId}`);
          }
        }
      }
    }
    await updateTaskList(this.homeStore);
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
            this.reminderRowBuilder($r('app.string.reminder_frequency'), ReminderSettingType.FREQUENCY)
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

  private getReminderFrequencyText(): Resource {
    switch (this.taskInfo.alertFrequency) {
      case Const.REMINDER_FREQUENCY_WEEKDAY:
        return $r('app.string.reminder_frequency_weekday');
      case Const.REMINDER_FREQUENCY_WEEKEND:
        return $r('app.string.reminder_frequency_weekend');
      case Const.REMINDER_FREQUENCY_DAILY:
      default:
        return $r('app.string.reminder_frequency_daily');
    }
  }

  @Builder
  reminderRowBuilder(label: Resource, settingType: ReminderSettingType) {
    Row() {
      Text(label)
        .fontWeight(FontWeight.Medium)
        .fontSize($r('app.float.default_18'))

      Blank()

      Text(settingType === ReminderSettingType.TIME ? this.taskInfo.alertStartTime : this.getReminderFrequencyText())
        .fontSize($r('app.float.default_16'))
        .fontColor($r('sys.color.font_primary'))
        .padding({
          right: $r('app.float.default_6')
        })

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
    .enabled(this.taskInfo.isOpen && this.taskInfo.isAlert)
    .onClick(() => {
      let params = new ReminderSettingDialogParams(this.taskInfo, settingType);
      openReminderSettingCustomDialog(this.getUIContext(), params);
    })
  }
}
