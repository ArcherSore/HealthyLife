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
import { AchievementStore } from '../../viewmodel/AchievementStore';
import TaskInfoApi from 'common/src/main/ets/database/tables/TaskInfoApi';
import { openTaskClockCustomDialog } from '../dialog/TaskClockCustomDialog';
import { TaskInfoDialogParams } from '../../viewmodel/dialog/TaskInfoDialogParams';
import { CommonConstants as Const, DayTaskInfo, taskBaseInfoList } from 'common';

@Component
export struct TaskListComponent {
  @Consume('pathStack') pageStack: NavPathStack;
  @Consume homeStore: HomeStore;
  @Consume achievementStore: AchievementStore;
  private listScroller: ListScroller = new ListScroller();
  private readonly TASK_CARD_HEIGHT: number = 62;
  private readonly TASK_CARD_SPACE: number = 12;

  build() {
    if (this.homeStore.taskList.length > 0) {
      List({
        space: this.TASK_CARD_SPACE,
        scroller: this.listScroller
      }) {
        ForEach(this.homeStore.taskList, (item: DayTaskInfo, index: number) => {
          this.taskListItemBuilder(item, index)
        }, (item: DayTaskInfo, index: number) => index + JSON.stringify(item))
      }
      .width(Const.THOUSANDTH_1000)
      .height(this.getTaskListHeight())
      .padding({
        top: Const.THOUSANDTH_15,
        left:$r('app.float.default_16'),
        right:$r('app.float.default_16')
      })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)
      .onScrollStart(() => {
        this.closeSwipeActions();
      })
    } else {
      Column() {
        Image($r('app.media.ic_no_data'))
          .width($r('app.float.default_132'))
          .height($r('app.float.default_100'))
          .margin({
            bottom: $r('app.float.default_8')
          })

        Text($r('app.string.no_task'))
          .fontFamily(Const.HARMONY_HEI_TI_MEDIUM)
          .fontWeight(FontWeight.Regular)
          .fontColor($r(`sys.color.font_secondary`))
          .fontSize($r('app.float.default_14'))
      }
      .width(Const.THOUSANDTH_1000)
      .margin({
        top: $r('app.float.default_48')
      })
    }
  }

  @Builder
  taskListItemBuilder(item: DayTaskInfo, _index: number) {
    if (this.homeStore.checkCurrentDay()) {
      ListItem() {
        this.taskCardBuilder(item)
      }
      .transition(TransitionEffect.OPACITY)
      .swipeAction({
        end: {
          builder: () => {
            this.removeActionBuilder(item)
          }
        },
        edgeEffect: SwipeEdgeEffect.None
      })
    } else {
      ListItem() {
        this.taskCardBuilder(item)
      }
    }
  }

  @Builder
  taskCardBuilder(item: DayTaskInfo) {
    Row() {
      Image(taskBaseInfoList[item.taskId].icon)
        .width($r('app.float.default_36'))
        .height($r('app.float.default_36'))
        .objectFit(ImageFit.Contain)
        .margin({
          right: $r('app.float.default_8')
        })

      Text(taskBaseInfoList[item.taskId].name)
        .fontFamily(Const.HARMONY_HEI_TI_MEDIUM)
        .fontWeight(FontWeight.Regular)
        .fontColor($r(`sys.color.font_primary`))
        .fontSize($r('app.float.default_16'))

      Blank()

      this.targetValueBuilder(item)
    }
    .width(Const.THOUSANDTH_1000)
    .height($r('app.float.default_62'))
    .borderRadius($r('app.float.default_16'))
    .padding({
      left: Const.THOUSANDTH_50,
      right: Const.THOUSANDTH_50
    })
    .backgroundColor($r('sys.color.background_primary'))
    .onClick(() => {
      if (this.homeStore.checkCurrentDay()) {
        this.closeSwipeActions();
        let params = new TaskInfoDialogParams(item, this.homeStore, this.achievementStore, this.getUIContext());
        openTaskClockCustomDialog(this.getUIContext(), params);
      }
    })
    .gesture(LongPressGesture().onAction(async () => {
      if (this.homeStore.checkCurrentDay()) {
        let taskInfo = await TaskInfoApi.queryByKey(item.taskId);
        this.pageStack.pushPath({ name: 'EditTaskComponent', param: taskInfo });
      }
    }))
  }

  @Builder
  removeActionBuilder(item: DayTaskInfo) {
    Row() {
      Column() {
        SymbolGlyph($r('sys.symbol.trash'))
          .fontColor([Color.White])
          .fontSize($r('app.float.default_22'))

        Text($r('app.string.remove_task'))
          .fontFamily(Const.HARMONY_HEI_TI_MEDIUM)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .fontSize($r('app.float.default_14'))
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .width($r('app.float.default_72'))
      .height($r('app.float.default_62'))
      .borderRadius($r('app.float.default_16'))
      .backgroundColor($r('app.color.button_red'))
      .onClick(() => {
        this.showRemoveConfirmDialog(item);
      })
    }
    .width($r('app.float.default_88'))
    .height($r('app.float.default_62'))
    .justifyContent(FlexAlign.End)
  }

  private showRemoveConfirmDialog(item: DayTaskInfo): void {
    this.closeSwipeActions();
    this.getUIContext().showAlertDialog({
      title: $r('app.string.remove_task_dialog_title'),
      message: $r('app.string.remove_task_dialog_message'),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => {
          this.closeSwipeActions();
        }
      },
      secondaryButton: {
        value: $r('app.string.remove_task'),
        fontColor: $r('app.color.button_red'),
        action: async () => {
          await this.removeTask(item);
        }
      }
    })
  }

  private async removeTask(item: DayTaskInfo): Promise<void> {
    if (!this.homeStore.checkCurrentDay()) {
      return;
    }
    let result = await TaskInfoApi.closeTask(this.homeStore.currentDate, item.taskId);
    if (result) {
      await updateTaskList(this.homeStore);
      this.showToast($r('app.string.remove_task_success'));
      return;
    }
    this.showToast($r('app.string.remove_task_failed'));
  }

  private closeSwipeActions(): void {
    try {
      this.listScroller.closeAllSwipeActions();
    } catch (error) {
      console.error(`close swipe actions failed: ${error}`);
    }
  }

  private showToast(message: Resource): void {
    try {
      this.getUIContext().getPromptAction().showToast({
        message: message
      });
    } catch (error) {
      console.error(`showToast failed: ${error}`);
    }
  }

  private getTaskListHeight(): string {
    let taskCount = this.homeStore.taskList.length;
    return `${taskCount * this.TASK_CARD_HEIGHT + (taskCount - 1) * this.TASK_CARD_SPACE}vp`;
  }

  @Builder
  targetValueBuilder(item: DayTaskInfo) {
    if (item.isDone) {
      this.taskValueBuilder($r('app.string.was_done'), $r(`sys.color.font_primary`))
    } else {
      Row() {
        this.taskValueBuilder((item.finValue || `--`), $r(`sys.color.font_primary`))

        this.taskValueBuilder(` / ${item.targetValue} `, $r(`sys.color.font_primary`))

        this.taskValueBuilder(taskBaseInfoList[item.taskId].unit, $r(`sys.color.font_primary`))
      }
    }
  }

  @Builder
  taskValueBuilder(content: ResourceStr, fontColor: Resource) {
    Text(content)
      .fontFamily(Const.HARMONY_HEI_TI_MEDIUM)
      .fontWeight(FontWeight.Regular)
      .fontColor(fontColor)
      .fontSize($r('app.float.default_16'))
  }
}
