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

import { CommonConstants as Const, convertTime2Date, TaskInfo } from 'common';

export enum ReminderSettingType {
  TIME = 'time',
  FREQUENCY = 'frequency'
}

export class ReminderSettingDialogParams {
  taskInfo: TaskInfo;
  settingType: ReminderSettingType;
  selectedValue: string;
  startDate: Date;
  endDate: Date;

  constructor(taskInfo: TaskInfo, settingType: ReminderSettingType) {
    this.taskInfo = taskInfo;
    this.settingType = settingType;
    this.selectedValue = settingType === ReminderSettingType.TIME ? taskInfo.alertStartTime : taskInfo.alertFrequency;
    if (this.selectedValue === '') {
      this.selectedValue = settingType === ReminderSettingType.TIME ? '08:00' : Const.REMINDER_FREQUENCY_DAILY;
    }
    this.startDate = convertTime2Date('00:00');
    this.endDate = convertTime2Date('23:59');
  }
}
