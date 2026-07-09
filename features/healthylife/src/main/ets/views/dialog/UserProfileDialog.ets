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
import { CommonConstants as Const, PromptActionClass } from 'common';
import {
  GENDER_FEMALE,
  GENDER_MALE,
  GENDER_SECRET,
  selectAvatarFromGallery,
  UserProfileStore
} from '../../viewmodel/UserProfileStore';

const MIN_BIRTHDAY = new Date(1900, 0, 1);

export enum UserProfileInputType {
  NICKNAME = 'nickname',
  HEIGHT = 'height',
  WEIGHT = 'weight'
}

class UserProfileInputDialogParams {
  uiContext: UIContext;
  userProfileStore: UserProfileStore;
  inputType: UserProfileInputType;
  title: Resource;
  placeholder: Resource;
  inputValue: string;
  onUpdated: () => void;

  constructor(uiContext: UIContext, userProfileStore: UserProfileStore, inputType: UserProfileInputType,
    title: Resource, placeholder: Resource, inputValue: string, onUpdated: () => void) {
    this.uiContext = uiContext;
    this.userProfileStore = userProfileStore;
    this.inputType = inputType;
    this.title = title;
    this.placeholder = placeholder;
    this.inputValue = inputValue;
    this.onUpdated = onUpdated;
  }
}

class UserProfileGenderDialogParams {
  userProfileStore: UserProfileStore;
  selectedValue: string;
  onUpdated: () => void;

  constructor(userProfileStore: UserProfileStore, onUpdated: () => void) {
    this.userProfileStore = userProfileStore;
    this.selectedValue = userProfileStore.gender;
    this.onUpdated = onUpdated;
  }
}

class UserProfileBirthdayDialogParams {
  userProfileStore: UserProfileStore;
  selectedValue: string;
  onUpdated: () => void;

  constructor(userProfileStore: UserProfileStore, onUpdated: () => void) {
    this.userProfileStore = userProfileStore;
    this.selectedValue = userProfileStore.birthday;
    this.onUpdated = onUpdated;
  }
}

class UserProfileAvatarDialogParams {
  uiContext: UIContext;
  userProfileStore: UserProfileStore;
  pageStack: NavPathStack;
  onUpdated: () => void;

  constructor(uiContext: UIContext, userProfileStore: UserProfileStore, pageStack: NavPathStack,
    onUpdated: () => void) {
    this.uiContext = uiContext;
    this.userProfileStore = userProfileStore;
    this.pageStack = pageStack;
    this.onUpdated = onUpdated;
  }
}

export function openUserProfileInputDialog(uiContext: UIContext, userProfileStore: UserProfileStore,
  inputType: UserProfileInputType, onUpdated: () => void = () => {}): void {
  let currentValue = '';
  let title: Resource = $r('app.string.profile_nickname');
  let placeholder: Resource = $r('app.string.profile_nickname_placeholder');
  if (inputType === UserProfileInputType.NICKNAME) {
    currentValue = userProfileStore.nickname;
  } else if (inputType === UserProfileInputType.HEIGHT) {
    title = $r('app.string.profile_height');
    placeholder = $r('app.string.profile_height_placeholder');
    currentValue = userProfileStore.height;
  } else {
    title = $r('app.string.profile_weight');
    placeholder = $r('app.string.profile_weight_placeholder');
    currentValue = userProfileStore.weight;
  }
  let params = new UserProfileInputDialogParams(uiContext, userProfileStore, inputType, title, placeholder,
    currentValue, onUpdated);
  openBottomDialog(uiContext, wrapBuilder(userProfileInputDialogBuilder), params, Const.THOUSANDTH_420);
}

export function openUserProfileGenderDialog(uiContext: UIContext, userProfileStore: UserProfileStore,
  onUpdated: () => void = () => {}): void {
  let params = new UserProfileGenderDialogParams(userProfileStore, onUpdated);
  openBottomDialog(uiContext, wrapBuilder(userProfileGenderDialogBuilder), params, Const.THOUSANDTH_420);
}

export function openUserProfileBirthdayDialog(uiContext: UIContext, userProfileStore: UserProfileStore,
  onUpdated: () => void = () => {}): void {
  let params = new UserProfileBirthdayDialogParams(userProfileStore, onUpdated);
  openBottomDialog(uiContext, wrapBuilder(userProfileBirthdayDialogBuilder), params, Const.THOUSANDTH_440);
}

