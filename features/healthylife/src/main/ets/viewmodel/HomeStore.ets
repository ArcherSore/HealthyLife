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

import {
  CommonConstants as Const, convertDate2Str, DayInfo, DayTaskInfo
} from 'common';
import DayInfoApi from 'common/src/main/ets/database/tables/DayInfoApi';
import DayTaskInfoApi from 'common/src/main/ets/database/tables/DayTaskInfoApi';

/*
 * Global day and tasks information storage.
 */
@Observed
export class HomeStore {
  // three consecutive weeks where the current date is located
  public weekList: DayInfo[];
  public selectedDay: number;
  public currentDate: string;
  public taskList: DayTaskInfo[];
  public weekTaskMap: Record<string, DayTaskInfo[]>;

  constructor(weekList: DayInfo[], selectedDay: number, currentDate: string, taskList: DayTaskInfo[],
    weekTaskMap: Record<string, DayTaskInfo[]> = {}) {
    this.weekList = weekList;
    this.selectedDay = selectedDay;
    this.currentDate = currentDate;
    this.taskList = taskList;
    this.weekTaskMap = weekTaskMap;
  }

  public checkCurrentDay(): boolean {
    return convertDate2Str(new Date()) === this.currentDate;
  }

  public getTaskListByDate(date: string): DayTaskInfo[] {
    return this.weekTaskMap[date] || [];
  }
}

/*
 * Initialize the global storage information of the day.
 * @param { Date } date Date of the day.
 * @returns { Promise<HomeStore> } The global storage information.
 */
export async function initCurrentDateInfo(date: Date): Promise<HomeStore> {
  let dayOfWeek = date.getDay();
  let selectedDay = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
  let dateList: Date[] = getWeekDates(date, selectedDay);
  let weekList: DayInfo[] = [];
  let weekTaskMap: Record<string, DayTaskInfo[]> = {};
  for (let dateOfWeek of dateList) {
    let dateStr = convertDate2Str(dateOfWeek);
    let dayTaskList = await DayTaskInfoApi.queryDayTaskInfo(dateStr);
    let dayInfo = await syncDayInfoWithTasks(dateStr, dayTaskList);
    weekList.push(dayInfo);
    weekTaskMap[dateStr] = dayTaskList;
  }

  let dateStr = convertDate2Str(date);
  let taskList: DayTaskInfo[] = await DayTaskInfoApi.queryDayTaskInfo(dateStr);
  weekTaskMap[dateStr] = taskList;
  return new HomeStore(weekList, selectedDay + Const.WEEK_DAY_NUM, dateStr, taskList, weekTaskMap);
}

/*
 * Update the task list information in the global storage information.
 * @param { HomeStore } homeStore The global storage information.
 * @returns { Promise<void> }  A promise object.
 */
export async function updateTaskList(homeStore: HomeStore): Promise<void> {
  for (let index = 0; index < homeStore.weekList.length; index++) {
    const dateStr = homeStore.weekList[index].date;
    let dayTaskList = await DayTaskInfoApi.queryDayTaskInfo(dateStr);
    homeStore.weekList[index] = await syncDayInfoWithTasks(dateStr, dayTaskList);
    homeStore.weekTaskMap[dateStr] = dayTaskList;
  }

  let dateStr = homeStore.currentDate;
  let taskList: DayTaskInfo[] = await DayTaskInfoApi.queryDayTaskInfo(dateStr);
  homeStore.taskList = taskList;
  homeStore.weekTaskMap[dateStr] = taskList;
}

async function syncDayInfoWithTasks(date: string, taskList: DayTaskInfo[]): Promise<DayInfo> {
  let finTaskNum = 0;
  for (let taskInfo of taskList) {
    if (taskInfo.isDone) {
      finTaskNum++;
    }
  }
  let dayInfo = await DayInfoApi.queryByKey(date);
  if (dayInfo === null) {
    dayInfo = new DayInfo(date, taskList.length, finTaskNum);
    // Future task instances are previews. Persist DayInfo only when that date actually arrives.
    if (taskList.length > 0 && date <= convertDate2Str(new Date())) {
      await DayInfoApi.insert(dayInfo);
    }
    return dayInfo;
  }
  if (dayInfo.targetTaskNum !== taskList.length || dayInfo.finTaskNum !== finTaskNum) {
    await DayInfoApi.updateByKey(date, taskList.length, finTaskNum);
    dayInfo = new DayInfo(date, taskList.length, finTaskNum);
  }
  return dayInfo;
}

/*
 * Get a list of dates for three weeks before and after the day.
 * @param { Date } inputDate Date of the day.
 * @param { number } adjustDays The difference between the day and Monday.
 * @returns { Date[] } The array of three weeks.
 */
function getWeekDates(inputDate: Date, adjustDays: number): Date[] {
  const monday = new Date(inputDate);
  monday.setDate(inputDate.getDate() - adjustDays - Const.WEEK_DAY_NUM);

  const dates: Date[] = [];
  for (let i = 0; i < Const.WEEK_DAY_NUM * 3; i++) {
    // eslint-disable-next-line @performance/reuse-date-instances-check
    const currentDate = new Date(monday);
    currentDate.setDate(monday.getDate() + i);
    dates.push(currentDate);
  }
  return dates;
}
