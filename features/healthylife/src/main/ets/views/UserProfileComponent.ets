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

import { CommonConstants as Const } from 'common';
import {
  GENDER_FEMALE,
  GENDER_MALE,
  selectAvatarFromGallery,
  UserProfileStore
} from '../viewmodel/UserProfileStore';
import {
  openUserProfileAvatarDialog,
  openUserProfileBirthdayDialog,
  openUserProfileGenderDialog,
  openUserProfileInputDialog,
  UserProfileInputType
} from './dialog/UserProfileDialog';

enum UserProfileField {
  NICKNAME = 'nickname',
  BIRTHDAY = 'birthday',
  HEIGHT = 'height',
  WEIGHT = 'weight'
}

@Builder
export function userProfileBuilder() {
  UserProfileComponent();
}

@Builder
export function avatarPreviewBuilder() {
  AvatarPreviewComponent();
}

@Extend(Row)
function cardRowStyle() {
  .width(Const.THOUSANDTH_940)
  .height($r('app.float.default_56'))
  .padding({
    left: $r('app.float.default_12'),
    right: $r('app.float.default_12')
  })
  .backgroundColor($r('sys.color.background_primary'))
}

@Component
export struct UserProfileComponent {
  @Consume('pathStack') pageStack: NavPathStack;
  @Consume userProfileStore: UserProfileStore;

