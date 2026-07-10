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
import { openTaskClockCustomDialog } from '../dialog/TaskClockCustomDialog';
import { TaskInfoDialogParams } from '../../viewmodel/dialog/TaskInfoDialogParams';
import { CommonConstants as Const, DayTaskInfo, taskBaseInfoList } from 'common';
import { openTaskRemoveCustomDialog } from '../dialog/TaskRemoveDialog';
import { TaskRemoveDialogParams } from '../../viewmodel/dialog/TaskRemoveDialogParams';

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
      .nestedScroll({
        scrollForward: NestedScrollMode.PARENT_FIRST,
        scrollBackward: NestedScrollMode.PARENT_FIRST
      })
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
        TaskCardComponent({
          item: item,
          clickCallback: () => {
            this.closeSwipeActions();
            let params = new TaskInfoDialogParams(item, this.homeStore, this.achievementStore, this.getUIContext());
            openTaskClockCustomDialog(this.getUIContext(), params);
          }
        })
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
        TaskCardComponent({
          item: item,
          clickCallback: () => {}
        })
      }
    }
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
    TaskInfoApi.queryByKey(item.taskId).then((taskInfo) => {
      if (!taskInfo) {
        this.showToast($r('app.string.remove_task_failed'));
        return;
      }
      const params = new TaskRemoveDialogParams(taskBaseInfoList[item.taskId].name, item.isDone,
        taskInfo.repeatDays !== Const.REPEAT_DAYS_ONCE, () => this.skipTask(item), () => this.stopTask(item));
      openTaskRemoveCustomDialog(this.getUIContext(), params);
    });
  }

  private async skipTask(item: DayTaskInfo): Promise<void> {
    if (!this.homeStore.checkCurrentDay()) {
      return;
    }
    let result = await TaskInfoApi.skipTaskForDate(this.homeStore.currentDate, item.taskId);
    if (result) {
      await updateTaskList(this.homeStore);
      await syncStreaksFromDb(this.achievementStore, this.getUIContext());
      await syncTaskOverAchievementDb(this.achievementStore, this.getUIContext(), item.taskId);
      this.showToast($r('app.string.skip_today_success'));
      return;
    }
    this.showToast($r('app.string.remove_task_failed'));
  }

  private async stopTask(item: DayTaskInfo): Promise<void> {
    if (!this.homeStore.checkCurrentDay()) {
      return;
    }
    let result = await TaskInfoApi.closeTask(this.homeStore.currentDate, item.taskId);
    if (result) {
      await updateTaskList(this.homeStore);
      await syncStreaksFromDb(this.achievementStore, this.getUIContext());
      await syncTaskOverAchievementDb(this.achievementStore, this.getUIContext(), item.taskId);
      this.showToast($r('app.string.stop_repeat_success'));
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
}

@Component
struct TaskCardComponent {
  @Prop @Watch('drawProgress') item: DayTaskInfo;
  @Consume('pathStack') pageStack: NavPathStack;
  @Consume homeStore: HomeStore;
  @Consume achievementStore: AchievementStore;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  @State cardWidthVp: number = 0;
  @State cardHeightVp: number = 0;
  private isReady: boolean = false;
  clickCallback: () => void = () => {};

  drawProgress() {
    const ctx = this.context;
    const w = this.cardWidthVp;
    const h = this.cardHeightVp;
    if (w <= 0 || h <= 0 || !this.isReady) {
      return;
    }

    ctx.clearRect(0, 0, w, h);

    const progress = this.calculateTaskProgress(this.item);
    if (progress <= 0) {
      return;
    }

    const r = 16;
    const strokeWidth = 3;

    ctx.lineWidth = strokeWidth;
    ctx.strokeStyle = Const.getTaskColor(this.item.taskId);
    ctx.lineCap = 'round';

    const offset = strokeWidth / 2;
    const w_in = w - strokeWidth;
    const h_in = h - strokeWidth;
    const r_in = r - offset;

    const L1 = h_in / 2 - r_in;
    const L2 = Math.PI * r_in / 2;
    const L3 = w_in - 2 * r_in;
    const L4 = Math.PI * r_in / 2;
    const L5 = h_in / 2 - r_in;

    const halfPerimeter = L1 + L2 + L3 + L4 + L5;
    const targetLen = halfPerimeter * (Math.min(100, progress) / 100);

    // 1. Draw top half (normal)
    ctx.save();
    ctx.beginPath();
    this.drawSymmetricPath(ctx, w, h, r, strokeWidth, targetLen, L1, L2, L3, L4);
    ctx.stroke();
    ctx.restore();

    // 2. Draw bottom half (mirrored)
    ctx.save();
    ctx.translate(0, h);
    ctx.scale(1, -1);
    ctx.beginPath();
    this.drawSymmetricPath(ctx, w, h, r, strokeWidth, targetLen, L1, L2, L3, L4);
    ctx.stroke();
    ctx.restore();
  }

  private drawSymmetricPath(
    ctx: CanvasRenderingContext2D,
    w: number,
    h: number,
    r: number,
    strokeWidth: number,
    targetLen: number,
    L1: number,
    L2: number,
    L3: number,
    L4: number
  ) {
    const offset = strokeWidth / 2;
    const r_in = r - offset;

    ctx.moveTo(offset, h / 2);

    if (targetLen <= L1) {
      ctx.lineTo(offset, h / 2 - targetLen);
      return;
    }
    ctx.lineTo(offset, offset + r_in);

    if (targetLen <= L1 + L2) {
      const dTheta = (targetLen - L1) / r_in;
      ctx.arc(offset + r_in, offset + r_in, r_in, Math.PI, Math.PI + dTheta, false);
      return;
    }
    ctx.arc(offset + r_in, offset + r_in, r_in, Math.PI, 1.5 * Math.PI, false);

    if (targetLen <= L1 + L2 + L3) {
      ctx.lineTo(offset + r_in + (targetLen - L1 - L2), offset);
      return;
    }
    ctx.lineTo(w - offset - r_in, offset);

    if (targetLen <= L1 + L2 + L3 + L4) {
      const dTheta = (targetLen - L1 - L2 - L3) / r_in;
      ctx.arc(w - offset - r_in, offset + r_in, r_in, 1.5 * Math.PI, 1.5 * Math.PI + dTheta, false);
      return;
    }
    ctx.arc(w - offset - r_in, offset + r_in, r_in, 1.5 * Math.PI, 2.0 * Math.PI, false);

    const remaining = targetLen - L1 - L2 - L3 - L4;
    ctx.lineTo(w - offset, offset + r_in + remaining);
  }

  private calculateTaskProgress(item: DayTaskInfo): number {
    if (item.isDone) {
      return Const.DEFAULT_100;
    }
    const step = taskBaseInfoList[item.taskId].step;
    if (step === 0) {
      return Const.DEFAULT_0;
    }
    const targetValue = Number(item.targetValue);
    const finValue = Number(item.finValue || '0');
    if (targetValue <= 0 || finValue <= 0) {
      return Const.DEFAULT_0;
    }
    return Math.min(Const.DEFAULT_100, Math.ceil(finValue / targetValue * Const.DEFAULT_100));
  }

  build() {
    Stack() {
      // 1. Main Row Layout
      Row() {
        Image(taskBaseInfoList[this.item.taskId].icon)
          .width($r('app.float.default_36'))
          .height($r('app.float.default_36'))
          .objectFit(ImageFit.Contain)
          .margin({
            right: $r('app.float.default_8')
          })

        Text(taskBaseInfoList[this.item.taskId].name)
          .fontFamily(Const.HARMONY_HEI_TI_MEDIUM)
          .fontWeight(FontWeight.Regular)
          .fontColor($r(`sys.color.font_primary`))
          .fontSize($r('app.float.default_16'))

        Blank()

        this.targetValueBuilder(this.item)
      }
      .width(Const.THOUSANDTH_1000)
      .height($r('app.float.default_62'))
      .borderRadius($r('app.float.default_16'))
      .padding({
        left: Const.THOUSANDTH_50,
        right: Const.THOUSANDTH_50
      })
      .backgroundColor($r('sys.color.background_primary'))

      // 2. Transparent Canvas overlay for border progress (on top)
      Canvas(this.context)
        .width(Const.THOUSANDTH_1000)
        .height($r('app.float.default_62'))
        .hitTestBehavior(HitTestMode.None)
        .onReady(() => {
          this.isReady = true;
          this.drawProgress();
        })
    }
    .width(Const.THOUSANDTH_1000)
    .height($r('app.float.default_62'))
    .borderRadius($r('app.float.default_16'))
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.cardWidthVp = newValue.width as number;
      this.cardHeightVp = newValue.height as number;
      this.drawProgress();
    })
    .onClick(() => {
      this.clickCallback();
    })
    .gesture(LongPressGesture().onAction(async () => {
      if (this.homeStore.checkCurrentDay()) {
        let taskInfo = await TaskInfoApi.queryByKey(this.item.taskId);
        this.pageStack.pushPath({ name: 'EditTaskComponent', param: taskInfo });
      }
    }))
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
