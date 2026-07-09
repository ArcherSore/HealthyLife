
import { ComponentContent } from '@kit.ArkUI';
import { updateTaskList } from '../../viewmodel/HomeStore';
import TaskInfoApi from 'common/src/main/ets/database/tables/TaskInfoApi';
import { updateAchievementStore, updateTaskAchievementStore } from '../../viewmodel/AchievementStore';
import { TaskInfoDialogParams } from '../../viewmodel/dialog/TaskInfoDialogParams';
import { CommonConstants as Const, PromptActionClass, taskBaseInfoList } from 'common';

export function openTaskClockCustomDialog(uIContext: UIContext, params: TaskInfoDialogParams): void {
  PromptActionClass.setContext(uIContext);
  let taskInfoDialogNode = new ComponentContent(uIContext, wrapBuilder(taskClockDialogBuilder), params);
  PromptActionClass.setContentNode(taskInfoDialogNode);
  PromptActionClass.openDialog();
}

@Builder
export function taskClockDialogBuilder(params: TaskInfoDialogParams) {
  Column() {
    Text(taskBaseInfoList[params.dayTaskInfo.taskId].name)
      .fontFamily(Const.HARMONY_HEI_TI_BOLD)
      .fontWeight(FontWeight.Bold)
      .fontColor($r(`sys.color.font_on_primary`))
      .fontSize($r('app.float.default_22'))
      .width(Const.THOUSANDTH_1000)
      .margin({
        left: $r('app.float.default_12')
      })
      .position({
        y: $r('app.float.default_267')
      });

    Button() {
      Text(getClockButtonText(params))
        .fontFamily(Const.HARMONY_HEI_TI)
        .fontWeight(FontWeight.Normal)
        .fontColor($r(`sys.color.font_on_primary`))
        .fontSize($r('app.float.default_20'))
        .height($r('app.float.default_42'));
    }
    .width($r('app.float.default_220'))
    .borderRadius($r('app.float.default_24'))
    .backgroundColor($r('app.color.task_clock_bg_color'))
    .onClick(async () => {
      await taskClock(params);
    });
  }
  .height($r('app.float.default_451'))
  .width($r('app.float.default_316'))
  .backgroundImage(taskBaseInfoList[params.dayTaskInfo.taskId].dialog, ImageRepeat.NoRepeat)
  .backgroundImageSize({
    width: Const.THOUSANDTH_1000,
    height: Const.THOUSANDTH_1000
  })
  .justifyContent(FlexAlign.End)
  .padding({
    bottom: $r('app.float.default_16'),
    left: $r('app.float.default_10')
  })
}

function getClockButtonText(params: TaskInfoDialogParams): ResourceStr {
  const step = taskBaseInfoList[params.dayTaskInfo.taskId].step;
  if (params.dayTaskInfo.isDone) {
    if (step > 0) {
      return $r('app.string.clock_in_continue');
    }
    return $r('app.string.was_done');
  }
  return $r('app.string.clock_in');
}

async function taskClock(params: TaskInfoDialogParams) {
  const step = taskBaseInfoList[params.dayTaskInfo.taskId].step;
  const canClockIn = !params.dayTaskInfo.isDone || step > 0;
  if (canClockIn) {
    await TaskInfoApi.clockTask(params.dayTaskInfo.date, params.dayTaskInfo.taskId);
    await updateTaskList(params.homeStore);
  }
  PromptActionClass.closeDialog();

  if (!params.dayTaskInfo.isDone) {
    await updateAchievementStore(params);
  }
  if (canClockIn) {
    await updateTaskAchievementStore(params);
  }
}
