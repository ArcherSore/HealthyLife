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

import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { TaskInfo } from '../../model/database/TaskInfo';
import { TaskBaseInfo } from '../../model/TaskBaseModel';
import { CommonConstants as Const } from '../../constants/CommonConstants';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { convertDate2Str, convertStr2Date } from '../Utils';

const TAG: string = '[AgentUtils]';

export class AgentUtils {
  static async creatAgent(taskInfo: TaskInfo, taskBaseInfo: TaskBaseInfo, date: string,
    uIContext: UIContext): Promise<number> {
    let targetReminderAgent = AgentUtils.agentConfigSet(taskInfo, taskBaseInfo, date, uIContext);
    if (!targetReminderAgent) {
      return -1;
    }
    try {
      let reminderId: number = await reminderAgentManager.publishReminder(targetReminderAgent); // 发布的提醒ID
      hilog.info(0x0000, TAG, `Succeeded in publishing reminder. `);
      return reminderId;
    } catch (err) {
      hilog.error(0x0000, TAG, `Failed to publish reminder. Code: ${err.code}, message: ${err.message}`);
    }
    return -1;
  }

  static async updateAgent(taskInfo: TaskInfo, taskBaseInfo: TaskBaseInfo, date: string,
    uIContext: UIContext): Promise<boolean> {
    let targetReminderAgent = AgentUtils.agentConfigSet(taskInfo, taskBaseInfo, date, uIContext);
    if (!targetReminderAgent) {
      return false;
    }
    try {
      await reminderAgentManager.updateReminder(taskInfo.reminderId, targetReminderAgent);
      hilog.info(0x0000, TAG, `Succeeded in updating reminder, reminderId is ${taskInfo.reminderId}`);
      return true;
    } catch (err) {
      hilog.error(0x0000, TAG,
        `Failed to update reminder. Code: ${err.code}, message: ${err.message}`);
      return false;
    }
  }

  static async deleteAgent(reminderId: number): Promise<boolean> {
    // The value of reminderId is obtained from the callback after the reminder agent is successfully published.
    try {
      await reminderAgentManager.cancelReminder(reminderId);
      hilog.info(0x0000, TAG, `Succeeded in canceling reminder. `);
      return true;
    } catch (err) {
      const businessError = err as BusinessError;
      if (businessError.code === 1700003) {
        hilog.info(0x0000, TAG, `Reminder is already inactive, reminderId is ${reminderId}`);
        return true;
      }
      hilog.error(0x0000, TAG, `Failed to cancel reminder. Code: ${err.code}, message: ${err.message}`);
      return false;
    }
  }

  static shouldScheduleReminder(taskInfo: TaskInfo, date: string): boolean {
    if (!taskInfo.isAlert || date !== convertDate2Str(new Date())) {
      return false;
    }
    let taskDate = convertStr2Date(date);
    let dayOfWeek = taskDate.getDay();
    if (taskInfo.alertFrequency === Const.REMINDER_FREQUENCY_WEEKDAY && (dayOfWeek === 0 || dayOfWeek === 6)) {
      return false;
    }
    if (taskInfo.alertFrequency === Const.REMINDER_FREQUENCY_WEEKEND && dayOfWeek !== 0 && dayOfWeek !== 6) {
      return false;
    }
    let reminderTime = taskInfo.alertStartTime || taskInfo.targetValue || '08:00';
    let hourMin = reminderTime.split(':');
    if (hourMin.length !== 2) {
      return false;
    }
    let hour = parseInt(hourMin[0]);
    let minute = parseInt(hourMin[1]);
    if (Number.isNaN(hour) || Number.isNaN(minute)) {
      return false;
    }
    let reminderDate = new Date(taskDate.getFullYear(), taskDate.getMonth(), taskDate.getDate(), hour, minute, 0);
    return reminderDate.getTime() > Date.now();
  }

  static agentConfigSet(taskInfo: TaskInfo, taskBaseInfo: TaskBaseInfo, date: string,
    uIContext: UIContext): reminderAgentManager.ReminderRequestCalendar | undefined {
    if (!AgentUtils.shouldScheduleReminder(taskInfo, date)) {
      hilog.info(0x0000, TAG, `Skip reminder for inactive date or elapsed time, taskId is ${taskInfo.taskId}`);
      return undefined;
    }
    // Adjust the time format
    let reminderTime = taskInfo.alertStartTime || taskInfo.targetValue || '08:00';
    let hourMin = reminderTime.split(':');
    let taskDate = convertStr2Date(date);
    try {
      let displayText = uIContext.getHostContext()?.resourceManager.getStringSync(taskBaseInfo.name.id);
      let targetReminderAgent: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: taskDate.getFullYear(),
          month: taskDate.getMonth() + 1,
          day: taskDate.getDate(),
          hour: parseInt(hourMin[0]),
          minute: parseInt(hourMin[1])
        },
        actionButton: [
          {
            title: 'close',
            type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
          },
          {
            title: 'snooze',
            type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_SNOOZE
          },
        ],
        wantAgent: {
          pkgName: 'com.huawei.healthylife',
          abilityName: 'EntryAbility'
        },
        ringDuration: 10,
        snoozeTimes: 2,
        timeInterval: 5 * 60,
        title: displayText,
        content: displayText,
        expiredContent: 'this reminder has expired',
        snoozeContent: 'remind later',
        slotType: notificationManager.SlotType.SOCIAL_COMMUNICATION
      }
      return targetReminderAgent;
    } catch (error) {
      hilog.error(0x0000, TAG, `an error occurred: ${error}`);
      return undefined
    }
  }
}