export function openUserProfileAvatarDialog(uiContext: UIContext, userProfileStore: UserProfileStore,
  pageStack: NavPathStack, onUpdated: () => void = () => {}): void {
  let params = new UserProfileAvatarDialogParams(uiContext, userProfileStore, pageStack, onUpdated);
  openBottomDialog(uiContext, wrapBuilder(userProfileAvatarDialogBuilder), params, Const.THOUSANDTH_420);
}

@Builder
function userProfileInputDialogBuilder(params: UserProfileInputDialogParams) {
  Column() {
    dialogTitleBuilder(params.title)

    TextInput({
      text: params.inputValue,
      placeholder: params.placeholder
    })
      .width(Const.THOUSANDTH_900)
      .height($r('app.float.default_48'))
      .fontSize($r('app.float.default_18'))
      .maxLength(params.inputType === UserProfileInputType.NICKNAME ? 20 : 6)
      .backgroundColor($r('sys.color.background_secondary'))
      .borderRadius($r('app.float.default_12'))
      .onChange((value: string) => {
        params.inputValue = value;
      })

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
        .onClick(async () => {
          await confirmInputValue(params);
        })
    }
    .width(Const.THOUSANDTH_1000)
    .height($r('app.float.default_56'))
    .justifyContent(FlexAlign.SpaceAround)
    .margin({
      top: $r('app.float.default_8')
    })
  }
  .dialogContainerStyle(Const.THOUSANDTH_420)
}

@Builder
function userProfileGenderDialogBuilder(params: UserProfileGenderDialogParams) {
  Column() {
    dialogTitleBuilder($r('app.string.profile_gender'))
    profileSelectItemBuilder(params, GENDER_MALE, $r('app.string.profile_gender_male'))
    profileSelectItemBuilder(params, GENDER_FEMALE, $r('app.string.profile_gender_female'))
    profileSelectItemBuilder(params, GENDER_SECRET, $r('app.string.profile_gender_secret'))

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
        .onClick(async () => {
          await params.userProfileStore.saveGender(params.selectedValue);
          params.onUpdated();
          PromptActionClass.closeDialog();
        })
    }
    .width(Const.THOUSANDTH_1000)
    .height($r('app.float.default_56'))
    .justifyContent(FlexAlign.SpaceAround)
  }
  .dialogContainerStyle(Const.THOUSANDTH_420)
}

