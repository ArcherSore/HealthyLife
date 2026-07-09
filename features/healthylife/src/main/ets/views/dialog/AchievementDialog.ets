
import { ComponentContent } from '@kit.ArkUI';
import { AchievementList, TaskOverAchievementList } from '../../model/AchievementModel';
import { CommonConstants as Const, PromptActionClass, taskBaseInfoList } from 'common';
import { AchievementDialogParams } from '../../viewmodel/dialog/AchievementDialogParams';

export function openAchievementCustomDialog(uIContext: UIContext, index: number, medalType: string,
  taskId: number): void {
  PromptActionClass.setContext(uIContext);
  let params = new AchievementDialogParams(uIContext, index, medalType, taskId,
    Const.ANIMATE_OPACITY_0, Const.ANIMATE_ANGLE_0, Const.ANIMATE_SCALE_0);
  let taskInfoDialogNode = new ComponentContent(uIContext, wrapBuilder(taskInfoDialogBuilder), params);
  PromptActionClass.setContentNode(taskInfoDialogNode);
  PromptActionClass.openDialog();
}

@Builder
export function taskInfoDialogBuilder(param: AchievementDialogParams) {
  Column() {
    Image(getMedalIconOn(param))
      .width(Const.THOUSANDTH_560)
      .height(Const.THOUSANDTH_400)
      .objectFit(ImageFit.Contain)

    if (param.medalType === 'global') {
      Text($r('app.string.achievement_level', AchievementList[param.index].name))
        .fontFamily(Const.HARMONY_HEI_TI)
        .fontWeight(FontWeight.Regular)
        .fontColor($r('sys.color.font_on_primary'))
        .fontSize($r('app.float.default_24'))
        .margin({ top: $r('app.float.default_12') })
    } else {
      Text(taskBaseInfoList[param.taskId].name)
        .fontFamily(Const.HARMONY_HEI_TI_BOLD)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_on_primary'))
        .fontSize($r('app.float.default_20'))
        .margin({ top: $r('app.float.default_8') })

      Text($r('app.string.over_achievement_level', TaskOverAchievementList[param.index].name))
        .fontFamily(Const.HARMONY_HEI_TI)
        .fontWeight(FontWeight.Regular)
        .fontColor($r('sys.color.font_on_primary'))
        .fontSize($r('app.float.default_18'))
        .margin({ top: $r('app.float.default_4') })
    }
  }
  .height(Const.THOUSANDTH_400)
  .width(Const.THOUSANDTH_500)
  .justifyContent(FlexAlign.Center)
  .scale({
    x: param.scaleValue,
    y: param.scaleValue
  })
  .rotate({
    x: Const.ANIMATE_ROTATE_0,
    y: Const.ANIMATE_ROTATE_1,
    z: Const.ANIMATE_ROTATE_0,
    angle: param.angle
  })
  .opacity(param.opacityValue)
  .onAppear(() => {
    param.uiContext?.animateTo({
      duration: Const.DURATION_800,
      curve: Curve.EaseOut,
      delay: Const.DURATION_100,
      iterations: Const.ANIMATE_ITERATIONS_1
    }, () => {
      PromptActionClass.contentNode.update(
        new AchievementDialogParams(param.uiContext, param.index, param.medalType, param.taskId,
          Const.ANIMATE_OPACITY_1, Const.ANIMATE_ANGLE_360, Const.ANIMATE_SCALE_1));
    });
  })
}

function getMedalIconOn(param: AchievementDialogParams): Resource {
  if (param.medalType === 'taskOverAchievement') {
    return TaskOverAchievementList[param.index].iconOn;
  }
  return AchievementList[param.index].iconOn;
}
