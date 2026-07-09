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

import { ComponentContent } from '@kit.ArkUI';
import { CommonConstants as Const, convertTime2Date, PromptActionClass } from 'common';
import {
  ReminderSettingDialogParams,
  ReminderSettingType
} from '../../viewmodel/dialog/ReminderSettingDialogParams';

export function openReminderSettingCustomDialog(uIContext: UIContext, params: ReminderSettingDialogParams): void {
  PromptActionClass.setContext(uIContext);
  let reminderSettingDialogNode = new ComponentContent(uIContext, wrapBuilder(reminderSettingDialogBuilder), params);
  PromptActionClass.setContentNode(reminderSettingDialogNode);
  PromptActionClass.setOptions({
    alignment: DialogAlignment.Bottom,
    offset: {
      dx: Const.DEFAULT_0,
      dy: Const.DEFAULT_NEGATIVE_20
    }
  })
  PromptActionClass.openDialog();
}

@Builder
export function reminderSettingDialogBuilder(params: ReminderSettingDialogParams) {
  Column() {
    Row() {
      Text(params.settingType === ReminderSettingType.TIME ? $r('app.string.reminder_time') :
      $r('app.string.reminder_frequency'))
        .fontSize($r('app.float.default_20'))
        .fontWeight(FontWeight.Bold)
        .margin({
          top: $r('app.float.default_12'),
          right: $r('app.float.default_12'),
          bottom: $r('app.float.default_16')
        })
    }
    .width(Const.THOUSANDTH_1000)
    .height($r('app.float.default_56'))
    .justifyContent(FlexAlign.Center)

    if (params.settingType === ReminderSettingType.TIME) {
      TimePicker({
        selected: convertTime2Date(params.selectedValue),
        format: TimePickerFormat.HOUR_MINUTE,
        start: params.startDate,
        end: params.endDate
      })
        .margin({
          left: $r('app.float.default_24'),
          right: $r('app.float.default_24')
        })
        .useMilitaryTime(true)
        .onChange((value: TimePickerResult) => {
          if (value.hour != undefined && value.minute != undefined) {
            params.selectedValue = `${("0" + value.hour).slice(-2)}:${("0" + value.minute).slice(-2)}`;
          }
        })
    } else {
      Column() {
        reminderFrequencyItemBuilder(params, Const.REMINDER_FREQUENCY_DAILY, $r('app.string.reminder_frequency_daily'))
        reminderFrequencyItemBuilder(params, Const.REMINDER_FREQUENCY_WEEKDAY,
          $r('app.string.reminder_frequency_weekday'))
        reminderFrequencyItemBuilder(params, Const.REMINDER_FREQUENCY_WEEKEND,
          $r('app.string.reminder_frequency_weekend'))
      }
      .width(Const.THOUSANDTH_900)
    }

    Row() {
      Text($r('app.string.cancel'))
        .fontColor($r('app.color.text_font_color'))
        .fontSize($r('app.float.default_20'))
        .onClick(() => {
          PromptActionClass.closeDialog();
        })

      Text($r('app.string.confirm'))
        .fontColor($r('app.color.text_font_color'))
        .fontSize($r('app.float.default_20'))
        .onClick(() => {
          if (params.settingType === ReminderSettingType.TIME) {
            params.taskInfo.alertStartTime = params.selectedValue;
          } else {
            params.taskInfo.alertFrequency = params.selectedValue;
          }
          PromptActionClass.closeDialog();
        })
    }
    .width(Const.THOUSANDTH_1000)
    .height($r('app.float.default_56'))
    .justifyContent(FlexAlign.SpaceAround)
    .margin({
      top: $r('app.float.default_8')
    })
  }
  .backgroundColor($r('sys.color.background_primary'))
  .height(Const.THOUSANDTH_420)
  .justifyContent(FlexAlign.SpaceAround)
  .borderRadius($r('app.float.default_32'))
  .margin({
    left: $r('app.float.default_18'),
    right: $r('app.float.default_18'),
    bottom: Const.THOUSANDTH_500
  })
  .padding($r('app.float.default_12'))
}

@Builder
function reminderFrequencyItemBuilder(params: ReminderSettingDialogParams, value: string, label: Resource) {
  Row() {
    Text(label)
      .fontSize($r('app.float.default_18'))
      .fontColor($r('sys.color.font_primary'))

    Blank()

    SymbolGlyph($r('sys.symbol.checkmark'))
      .fontColor([$r('sys.color.brand')])
      .fontSize($r('app.float.default_22'))
      .visibility(params.selectedValue === value ? Visibility.Visible : Visibility.Hidden)
  }
  .height($r('app.float.default_48'))
  .width(Const.THOUSANDTH_1000)
  .padding({
    left: $r('app.float.default_12'),
    right: $r('app.float.default_12')
  })
  .onClick(() => {
    params.selectedValue = value;
    PromptActionClass.contentNode.update(params);
  })
}