@Builder
function userProfileBirthdayDialogBuilder(params: UserProfileBirthdayDialogParams) {
  Column() {
    dialogTitleBuilder($r('app.string.profile_birthday'))

    DatePicker({
      start: MIN_BIRTHDAY,
      end: new Date(),
      selected: convertBirthday2Date(params.selectedValue)
    })
      .margin({
        left: $r('app.float.default_24'),
        right: $r('app.float.default_24')
      })
      .onChange((value: DatePickerResult) => {
        params.selectedValue = formatDatePickerResult(value);
      })

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
        .onClick(async () => {
          await params.userProfileStore.saveBirthday(params.selectedValue);
          params.onUpdated();
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
  .dialogContainerStyle(Const.THOUSANDTH_440)
}

@Builder
function userProfileAvatarDialogBuilder(params: UserProfileAvatarDialogParams) {
  Column() {
    dialogTitleBuilder($r('app.string.profile_avatar'))
    avatarActionItemBuilder($r('app.string.profile_view_avatar'), async () => {
      PromptActionClass.closeDialog();
      params.pageStack.pushPathByName('AvatarPreviewComponent', '');
    })
    avatarActionItemBuilder($r('app.string.profile_select_from_gallery'), async () => {
      PromptActionClass.closeDialog();
      await chooseAvatar(params);
    })
    avatarActionItemBuilder($r('app.string.profile_restore_default_avatar'), async () => {
      await params.userProfileStore.saveAvatarUri('');
      params.onUpdated();
      PromptActionClass.closeDialog();
    })
  }
  .dialogContainerStyle(Const.THOUSANDTH_420)
}

@Builder
function dialogTitleBuilder(title: Resource) {
  Row() {
    Text(title)
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
}

@Builder
function profileSelectItemBuilder(params: UserProfileGenderDialogParams, value: string, label: Resource) {
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
  .width(Const.THOUSANDTH_900)
  .padding({
    left: $r('app.float.default_12'),
    right: $r('app.float.default_12')
  })
  .onClick(() => {
    params.selectedValue = value;
    PromptActionClass.contentNode.update(params);
  })
}

@Builder
function avatarActionItemBuilder(label: Resource, action: () => Promise<void>) {
  Row() {
    Text(label)
      .fontSize($r('app.float.default_18'))
      .fontColor($r('sys.color.font_primary'))
  }
  .height($r('app.float.default_56'))
  .width(Const.THOUSANDTH_900)
  .justifyContent(FlexAlign.Center)
  .onClick(async () => {
    await action();
  })
}

@Extend(Column)
function dialogContainerStyle(heightValue: string) {
  .backgroundColor($r('sys.color.background_primary'))
  .height(heightValue)
  .justifyContent(FlexAlign.SpaceAround)
  .borderRadius($r('app.float.default_32'))
  .margin({
    left: $r('app.float.default_18'),
    right: $r('app.float.default_18'),
    bottom: Const.THOUSANDTH_500
  })
  .padding($r('app.float.default_12'))
}

function openBottomDialog<T extends Object>(uiContext: UIContext, builder: WrappedBuilder<[T]>, params: T,
  _heightValue: string): void {
  PromptActionClass.setContext(uiContext);
  let dialogNode = new ComponentContent(uiContext, builder, params);
  PromptActionClass.setContentNode(dialogNode);
  PromptActionClass.setOptions({
    alignment: DialogAlignment.Bottom,
    offset: {
      dx: Const.DEFAULT_0,
      dy: Const.DEFAULT_NEGATIVE_20
    }
  })
  PromptActionClass.openDialog();
}

async function confirmInputValue(params: UserProfileInputDialogParams): Promise<void> {
  const inputValue = params.inputValue.trim();
  if (params.inputType === UserProfileInputType.NICKNAME) {
    if (inputValue.length === 0) {
      showToast(params.uiContext, $r('app.string.profile_nickname_empty'));
      return;
    }
    await params.userProfileStore.saveNickname(inputValue);
  } else if (params.inputType === UserProfileInputType.HEIGHT) {
    if (!validateNumberInput(params.uiContext, inputValue, 50, 250)) {
      return;
    }
    await params.userProfileStore.saveHeight(inputValue);
  } else {
    if (!validateNumberInput(params.uiContext, inputValue, 20, 300)) {
      return;
    }
    await params.userProfileStore.saveWeight(inputValue);
  }
  params.onUpdated();
  PromptActionClass.closeDialog();
}

function validateNumberInput(uiContext: UIContext, inputValue: string, minValue: number, maxValue: number): boolean {
  if (inputValue.length === 0) {
    return true;
  }
  const numberPattern = /^\d{1,3}(\.\d)?$/;
  if (!numberPattern.test(inputValue)) {
    showToast(uiContext, $r('app.string.profile_number_invalid'));
    return false;
  }
  const numberValue = Number(inputValue);
  if (numberValue < minValue || numberValue > maxValue) {
    showToast(uiContext, $r('app.string.profile_number_invalid'));
    return false;
  }
  return true;
}

async function chooseAvatar(params: UserProfileAvatarDialogParams): Promise<void> {
  try {
    const avatarUri = await selectAvatarFromGallery();
    if (avatarUri.length > 0) {
      await params.userProfileStore.saveAvatarUri(avatarUri);
      params.onUpdated();
    }
  } catch (error) {
    showToast(params.uiContext, $r('app.string.profile_avatar_select_failed'));
  }
}

function showToast(uiContext: UIContext, message: Resource): void {
  try {
    uiContext.getPromptAction().showToast({
      message: message
    });
  } catch (error) {
    console.error(`showToast failed: ${error}`);
  }
}

function convertBirthday2Date(birthday: string): Date {
  const dateItems = birthday.split('-');
  if (dateItems.length !== 3) {
    return new Date(1999, 11, 31);
  }
  return new Date(Number(dateItems[0]), Number(dateItems[1]) - 1, Number(dateItems[2]));
}

function formatDatePickerResult(value: DatePickerResult): string {
  const year = value.year ?? 1999;
  const month = (value.month ?? 11) + 1;
  const day = value.day ?? 31;
  return `${year}-${padDateValue(month)}-${padDateValue(day)}`;
}

function padDateValue(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}