  build() {
    NavDestination() {
      Column() {
        this.titleBuilder($r('app.string.profile_title'))

        Scroll() {
          Column() {
            Column() {
              Stack({ alignContent: Alignment.Center }) {
                this.avatarBuilder($r('app.float.default_88'))

                Row() {
                  SymbolGlyph($r('sys.symbol.camera'))
                    .fontColor([$r('sys.color.icon_on_primary')])
                    .fontSize($r('app.float.default_18'))
                }
                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Center)
                .width($r('app.float.default_28'))
                .height($r('app.float.default_28'))
                .backgroundColor($r('sys.color.brand'))
                .borderRadius(Const.BORDER_RADIUS_PERCENT_50)
                .position({
                  x: $r('app.float.default_66'),
                  y: $r('app.float.default_62')
                })
              }
              .width($r('app.float.default_100'))
              .height($r('app.float.default_100'))
              .margin({
                top: $r('app.float.default_12'),
                bottom: $r('app.float.default_4')
              })
              .onClick(() => {
                openUserProfileAvatarDialog(this.getUIContext(), this.userProfileStore, this.pageStack);
              })

              Text($r('app.string.profile_change_avatar'))
                .fontColor($r('app.color.text_font_color'))
                .fontSize($r('app.float.default_14'))
                .textAlign(TextAlign.Center)
                .width(Const.THOUSANDTH_1000)
                .margin({
                  bottom: $r('app.float.default_14')
                })
            }
            .width(Const.THOUSANDTH_940)
            .backgroundColor($r('sys.color.background_primary'))
            .borderRadius($r('app.float.default_16'))
            .alignItems(HorizontalAlign.Center)
            .margin({
              bottom: $r('app.float.default_12')
            })

            this.profileRowBuilder($r('app.string.profile_nickname'), UserProfileField.NICKNAME, '', () => {
              openUserProfileInputDialog(this.getUIContext(), this.userProfileStore, UserProfileInputType.NICKNAME);
            }, true, false)
            Divider()
              .color($r('app.float.default_1'))
              .width(Const.THOUSANDTH_880)
            this.genderRowBuilder()
            Divider()
              .color($r('app.float.default_1'))
              .width(Const.THOUSANDTH_880)
            this.profileRowBuilder($r('app.string.profile_birthday'), UserProfileField.BIRTHDAY, '', () => {
              openUserProfileBirthdayDialog(this.getUIContext(), this.userProfileStore);
            }, false, true)

            Column()
              .width(Const.THOUSANDTH_940)
              .height($r('app.float.default_12'))

            this.profileRowBuilder($r('app.string.profile_height'), UserProfileField.HEIGHT, 'cm', () => {
              openUserProfileInputDialog(this.getUIContext(), this.userProfileStore, UserProfileInputType.HEIGHT);
            }, true, false)
            Divider()
              .color($r('app.float.default_1'))
              .width(Const.THOUSANDTH_880)
            this.profileRowBuilder($r('app.string.profile_weight'), UserProfileField.WEIGHT, 'kg', () => {
              openUserProfileInputDialog(this.getUIContext(), this.userProfileStore, UserProfileInputType.WEIGHT);
            }, false, true)

            Blank()
              .height($r('app.float.default_120'))
          }
          .width(Const.THOUSANDTH_1000)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Start)
        }
        .width(Const.THOUSANDTH_1000)
        .layoutWeight(Const.FLEX_GROW_1)
      }
      .width(Const.THOUSANDTH_1000)
      .height(Const.THOUSANDTH_1000)
      .backgroundColor($r('sys.color.background_secondary'))
      .padding({
        left: $r('app.float.default_10'),
        right: $r('app.float.default_10')
      })
    }
    .size({
      width: Const.THOUSANDTH_1000,
      height: Const.THOUSANDTH_1000
    })
    .title($r('app.string.profile_title'))
    .hideTitleBar(true)
    .padding({
      top: $r('app.float.default_40')
    })
    .backgroundColor($r('sys.color.background_secondary'))
  }

  @Builder
  titleBuilder(title: Resource) {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontColor([$r('sys.color.icon_primary')])
        .fontWeight(FontWeight.Normal)
        .fontSize($r('app.float.default_28'))
        .width($r('app.float.default_40'))
        .height($r('app.float.default_40'))
        .onClick(() => {
          this.pageStack.pop();
        })

      Text(title)
        .fontFamily($r(Const.HARMONY_HEI_TI_MEDIUM))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .fontSize($r('app.float.default_20'))
        .height($r('app.float.default_56'))

      Blank()
        .width($r('app.float.default_40'))
    }
    .width(Const.THOUSANDTH_1000)
    .height($r('app.float.default_56'))
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  avatarBuilder(size: Resource) {
    if (this.userProfileStore.avatarUri.length > 0) {
      Image(this.userProfileStore.avatarUri)
        .width(size)
        .height(size)
        .borderRadius(Const.BORDER_RADIUS_PERCENT_50)
        .objectFit(ImageFit.Cover)
    } else {
      Image($r('app.media.person_crop_circle'))
        .width(size)
        .height(size)
        .borderRadius(Const.BORDER_RADIUS_PERCENT_50)
        .objectFit(ImageFit.Cover)
    }
  }

  @Builder
  profileRowBuilder(label: Resource, field: UserProfileField, unit: string, onClickAction: () => void, isTop: boolean,
    isBottom: boolean) {
    Row({ space: $r('app.float.default_12') }) {
      Text(label)
        .fontColor($r('app.color.mine_font_color'))
        .fontSize($r('app.float.default_18'))
        .fontWeight(FontWeight.Medium)

      Blank()

      this.profileValueBuilder(field, unit)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontColor([$r('sys.color.icon_fourth')])
        .fontWeight(FontWeight.Normal)
        .fontSize($r('app.float.default_24'))
    }
    .cardRowStyle()
    .borderRadius({
      topLeft: isTop ? $r('app.float.default_16') : 0,
      topRight: isTop ? $r('app.float.default_16') : 0,
      bottomLeft: isBottom ? $r('app.float.default_16') : 0,
      bottomRight: isBottom ? $r('app.float.default_16') : 0
    })
    .onClick(() => {
      onClickAction();
    })
  }

  @Builder
  profileValueBuilder(field: UserProfileField, unit: string) {
    if (field === UserProfileField.NICKNAME) {
      if (this.userProfileStore.nickname.length > 0) {
        Text(this.userProfileStore.nickname)
          .fontColor($r('sys.color.font_secondary'))
          .fontSize($r('app.float.default_16'))
      } else {
        this.unfilledValueBuilder()
      }
    } else if (field === UserProfileField.BIRTHDAY) {
      if (this.userProfileStore.birthday.length > 0) {
        Text(this.userProfileStore.birthday)
          .fontColor($r('sys.color.font_secondary'))
          .fontSize($r('app.float.default_16'))
      } else {
        this.unfilledValueBuilder()
      }
    } else if (field === UserProfileField.HEIGHT) {
      if (this.userProfileStore.height.length > 0) {
        Text(`${this.userProfileStore.height} ${unit}`)
          .fontColor($r('sys.color.font_secondary'))
          .fontSize($r('app.float.default_16'))
      } else {
        this.unfilledValueBuilder()
      }
    } else {
      if (this.userProfileStore.weight.length > 0) {
        Text(`${this.userProfileStore.weight} ${unit}`)
          .fontColor($r('sys.color.font_secondary'))
          .fontSize($r('app.float.default_16'))
      } else {
        this.unfilledValueBuilder()
      }
    }
  }

  @Builder
  unfilledValueBuilder() {
    Text($r('app.string.profile_unfilled'))
      .fontColor($r('sys.color.font_tertiary'))
      .fontSize($r('app.float.default_16'))
  }

  @Builder
  genderRowBuilder() {
    Row({ space: $r('app.float.default_12') }) {
      Text($r('app.string.profile_gender'))
        .fontColor($r('app.color.mine_font_color'))
        .fontSize($r('app.float.default_18'))
        .fontWeight(FontWeight.Medium)

      Blank()

      Text(this.getGenderText())
        .fontColor($r('sys.color.font_secondary'))
        .fontSize($r('app.float.default_16'))

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontColor([$r('sys.color.icon_fourth')])
        .fontWeight(FontWeight.Normal)
        .fontSize($r('app.float.default_24'))
    }
    .cardRowStyle()
    .onClick(() => {
      openUserProfileGenderDialog(this.getUIContext(), this.userProfileStore);
    })
  }

  private getGenderText(): Resource {
    if (this.userProfileStore.gender === GENDER_MALE) {
      return $r('app.string.profile_gender_male');
    }
    if (this.userProfileStore.gender === GENDER_FEMALE) {
      return $r('app.string.profile_gender_female');
    }
    return $r('app.string.profile_gender_secret');
  }
}

