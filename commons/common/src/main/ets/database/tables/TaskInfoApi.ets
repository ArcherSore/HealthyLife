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

import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { RdbUtils } from '../RdbUtils';
import DayInfoApi from './DayInfoApi';
import { TableApi } from './TableApi';
import DayTaskInfoApi from './DayTaskInfoApi';
import ColumnInfo from '../../model/ColumnModel';
import { RdbConstants } from '../../constants/RdbConstants';
import { taskBaseInfoList } from '../../model/TaskBaseModel';
import { CommonConstants as Const } from '../../constants/CommonConstants';
import { defaultTaskInfoList, TaskInfo } from '../../model/database/TaskInfo';
import { AgentUtils } from '../../utils/agent/AgentUtils';
import { convertDate2Str, convertStr2Date } from '../../utils/Utils';

// hilog tag
const TAG: string = 'TaskInfoApi';
// this api table name
const TABLE_NAME: string = RdbConstants.TABLE_OF_TASK;
// this api columns info
const COLUMNS_INFO: ColumnInfo[] = RdbConstants.TABLE_COLUMNS_MAPPING[TABLE_NAME];
// this api columns name of primary key
const PRIMARY_KEY: string = COLUMNS_INFO[0].name;

class TaskInfoApi implements TableApi<TaskInfo> {
  async insert(data: TaskInfo): Promise<number> {
    let result: number = -1;
    const valueBucket = this.convertEntity2ValuesBucket(data, false);
    await RdbUtils.rdbStore?.insert(TABLE_NAME, valueBucket,
      relationalStore.ConflictResolution.ON_CONFLICT_REPLACE).then((rowId: number) => {
      if (rowId === -1) {
        hilog.error(0x0000, TAG, `Insert is failed, data is ${data.toString()}`);
      }
      hilog.info(0x0000, TAG, `Insert is successful, data is ${data.toString()}`);
      result = rowId;
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG,
        `Insert is failed, data is ${data.toString()}, code is ${err.code}, message is ${err.message}`);
    });
    return result;
  }

  async batchInsert(dataList: TaskInfo[]): Promise<number> {
    let result: number = -1;
    const valueBucketList: relationalStore.ValuesBucket[] = [];
    for (let data of dataList) {
      valueBucketList.push(this.convertEntity2ValuesBucket(data, false))
    }
    await RdbUtils.rdbStore?.batchInsert(TABLE_NAME, valueBucketList).then((count: number) => {
      if (count === -1) {
        hilog.error(0x0000, TAG, 'Batch insert is failed');
      }
      hilog.info(0x0000, TAG, 'Batch insert is successful');
      result = count;
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, `Batch insert is failed, code is ${err.code}, message is ${err.message}`);
    });
    return result;
  }

  async delete(primaryKey: number): Promise<boolean> {
    let result = true;
    let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo(PRIMARY_KEY, primaryKey);
    await RdbUtils.rdbStore?.delete(predicates).then((rows: number) => {
      hilog.info(0x0000, TAG, `Delete is successful, primaryKey is ${primaryKey}, affected rows is ${rows}`);
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG,
        `Delete is failed, primaryKey is ${primaryKey}, code is ${err.code}, message is ${err.message}`);
      result = false;
    });
    return result;
  }

  async update(primaryKey: number, data: TaskInfo): Promise<boolean> {
    let result = true;
    const valueBucket = this.convertEntity2ValuesBucket(data, true);
    let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo(PRIMARY_KEY, primaryKey);
    await RdbUtils.rdbStore?.update(valueBucket, predicates,
      relationalStore.ConflictResolution.ON_CONFLICT_REPLACE).then(async (rows: number) => {
      hilog.info(0x0000, TAG,
        `Updated is successful, primaryKey is ${primaryKey}, data is ${data.toString()}, affected rows is ${rows}`);
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG,
        `Updated is failed, primaryKey is ${primaryKey}, data is ${data.toString()}, code is ${err.code}, message is ${err.message}`);
      result = false;
    });
    return result;
  }

  async query(querySql: string): Promise<TaskInfo[]> {
    let resultList: TaskInfo[] = [];
    await RdbUtils.rdbStore?.querySql(querySql).then((resultSet: relationalStore.ResultSet) => {
      while (resultSet.goToNextRow()) {
        resultList.push(this.convertResultSet2Entity(resultSet));
      }
      resultSet.close();
      hilog.info(0x0000, TAG, `Query is successful, querySql is [${querySql}], query count is ${resultList.length}`);
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG,
        `Query is failed, querySql is [${querySql}], code is ${err.code}, message is ${err.message}`);
    });
    return resultList;
  }

  async queryByKey(primaryKey: number): Promise<TaskInfo | null> {
    let result: TaskInfo | null = null;
    let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo(PRIMARY_KEY, primaryKey);
    await RdbUtils.rdbStore?.query(predicates).then((resultSet: relationalStore.ResultSet) => {
      if (resultSet.rowCount === 1) {
        resultSet.goToFirstRow()
        result = this.convertResultSet2Entity(resultSet)
        hilog.info(0x0000, TAG,
          `Query is successful, primaryKey is ${primaryKey}, query result is ${result.toString()}`);
      } else {
        hilog.error(0x0000, TAG, `Query is failed, primaryKey is ${primaryKey}, query count is ${resultSet.rowCount}`);
      }
      resultSet.close();
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG,
        `Query is failed, primaryKey is ${primaryKey}, code is ${err.code}, message is ${err.message}`);
    });
    return result;
  }

  convertEntity2ValuesBucket(data: TaskInfo, excludePrimary: boolean): relationalStore.ValuesBucket {
    let valueBucket = {} as relationalStore.ValuesBucket;
    for (let item of COLUMNS_INFO) {
      if (excludePrimary && item.primary) {
        continue;
      }
      let name = item.name;
      switch (name) {
        case 'taskId':
          valueBucket[name] = data.taskId;
          break;
        case 'isOpen':
          valueBucket[name] = data.isOpen;
          break;
        case 'targetValue':
          valueBucket[name] = data.targetValue;
          break;
        case 'finValue':
          valueBucket[name] = data.finValue;
          break;
        case 'isDone':
          valueBucket[name] = data.isDone;
          break;
        case 'isAlert':
          valueBucket[name] = data.isAlert;
          break;
        case 'alertStartTime':
          valueBucket[name] = data.alertStartTime;
          break;
        case 'alertEndTime':
          valueBucket[name] = data.alertEndTime;
          break;
        case 'alertFrequency':
          valueBucket[name] = data.alertFrequency;
          break;
        case 'reminderId':
          valueBucket[name] = data.reminderId;
          break;
        case 'repeatDays':
          valueBucket[name] = data.repeatDays;
          break;
        case 'scheduleStartDate':
          valueBucket[name] = data.scheduleStartDate;
          break;
        default:
          break;
      }
    }
    return valueBucket;
  }

  convertResultSet2Entity(resultSet: relationalStore.ResultSet): TaskInfo {
    try {
      const taskId = resultSet.getValue(resultSet.getColumnIndex('taskId')) as number;
      const isOpen = resultSet.getValue(resultSet.getColumnIndex('isOpen')) ? true : false;
      const targetValue = resultSet.getValue(resultSet.getColumnIndex('targetValue')) as string;
      const finValue = resultSet.getValue(resultSet.getColumnIndex('finValue')) as string;
      const isDone = resultSet.getValue(resultSet.getColumnIndex('isDone')) ? true : false;
      const isAlert = resultSet.getValue(resultSet.getColumnIndex('isAlert')) ? true : false;
      const alertStartTime = resultSet.getValue(resultSet.getColumnIndex('alertStartTime')) as string;
      const alertEndTime = resultSet.getValue(resultSet.getColumnIndex('alertEndTime')) as string;
      const alertFrequency = resultSet.getValue(resultSet.getColumnIndex('alertFrequency')) as string;
      const reminderId = resultSet.getValue(resultSet.getColumnIndex('reminderId')) as number;
      const repeatDays = resultSet.getValue(resultSet.getColumnIndex('repeatDays')) as number;
      const scheduleStartDate = resultSet.getValue(resultSet.getColumnIndex('scheduleStartDate')) as string;
      return new TaskInfo(taskId, isOpen, targetValue, finValue, isDone, isAlert, alertStartTime, alertEndTime,
        alertFrequency, reminderId, repeatDays, scheduleStartDate || '');
    } catch (error) {
      hilog.error(0x0000, TAG, `an error occurred: ${error}`);
      return new TaskInfo(-1, false, '', '', false, false, '', '', '', -1);
    }

  }

  async ensureScheduleSchema(currentDate: string): Promise<boolean> {
    if (!RdbUtils.rdbStore) {
      return false;
    }
    let columnNames: string[] = [];
    try {
      const resultSet = await RdbUtils.rdbStore.querySql(`PRAGMA table_info(${TABLE_NAME})`);
      while (resultSet.goToNextRow()) {
        columnNames.push(resultSet.getString(resultSet.getColumnIndex('name')));
      }
      resultSet.close();
    } catch (error) {
      hilog.error(0x0000, TAG, `Query task schema failed: ${error}`);
      return false;
    }
    if (!columnNames.includes('repeatDays') &&
      !await RdbUtils.executeSql(`ALTER TABLE ${TABLE_NAME} ADD COLUMN repeatDays INTEGER`)) {
      return false;
    }
    if (!columnNames.includes('scheduleStartDate') &&
      !await RdbUtils.executeSql(`ALTER TABLE ${TABLE_NAME} ADD COLUMN scheduleStartDate TEXT`)) {
      return false;
    }
    const presetSql = `UPDATE ${TABLE_NAME} SET repeatDays = CASE ` +
      `WHEN isOpen = 1 THEN ${Const.REPEAT_DAYS_DAILY} ` +
      `WHEN taskId = ${Const.TASK_RUN_ID} THEN ${Const.REPEAT_DAYS_ONCE} ` +
      `ELSE ${Const.REPEAT_DAYS_DAILY} END WHERE repeatDays IS NULL`;
    if (!await RdbUtils.executeSql(presetSql)) {
      return false;
    }
    return await RdbUtils.executeSql(`UPDATE ${TABLE_NAME} SET scheduleStartDate = CASE ` +
      `WHEN isOpen = 1 THEN '${currentDate}' ELSE '' END ` +
      `WHERE scheduleStartDate IS NULL`);
  }

  /*
   * check if the default task exists and complete it.
   * @returns { Promise<boolean> } check if it was successful.
   */
  async checkDefaultTask(): Promise<boolean> {
    let taskList: TaskInfo[] = await this.query('SELECT * FROM taskInfo');
    if (taskList.length === Const.TASK_NUM) {
      return true;
    }
    let exitsIndex: number[] = [];
    for (let task of taskList) {
      exitsIndex.push(task.taskId);
    }
    let missInfoList: TaskInfo[] = [];
    for (let index = 0; index < Const.TASK_NUM; index++) {
      if (exitsIndex.includes(index)) {
        continue;
      }
      missInfoList.push(defaultTaskInfoList[index]);
    }
    await this.batchInsert(missInfoList);
    return true;
  }

  /*
   * query the list of task information.
   * @returns { Promise<TaskInfo[]> } task list.
   */
  async queryAllTaskInfo(): Promise<TaskInfo[]> {
    let result: TaskInfo[] = [];
    let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.orderByAsc(PRIMARY_KEY)
    await RdbUtils.rdbStore?.query(predicates).then((resultSet: relationalStore.ResultSet) => {
      if (resultSet.rowCount === 0) {
        hilog.info(0x0000, TAG, `Query all task is failed, query result is empty`);
        resultSet.close();
        return;
      }
      while (resultSet.goToNextRow()) {
        result.push(this.convertResultSet2Entity(resultSet));
      }
      hilog.info(0x0000, TAG, `Query all task is successful, query result is ${result.toString()}`);
      resultSet.close();
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, `Query all task is failed, code is ${err.code}, message is ${err.message}`);
    });
    return result;
  }

  /*
   * query the list of opened task information.
   * @returns { Promise<TaskInfo[]> } opened task list.
   */
  async queryOpenedTaskInfo(): Promise<TaskInfo[]> {
    let result: TaskInfo[] = [];
    let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('isOpen', true);
    predicates.orderByAsc(PRIMARY_KEY)
    await RdbUtils.rdbStore?.query(predicates).then((resultSet: relationalStore.ResultSet) => {
      if (resultSet.rowCount === 0) {
        hilog.info(0x0000, TAG, `Query opened task is failed, query result is empty`);
        resultSet.close();
        return;
      }
      while (resultSet.goToNextRow()) {
        result.push(this.convertResultSet2Entity(resultSet));
      }
      hilog.info(0x0000, TAG, `Query opened task is successful, query result is ${result.toString()}`);
      resultSet.close();
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, `Query opened task is failed, code is ${err.code}, message is ${err.message}`);
    });
    return result;
  }

  /* Legacy entry retained for callers outside the feature module. Daily reset no longer disables plans. */
  async resetTasksForNewDay(): Promise<boolean> {
    let initSql = `UPDATE ${TABLE_NAME} SET isDone = 0, finValue = ""`
    let result = await RdbUtils.executeSql(initSql);
    if (result) {
      hilog.info(0x0000, TAG, `Reset tasks for new day is successful`);
    } else {
      hilog.error(0x0000, TAG, `Reset tasks for new day is failed`);
    }
    return result;
  }

  /*
   * Reconcile only the legacy current-day progress fields. isOpen now means that the plan is enabled.
   */
  async reconcileDailyTaskState(date: string): Promise<boolean> {
    let result = true;
    let taskList = await this.queryAllTaskInfo();
    let dayTaskList = await DayTaskInfoApi.queryDayTaskInfo(date);
    for (let taskInfo of taskList) {
      let dayTaskInfo = dayTaskList.find((item) => item.taskId === taskInfo.taskId);
      taskInfo.finValue = dayTaskInfo ? dayTaskInfo.finValue : '';
      taskInfo.isDone = dayTaskInfo ? dayTaskInfo.isDone : false;
      result = await this.update(taskInfo.taskId, taskInfo);
      if (!result) {
        return false;
      }
    }
    return true;
  }

  async generateScheduledTasksForDate(date: string): Promise<boolean> {
    const taskList = await this.queryAllTaskInfo();
    const dayTaskList = await DayTaskInfoApi.queryDayTaskInfo(date);
    for (let taskInfo of taskList) {
      if (!taskInfo.isScheduledOn(date) || dayTaskList.some((item) => item.taskId === taskInfo.taskId)) {
        continue;
      }
      if (await DayTaskInfoApi.insert(taskInfo.convert2DefaultDayTask(date)) === -1) {
        return false;
      }
    }
    return true;
  }

  async expireOneTimePlans(date: string): Promise<boolean> {
    const taskList = await this.queryAllTaskInfo();
    for (let taskInfo of taskList) {
      if (!taskInfo.isOpen || taskInfo.repeatDays !== Const.REPEAT_DAYS_ONCE ||
        taskInfo.scheduleStartDate === '' || taskInfo.scheduleStartDate >= date) {
        continue;
      }
      if (taskInfo.reminderId !== -1 && !await AgentUtils.deleteAgent(taskInfo.reminderId)) {
        return false;
      }
      taskInfo.isOpen = false;
      taskInfo.isAlert = false;
      taskInfo.reminderId = -1;
      taskInfo.finValue = '';
      taskInfo.isDone = false;
      if (!await this.update(taskInfo.taskId, taskInfo)) {
        return false;
      }
    }
    return true;
  }

  async syncTaskForDate(date: string, taskInfo: TaskInfo): Promise<boolean> {
    const key = await DayTaskInfoApi.queryKeyByDateAndTaskId(date, taskInfo.taskId);
    if (!taskInfo.isScheduledOn(date)) {
      if (key !== -1 && !await DayTaskInfoApi.deleteByDateAndTaskId(date, taskInfo.taskId)) {
        return false;
      }
      return await DayInfoApi.updateDayByTaskStatus(date);
    }
    if (key === -1) {
      if (await DayTaskInfoApi.insert(taskInfo.convert2DefaultDayTask(date)) === -1) {
        return false;
      }
    } else {
      const dayTaskInfo = await DayTaskInfoApi.queryByKey(key);
      if (dayTaskInfo) {
        dayTaskInfo.targetValue = taskInfo.targetValue;
        if (!await DayTaskInfoApi.update(key, dayTaskInfo)) {
          return false;
        }
      }
    }
    return await DayInfoApi.updateDayByTaskStatus(date);
  }

  private getRemainingWeekDates(date: string): string[] {
    const currentDate = convertStr2Date(date);
    const daysUntilSunday = (Const.WEEK_DAY_NUM - currentDate.getDay()) % Const.WEEK_DAY_NUM;
    let result: string[] = [];
    for (let offset = 1; offset <= daysUntilSunday; offset++) {
      const futureDate = new Date(currentDate);
      futureDate.setDate(currentDate.getDate() + offset);
      result.push(convertDate2Str(futureDate));
    }
    return result;
  }

  async syncTaskForRemainingWeek(date: string, taskInfo: TaskInfo): Promise<boolean> {
    const remainingDates = this.getRemainingWeekDates(date);
    for (let futureDate of remainingDates) {
      if (!await this.syncTaskForDate(futureDate, taskInfo)) {
        return false;
      }
    }
    return true;
  }

  async syncPlansForRemainingWeek(date: string): Promise<boolean> {
    const taskList = await this.queryAllTaskInfo();
    for (let taskInfo of taskList) {
      if (!await this.syncTaskForRemainingWeek(date, taskInfo)) {
        return false;
      }
    }
    return true;
  }

  async saveTaskPlan(date: string, taskInfo: TaskInfo): Promise<boolean> {
    if (taskInfo.isOpen && taskInfo.scheduleStartDate === '') {
      taskInfo.scheduleStartDate = date;
    }
    if (!await this.update(taskInfo.taskId, taskInfo)) {
      return false;
    }
    if (!await this.syncTaskForDate(date, taskInfo)) {
      return false;
    }
    return await this.syncTaskForRemainingWeek(date, taskInfo);
  }

  /*
   * Open the task and update the relevant information synchronously.
   * @param { string } date date of the day.
   * @param { number } taskId id of the task.
   * @returns { Promise<boolean> } whether it was successful or not.
   */
  async openTask(date: string, taskId: number): Promise<boolean> {
    let taskInfo = await this.queryByKey(taskId);
    if (!taskInfo) {
      return false;
    }
    taskInfo.isOpen = true;
    taskInfo.scheduleStartDate = date;
    taskInfo.finValue = '';
    taskInfo.isDone = false;
    return await this.saveTaskPlan(date, taskInfo);
  }

  /*
   * Open the task and update the relevant information synchronously.
   * @param { string } date date of the day.
   * @param { number } taskId id of the task.
   * @returns { Promise<boolean> } whether it was successful or not.
   */
  async closeTask(date: string, taskId: number): Promise<boolean> {
    // Determine whether the task is open.
    let oldTaskInfo = await this.queryByKey(taskId);
    if (!oldTaskInfo) {
      return false;
    }
    let result = true;
    if (oldTaskInfo.reminderId !== -1) {
      let deleted = await AgentUtils.deleteAgent(oldTaskInfo.reminderId);
      if (!deleted) {
        hilog.error(0x0000, TAG,
          `Failed to delete reminder agent ${oldTaskInfo.reminderId} for task ${taskId}, proceeding with close`);
      }
    }
    oldTaskInfo.isOpen = false;
    oldTaskInfo.isAlert = false;
    oldTaskInfo.reminderId = -1;
    oldTaskInfo.finValue = '';
    oldTaskInfo.isDone = false;
    oldTaskInfo.scheduleStartDate = '';
    result = await this.update(taskId, oldTaskInfo);
    if (!result) {
      return false;
    }

    result = await DayTaskInfoApi.deleteByDateAndTaskId(date, taskId);
    if (!result) {
      return result;
    }

    result = await DayInfoApi.updateDayByTaskStatus(date);
    if (!result) {
      return false;
    }

    // Delete all future DayTask rows beyond today (covers next week etc.)
    let affectedDates = await DayTaskInfoApi.deleteByTaskIdFromDate(date, taskId);
    for (let affectedDate of affectedDates) {
      if (!await DayInfoApi.updateDayByTaskStatus(affectedDate)) {
        return false;
      }
    }

    return true;
  }

  async skipTaskForDate(date: string, taskId: number): Promise<boolean> {
    const taskInfo = await this.queryByKey(taskId);
    if (!taskInfo) {
      return false;
    }
    if (taskInfo.repeatDays === Const.REPEAT_DAYS_ONCE) {
      return await this.closeTask(date, taskId);
    }
    if (!await DayTaskInfoApi.deleteByDateAndTaskId(date, taskId)) {
      return false;
    }
    taskInfo.finValue = '';
    taskInfo.isDone = false;
    if (!await this.update(taskId, taskInfo)) {
      return false;
    }
    return await DayInfoApi.updateDayByTaskStatus(date);
  }

  /*
   * Clock the task and update the relevant information synchronously.
   * @param { string } date date of the day.
   * @param { number } taskId id of the task.
   * @returns { Promise<boolean> } whether it was successful or not.
   */
  async clockTask(date: string, taskId: number): Promise<boolean> {
    let taskInfo = await this.queryByKey(taskId);
    if (!taskInfo) {
      return false;
    }
    let key = await DayTaskInfoApi.queryKeyByDateAndTaskId(date, taskId);
    let dayTaskInfo = key === -1 ? null : await DayTaskInfoApi.queryByKey(key);
    if (!dayTaskInfo) {
      hilog.info(0x0000, TAG, `The task is not scheduled today and cannot be clocked, taskId is ${taskId}`);
      return true;
    }
    let step = taskBaseInfoList[taskId].step;
    if (dayTaskInfo.isDone && step === 0) {
      hilog.info(0x0000, TAG, `The current task is done and cannot be clock, taskId is ${taskInfo.taskId}`);
      return true;
    }

    let result = true;
    if (step === 0) {
      dayTaskInfo.finValue = dayTaskInfo.targetValue;
      dayTaskInfo.isDone = true;
    } else {
      let finValue = Number(dayTaskInfo.finValue) + step;
      dayTaskInfo.finValue = finValue.toString();
      if (!dayTaskInfo.isDone) {
        dayTaskInfo.isDone = finValue >= Number(dayTaskInfo.targetValue);
      }
    }

    taskInfo.finValue = dayTaskInfo.finValue;
    taskInfo.isDone = dayTaskInfo.isDone;

    result = await this.update(taskId, taskInfo);
    if (!result) {
      return result;
    }

    result = await DayTaskInfoApi.update(key, dayTaskInfo);
    if (!result) {
      return result;
    }
    // Synchronously modify the information for the day info.
    return await DayInfoApi.updateDayByTaskStatus(date);
  }
}

export default new TaskInfoApi();
