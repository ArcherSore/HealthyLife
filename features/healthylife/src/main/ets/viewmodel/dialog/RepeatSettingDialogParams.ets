/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

import { CommonConstants as Const, TaskInfo } from 'common';

export class RepeatSettingDialogParams {
  taskInfo: TaskInfo;
  selectedDays: number;
  customDays: number;

  constructor(taskInfo: TaskInfo) {
    this.taskInfo = taskInfo;
    this.selectedDays = taskInfo.repeatDays;
    this.customDays = this.isPreset(taskInfo.repeatDays) ? (1 << new Date().getDay()) : taskInfo.repeatDays;
  }

  isPreset(days: number): boolean {
    return days === Const.REPEAT_DAYS_ONCE || days === Const.REPEAT_DAYS_DAILY ||
      days === Const.REPEAT_DAYS_WEEKDAY || days === Const.REPEAT_DAYS_WEEKEND;
  }

  isCustom(): boolean {
    return !this.isPreset(this.selectedDays);
  }
}
