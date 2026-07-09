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

import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { PreferencesUtils } from 'common/src/main/ets/utils/PreferencesUtils';

const USER_PROFILE_AVATAR_URI = 'userProfileAvatarUri';
const USER_PROFILE_NICKNAME = 'userProfileNickname';
const USER_PROFILE_GENDER = 'userProfileGender';
const USER_PROFILE_BIRTHDAY = 'userProfileBirthday';
const USER_PROFILE_HEIGHT = 'userProfileHeight';
const USER_PROFILE_WEIGHT = 'userProfileWeight';
const PREFERENCE_EMPTY_VALUE = 'default';

export const DEFAULT_NICKNAME = 'Jolin';
export const DEFAULT_BIRTHDAY = '1999-12-31';
export const GENDER_MALE = 'male';
export const GENDER_FEMALE = 'female';
export const GENDER_SECRET = 'secret';

@Observed
export class UserProfileStore {
  public avatarUri: string;
  public nickname: string;
  public gender: string;
  public birthday: string;
  public height: string;
  public weight: string;

  constructor(avatarUri: string = '', nickname: string = DEFAULT_NICKNAME, gender: string = GENDER_SECRET,
    birthday: string = DEFAULT_BIRTHDAY, height: string = '', weight: string = '') {
    this.avatarUri = avatarUri;
    this.nickname = nickname;
    this.gender = gender;
    this.birthday = birthday;
    this.height = height;
    this.weight = weight;
  }

  async saveAvatarUri(avatarUri: string): Promise<void> {
    this.avatarUri = avatarUri;
    await PreferencesUtils.putPreference(USER_PROFILE_AVATAR_URI, avatarUri);
  }

  async saveNickname(nickname: string): Promise<void> {
    this.nickname = nickname;
    await PreferencesUtils.putPreference(USER_PROFILE_NICKNAME, nickname);
  }

  async saveGender(gender: string): Promise<void> {
    this.gender = gender;
    await PreferencesUtils.putPreference(USER_PROFILE_GENDER, gender);
  }

  async saveBirthday(birthday: string): Promise<void> {
    this.birthday = birthday;
    await PreferencesUtils.putPreference(USER_PROFILE_BIRTHDAY, birthday);
  }

  async saveHeight(height: string): Promise<void> {
    this.height = height;
    await PreferencesUtils.putPreference(USER_PROFILE_HEIGHT, height);
  }

  async saveWeight(weight: string): Promise<void> {
    this.weight = weight;
    await PreferencesUtils.putPreference(USER_PROFILE_WEIGHT, weight);
  }
}

export async function initUserProfileStore(): Promise<UserProfileStore> {
  const avatarUri = normalizePreferenceValue(await PreferencesUtils.getPreference(USER_PROFILE_AVATAR_URI), '');
  const nickname = normalizePreferenceValue(await PreferencesUtils.getPreference(USER_PROFILE_NICKNAME), DEFAULT_NICKNAME);
  const gender = normalizeGender(normalizePreferenceValue(await PreferencesUtils.getPreference(USER_PROFILE_GENDER),
    GENDER_SECRET));
  const birthday = normalizePreferenceValue(await PreferencesUtils.getPreference(USER_PROFILE_BIRTHDAY),
    DEFAULT_BIRTHDAY);
  const height = normalizePreferenceValue(await PreferencesUtils.getPreference(USER_PROFILE_HEIGHT), '');
  const weight = normalizePreferenceValue(await PreferencesUtils.getPreference(USER_PROFILE_WEIGHT), '');

  return new UserProfileStore(avatarUri, nickname, gender, birthday, height, weight);
}

export async function selectAvatarFromGallery(): Promise<string> {
  try {
    let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    photoSelectOptions.maxSelectNumber = 1;
    let photoPicker = new photoAccessHelper.PhotoViewPicker();
    let photoSelectResult = await photoPicker.select(photoSelectOptions);
    if (photoSelectResult.photoUris.length === 0) {
      return '';
    }
    return photoSelectResult.photoUris[0];
  } catch (error) {
    return '';
  }
}

function normalizePreferenceValue(value: string, defaultValue: string): string {
  if (value === '' || value === PREFERENCE_EMPTY_VALUE) {
    return defaultValue;
  }
  return value;
}

function normalizeGender(gender: string): string {
  if (gender === GENDER_MALE || gender === GENDER_FEMALE || gender === GENDER_SECRET) {
    return gender;
  }
  return GENDER_SECRET;
}
