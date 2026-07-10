/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

import { ComponentContent } from '@kit.ArkUI';
import { CommonConstants as Const, PromptActionClass } from 'common';
import { RepeatSettingDialogParams } from '../../viewmodel/dialog/RepeatSettingDialogParams';

export function openRepeatSettingCustomDialog(uIContext: UIContext, params: RepeatSettingDialogParams): void {
  PromptActionClass.setContext(uIContext);
  let contentNode = new ComponentContent(uIContext, wrapBuilder(repeatSettingDialogBuilder), params);
  PromptActionClass.setContentNode(contentNode);
  PromptActionClass.setOptions({
    alignment: DialogAlignment.Bottom,
    offset: { dx: Const.DEFAULT_0, dy: Const.DEFAULT_NEGATIVE_20 }
  });
  PromptActionClass.openDialog();
}

@Builder
export function repeatSettingDialogBuilder(params: RepeatSettingDialogParams) {
  Column() {
    Text($r('app.string.repeat_setting'))
      .fontSize($r('app.float.default_20'))
      .fontWeight(FontWeight.Bold)
      .margin({ top: $r('app.float.default_8'), bottom: $r('app.float.default_12') })

    repeatPresetBuilder(params, Const.REPEAT_DAYS_ONCE, $r('app.string.repeat_once'))
    repeatPresetBuilder(params, Const.REPEAT_DAYS_DAILY, $r('app.string.repeat_daily'))
    repeatPresetBuilder(params, Const.REPEAT_DAYS_WEEKDAY, $r('app.string.repeat_weekday'))
    repeatPresetBuilder(params, Const.REPEAT_DAYS_WEEKEND, $r('app.string.repeat_weekend'))
    repeatCustomBuilder(params)

    if (params.isCustom()) {
      Row({ space: $r('app.float.default_6') }) {
        ForEach([1, 2, 3, 4, 5, 6, 0], (day: number, index: number) => {
          Text(Const.WEEK_SHORTHAND_LIST[index])
            .fontSize($r('app.float.default_14'))
            .fontColor((params.customDays & (1 << day)) !== 0 ? Color.White : $r('sys.color.font_primary'))
            .textAlign(TextAlign.Center)
            .width($r('app.float.default_36'))
            .height($r('app.float.default_36'))
            .borderRadius($r('app.float.default_18'))
            .backgroundColor((params.customDays & (1 << day)) !== 0 ? $r('sys.color.brand') :
              $r('sys.color.background_secondary'))
            .onClick(() => {
              const dayMask = 1 << day;
              const nextDays = params.customDays ^ dayMask;
              if (nextDays !== 0) {
                params.customDays = nextDays;
                params.selectedDays = nextDays;
                PromptActionClass.contentNode.update(params);
              }
            })
        })
      }
      .width(Const.THOUSANDTH_1000)
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: $r('app.float.default_12'), bottom: $r('app.float.default_8') })
    }

    Row() {
      Text($r('app.string.cancel'))
        .fontColor($r('app.color.text_font_color'))
        .fontSize($r('app.float.default_20'))
        .onClick(() => PromptActionClass.closeDialog())

      Text($r('app.string.confirm'))
        .fontColor($r('app.color.text_font_color'))
        .fontSize($r('app.float.default_20'))
        .onClick(() => {
          params.taskInfo.repeatDays = params.selectedDays;
          PromptActionClass.closeDialog();
        })
    }
    .width(Const.THOUSANDTH_1000)
    .height($r('app.float.default_56'))
    .justifyContent(FlexAlign.SpaceAround)
    .margin({ top: $r('app.float.default_8') })
  }
  .backgroundColor($r('sys.color.background_primary'))
  .constraintSize({ minHeight: $r('app.float.default_316') })
  .borderRadius($r('app.float.default_32'))
  .margin({
    left: $r('app.float.default_18'),
    right: $r('app.float.default_18'),
    bottom: $r('app.float.default_12')
  })
  .padding($r('app.float.default_12'))
}

@Builder
function repeatPresetBuilder(params: RepeatSettingDialogParams, days: number, label: Resource) {
  Row() {
    Text(label).fontSize($r('app.float.default_18')).fontColor($r('sys.color.font_primary'))
    Blank()
    SymbolGlyph($r('sys.symbol.checkmark'))
      .fontColor([$r('sys.color.brand')])
      .fontSize($r('app.float.default_22'))
      .visibility(params.selectedDays === days ? Visibility.Visible : Visibility.Hidden)
  }
  .height($r('app.float.default_48'))
  .width(Const.THOUSANDTH_1000)
  .padding({ left: $r('app.float.default_12'), right: $r('app.float.default_12') })
  .margin({ top: $r('app.float.default_4'), bottom: $r('app.float.default_4') })
  .onClick(() => {
    params.selectedDays = days;
    PromptActionClass.contentNode.update(params);
  })
}

@Builder
function repeatCustomBuilder(params: RepeatSettingDialogParams) {
  Row() {
    Text($r('app.string.repeat_custom')).fontSize($r('app.float.default_18')).fontColor($r('sys.color.font_primary'))
    Blank()
    SymbolGlyph($r('sys.symbol.checkmark'))
      .fontColor([$r('sys.color.brand')])
      .fontSize($r('app.float.default_22'))
      .visibility(params.isCustom() ? Visibility.Visible : Visibility.Hidden)
  }
  .height($r('app.float.default_48'))
  .width(Const.THOUSANDTH_1000)
  .padding({ left: $r('app.float.default_12'), right: $r('app.float.default_12') })
  .margin({ top: $r('app.float.default_4'), bottom: $r('app.float.default_4') })
  .onClick(() => {
    params.selectedDays = params.customDays;
    PromptActionClass.contentNode.update(params);
  })
}
