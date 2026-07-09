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
import { UserProfileStore } from '../../viewmodel/UserProfileStore';

@Reusable
@Component
export struct UserInfoComponent {
  @Consume('pathStack') pageStack: NavPathStack;
  @Consume userProfileStore: UserProfileStore;

  build() {
    Row({ space: $r('app.float.default_12') }) {
      if (this.userProfileStore.avatarUri.length > 0) {
        Image(this.userProfileStore.avatarUri)
          .width($r('app.float.default_48'))
          .height($r('app.float.default_48'))
          .borderRadius(Const.BORDER_RADIUS_PERCENT_50)
          .objectFit(ImageFit.Cover)
          .onClick(() => {
            this.openAvatarEntry();
          })
      } else {
        Image($r('app.media.person_crop_circle'))
          .width($r('app.float.default_48'))
          .height($r('app.float.default_48'))
          .borderRadius(Const.BORDER_RADIUS_PERCENT_50)
          .objectFit(ImageFit.Cover)
          .onClick(() => {
            this.openAvatarEntry();
          })
      }

      Column() {
        Text(this.userProfileStore.nickname)
          .fontColor($r('app.color.mine_font_color'))
          .fontSize($r('app.float.default_18'))
          .fontWeight(FontWeight.Medium)

        Text($r('app.string.profile_view_profile'))
          .fontColor($r('sys.color.font_tertiary'))
          .fontSize($r('app.float.default_12'))
          .margin({
            top: $r('app.float.default_4')
          })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(Const.FLEX_GROW_1)
      .onClick(() => {
        this.pageStack.pushPathByName('UserProfileComponent', '');
      })

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontColor([$r('sys.color.icon_fourth')])
        .fontWeight(FontWeight.Normal)
        .fontSize($r('app.float.default_24'))
        .onClick(() => {
          this.pageStack.pushPathByName('UserProfileComponent', '');
        })
    }
    .width(Const.THOUSANDTH_940)
    .height(Const.THOUSANDTH_130)
    .borderRadius($r('app.float.default_16'))
    .padding({
      left: $r('app.float.default_12'),
      right: $r('app.float.default_12')
    })
    .backgroundColor($r('sys.color.background_primary'))
    .margin({
      bottom: $r('app.float.default_6')
    })
  }

  private openAvatarEntry(): void {
    if (this.userProfileStore.avatarUri.length > 0) {
      this.pageStack.pushPathByName('AvatarPreviewComponent', '');
      return;
    }
    this.pageStack.pushPathByName('UserProfileComponent', '');
  }
}
