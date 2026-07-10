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

import TaskInfoApi from 'common/src/main/ets/database/tables/TaskInfoApi';
import { CommonConstants as Const, taskBaseInfoList, TaskInfo } from 'common';
import { HomeStore } from '../../viewmodel/HomeStore';

@Builder
export function addTaskBuilder() {
  AddTaskComponent();
}

@Component
export struct AddTaskComponent {
  @Consume('pathStack') pageStack: NavPathStack;
  @Consume homeStore: HomeStore;
  @State taskList: TaskInfo[] = [];
  @State flag: boolean = false;

  async aboutToAppear(): Promise<void> {
    await TaskInfoApi.reconcileDailyTaskState(this.homeStore.currentDate);
    this.taskList = await TaskInfoApi.queryAllTaskInfo();
    this.flag = true;
  }

  build() {
    NavDestination() {
      if (this.flag) {
        Column({
          space: $r('app.float.default_12')
        }) {
          ForEach(this.taskList, (item: TaskInfo, index: number) => {
            this.taskInfoBuilder(item, index)
          }, (item: TaskInfo, index: number) => index + JSON.stringify(item))
        }
        .width(Const.THOUSANDTH_940)
        .justifyContent(FlexAlign.Center)
        .margin($r('app.float.default_8'))
      }
    }
    .size({
      width: Const.THOUSANDTH_1000,
      height: Const.THOUSANDTH_1000
    })
    .backgroundColor($r('sys.color.background_secondary'))
    .title($r('app.string.add_task'))
    .padding({
      top: $r('app.float.default_40'),
      left:$r('app.float.default_6'),
      right:$r('app.float.default_6')
    })
  }

  @Builder
  taskInfoBuilder(item: TaskInfo, _index: number) {
    Row() {
      Image(taskBaseInfoList[item.taskId].icon)
        .width($r('app.float.default_24'))
        .height($r('app.float.default_24'))
        .objectFit(ImageFit.Contain)
        .margin({
          right: $r('app.float.default_8')
        })

      Text(taskBaseInfoList[item.taskId].name)
        .fontColor($r(`sys.color.font_primary`))
        .fontSize($r('app.float.default_18'))

      Blank();

      Text(this.getTaskStatus(item))
        .fontColor($r(`sys.color.font_primary`))
        .fontSize($r('app.float.default_16'))
        .margin({
          right: $r('app.float.default_8')
        })
        .visibility(item.isOpen ? Visibility.Visible : Visibility.Hidden)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontColor([$r('sys.color.icon_secondary')])
        .fontWeight(FontWeight.Normal)
        .fontSize($r('app.float.default_28'))
    }
    .width(Const.THOUSANDTH_1000)
    .height(Const.THOUSANDTH_80)
    .borderRadius($r('app.float.default_16'))
    .padding({
      left: $r('app.float.default_12'),
      right: $r('app.float.default_12')
    })
    .backgroundColor($r('sys.color.background_primary'))
    .onClick(() => {
      this.pageStack.pushPath({ name: 'EditTaskComponent', param: item });
    })
  }

  private getTaskStatus(item: TaskInfo): string {
    if (!item.isOpen) {
      return '';
    }
    if (item.repeatDays === Const.REPEAT_DAYS_ONCE) {
      return this.getResourceString($r('app.string.task_today_added'));
    }
    let schedule = this.getRepeatSummary(item);
    try {
      return this.getUIContext().getHostContext()?.resourceManager
        .getStringSync($r('app.string.task_enabled_with_schedule').id, schedule) || schedule;
    } catch (error) {
      console.error(`getTaskStatus failed: ${error}`);
      return schedule;
    }
  }

  private getRepeatSummary(item: TaskInfo): string {
    let preset: Resource | undefined = undefined;
    if (item.repeatDays === Const.REPEAT_DAYS_DAILY) {
      preset = $r('app.string.repeat_daily');
    } else if (item.repeatDays === Const.REPEAT_DAYS_WEEKDAY) {
      preset = $r('app.string.repeat_weekday');
    } else if (item.repeatDays === Const.REPEAT_DAYS_WEEKEND) {
      preset = $r('app.string.repeat_weekend');
    }
    if (preset) {
      return this.getResourceString(preset);
    }
    const days: number[] = [1, 2, 3, 4, 5, 6, 0];
    let labels: string[] = [];
    for (let index = 0; index < days.length; index++) {
      if ((item.repeatDays & (1 << days[index])) !== 0) {
        labels.push(this.getResourceString(Const.WEEK_SHORTHAND_LIST[index]));
      }
    }
    return labels.join('、');
  }

  private getResourceString(resource: Resource): string {
    try {
      return this.getUIContext().getHostContext()?.resourceManager.getStringSync(resource.id) || '';
    } catch (error) {
      console.error(`getResourceString failed: ${error}`);
      return '';
    }
  }
}
