/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

import { ComponentContent } from '@kit.ArkUI';
import { CommonConstants as Const, PromptActionClass } from 'common';
import { TaskRemoveDialogParams } from '../../viewmodel/dialog/TaskRemoveDialogParams';

export function openTaskRemoveCustomDialog(uIContext: UIContext, params: TaskRemoveDialogParams): void {
  PromptActionClass.setContext(uIContext);
  const contentNode = new ComponentContent(uIContext, wrapBuilder(taskRemoveDialogBuilder), params);
  PromptActionClass.setContentNode(contentNode);
  PromptActionClass.setOptions({
    alignment: DialogAlignment.Bottom,
    offset: { dx: Const.DEFAULT_0, dy: Const.DEFAULT_NEGATIVE_20 }
  });
  PromptActionClass.openDialog();
}

@Builder
export function taskRemoveDialogBuilder(params: TaskRemoveDialogParams) {
  Column() {
    Row()
      .width($r('app.float.default_40'))
      .height($r('app.float.default_4'))
      .borderRadius($r('app.float.default_2'))
      .backgroundColor($r('sys.color.background_tertiary'))
      .margin({ top: $r('app.float.default_4'), bottom: $r('app.float.default_12') })

    Text($r('app.string.task_remove_actions_title'))
      .fontSize($r('app.float.default_22'))
      .fontWeight(FontWeight.Bold)
      .fontColor($r('sys.color.font_primary'))
      .width(Const.THOUSANDTH_1000)

    Text(params.taskName)
      .fontSize($r('app.float.default_18'))
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_primary'))
      .width(Const.THOUSANDTH_1000)
      .margin({ top: $r('app.float.default_6') })

    if (params.isDone) {
      Text($r('app.string.remove_completed_warning'))
        .fontSize($r('app.float.default_14'))
        .fontColor($r('app.color.button_red'))
        .width(Const.THOUSANDTH_1000)
        .padding($r('app.float.default_12'))
        .borderRadius($r('app.float.default_12'))
        .backgroundColor($r('sys.color.background_secondary'))
        .margin({ top: $r('app.float.default_12') })
    } else {
      Text($r('app.string.task_remove_actions_message'))
        .fontSize($r('app.float.default_14'))
        .fontColor($r('sys.color.font_secondary'))
        .width(Const.THOUSANDTH_1000)
        .margin({ top: $r('app.float.default_12') })
    }

    taskRemoveActionBuilder($r('sys.symbol.calendar'), $r('app.string.skip_today'),
      $r('app.string.skip_today_description'), false, params.onSkip)

    if (params.canStopRepeat) {
      taskRemoveActionBuilder($r('sys.symbol.trash'), $r('app.string.stop_repeat'),
        $r('app.string.stop_repeat_description'), true, params.onStop)
    }

    Button($r('app.string.cancel'))
      .buttonStyle(ButtonStyleMode.TEXTUAL)
      .fontSize($r('app.float.default_18'))
      .fontColor($r('app.color.text_font_color'))
      .width(Const.THOUSANDTH_1000)
      .height($r('app.float.default_48'))
      .margin({ top: $r('app.float.default_4') })
      .onClick(() => PromptActionClass.closeDialog())
  }
  .width(Const.THOUSANDTH_1000)
  .backgroundColor($r('sys.color.background_primary'))
  .borderRadius($r('app.float.default_32'))
  .padding({
    left: $r('app.float.default_20'),
    right: $r('app.float.default_20'),
    bottom: $r('app.float.default_12')
  })
  .margin({ left: $r('app.float.default_12'), right: $r('app.float.default_12'), bottom: $r('app.float.default_12') })
}

@Builder
function taskRemoveActionBuilder(symbol: Resource, title: Resource, description: Resource, dangerous: boolean,
  action: () => void) {
  Row({ space: $r('app.float.default_12') }) {
    SymbolGlyph(symbol)
      .fontSize($r('app.float.default_24'))
      .fontColor([dangerous ? $r('app.color.button_red') : $r('sys.color.brand')])
      .width($r('app.float.default_36'))

    Column({ space: $r('app.float.default_4') }) {
      Text(title)
        .fontSize($r('app.float.default_18'))
        .fontWeight(FontWeight.Medium)
        .fontColor(dangerous ? $r('app.color.button_red') : $r('sys.color.font_primary'))
        .width(Const.THOUSANDTH_1000)

      Text(description)
        .fontSize($r('app.float.default_14'))
        .fontColor($r('sys.color.font_secondary'))
        .width(Const.THOUSANDTH_1000)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }
  .width(Const.THOUSANDTH_1000)
  .height($r('app.float.default_66'))
  .padding({ left: $r('app.float.default_12'), right: $r('app.float.default_12') })
  .borderRadius($r('app.float.default_16'))
  .backgroundColor($r('sys.color.background_secondary'))
  .margin({ top: $r('app.float.default_12') })
  .onClick(() => {
    PromptActionClass.closeDialog();
    action();
  })
}