@Component
export struct AvatarPreviewComponent {
  @Consume('pathStack') pageStack: NavPathStack;
  @Consume userProfileStore: UserProfileStore;
  @State avatarRefreshVersion: number = 0;

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Column() {
          Blank()
          this.previewAvatarBuilder()
          Blank()
          Button() {
            Text($r('app.string.profile_select_from_gallery'))
              .fontSize($r('app.float.default_18'))
          }
          .buttonStyle(ButtonStyleMode.NORMAL)
          .width(Const.THOUSANDTH_560)
          .height($r('app.float.default_44'))
          .backgroundColor($r('sys.color.brand'))
          .margin({
            bottom: $r('app.float.default_40')
          })
          .onClick(async () => {
            await this.chooseAvatar();
          })
        }
        .width(Const.THOUSANDTH_1000)
        .height(Const.THOUSANDTH_1000)

        SymbolGlyph($r('sys.symbol.xmark'))
          .fontColor([$r('sys.color.icon_on_primary')])
          .fontSize($r('app.float.default_28'))
          .width($r('app.float.default_48'))
          .height($r('app.float.default_48'))
          .margin({
            top: $r('app.float.default_28'),
            left: $r('app.float.default_12')
          })
          .onClick(() => {
            this.pageStack.pop();
          })
      }
      .width(Const.THOUSANDTH_1000)
      .height(Const.THOUSANDTH_1000)
      .backgroundColor(Color.Black)
    }
    .size({
      width: Const.THOUSANDTH_1000,
      height: Const.THOUSANDTH_1000
    })
    .hideTitleBar(true)
    .backgroundColor(Color.Black)
  }

  @Builder
  previewAvatarBuilder() {
    if (this.avatarRefreshVersion >= 0 && this.userProfileStore.avatarUri.length > 0) {
      Image(this.userProfileStore.avatarUri)
        .width(Const.THOUSANDTH_1000)
        .height(Const.THOUSANDTH_780)
        .objectFit(ImageFit.Contain)
    } else {
      Image($r('app.media.person_crop_circle'))
        .width(Const.THOUSANDTH_560)
        .height(Const.THOUSANDTH_560)
        .objectFit(ImageFit.Contain)
    }
  }

  private async chooseAvatar(): Promise<void> {
    try {
      const avatarUri = await selectAvatarFromGallery();
      if (avatarUri.length > 0) {
        await this.userProfileStore.saveAvatarUri(avatarUri);
        this.avatarRefreshVersion++;
      }
    } catch (error) {
      try {
        this.getUIContext().getPromptAction().showToast({
          message: $r('app.string.profile_avatar_select_failed')
        });
      } catch (showError) {
        console.error(`showToast failed: ${showError}`);
      }
    }
  }
}
