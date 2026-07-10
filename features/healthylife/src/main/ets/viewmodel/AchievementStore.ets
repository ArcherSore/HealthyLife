
import { JSON } from '@kit.ArkTS';
import { CommonConstants as Const, taskBaseInfoList, DayTaskInfo, convertDate2Str, convertStr2Date } from 'common';
import { getAchievementDoneIndex, getTaskOverAchievementDoneIndex } from '../model/AchievementModel';
import { TaskInfoDialogParams } from './dialog/TaskInfoDialogParams';
import { PreferencesUtils } from 'common/src/main/ets/utils/PreferencesUtils';
import { openAchievementCustomDialog } from '../views/dialog/AchievementDialog';
import DayInfoApi from 'common/src/main/ets/database/tables/DayInfoApi';
import DayTaskInfoApi from 'common/src/main/ets/database/tables/DayTaskInfoApi';

@Observed
export class AchievementStore {
  public maxConsecutiveDays: number;
  public currentConsecutiveDays: number;
  public currentDayStatus: boolean;
  public taskOverAchievement: number[];

  constructor(maxConsecutiveDays: number, currentConsecutiveDays: number, currentDayStatus: boolean,
    taskOverAchievement: number[]) {
    this.maxConsecutiveDays = maxConsecutiveDays;
    this.currentConsecutiveDays = currentConsecutiveDays;
    this.currentDayStatus = currentDayStatus;
    this.taskOverAchievement = taskOverAchievement;
  }
}

export async function calculateStreaksFromDb(): Promise<Record<string, number>> {
  const dayInfos = await DayInfoApi.query("SELECT * FROM dayInfo ORDER BY date ASC");
  if (dayInfos.length === 0) {
    return { 'maxStreak': 0, 'currentStreak': 0 };
  }

  const completedDates: Date[] = [];
  for (let i = 0; i < dayInfos.length; i++) {
    const info = dayInfos[i];
    if (info.targetTaskNum > 0 && info.finTaskNum >= info.targetTaskNum) {
      completedDates.push(convertStr2Date(info.date));
    }
  }

  if (completedDates.length === 0) {
    return { 'maxStreak': 0, 'currentStreak': 0 };
  }

  // Calculate maxStreak
  let maxStreak = 0;
  let tempStreak = 0;
  let prevDate: Date | null = null;

  for (let i = 0; i < completedDates.length; i++) {
    const currDate = completedDates[i];
    if (prevDate === null) {
      tempStreak = 1;
    } else {
      const diffTime = currDate.getTime() - prevDate.getTime();
      const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));
      if (diffDays === 1) {
        tempStreak++;
      } else if (diffDays > 1) {
        maxStreak = Math.max(maxStreak, tempStreak);
        tempStreak = 1;
      }
    }
    prevDate = currDate;
  }
  maxStreak = Math.max(maxStreak, tempStreak);

  // Calculate currentStreak
  const completedDateStrings: string[] = [];
  for (let i = 0; i < dayInfos.length; i++) {
    const info = dayInfos[i];
    if (info.targetTaskNum > 0 && info.finTaskNum >= info.targetTaskNum) {
      completedDateStrings.push(info.date);
    }
  }

  const todayStr = convertDate2Str(new Date());
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = convertDate2Str(yesterday);

  let currentStreak = 0;
  let checkDate = new Date();

  if (completedDateStrings.includes(todayStr)) {
    // start from today
  } else if (completedDateStrings.includes(yesterdayStr)) {
    checkDate.setDate(checkDate.getDate() - 1);
  } else {
    return { 'maxStreak': maxStreak, 'currentStreak': 0 };
  }

  while (true) {
    const checkDateStr = convertDate2Str(checkDate);
    if (completedDateStrings.includes(checkDateStr)) {
      currentStreak++;
      checkDate.setDate(checkDate.getDate() - 1);
    } else {
      break;
    }
  }

  return { 'maxStreak': maxStreak, 'currentStreak': currentStreak };
}

export async function syncStreaksFromDb(store: AchievementStore, uIContext: UIContext) {
  const streaks = await calculateStreaksFromDb();
  const maxStreak = streaks['maxStreak'];
  const currentStreak = streaks['currentStreak'];

  if (currentStreak !== store.currentConsecutiveDays) {
    store.currentConsecutiveDays = currentStreak;
    await PreferencesUtils.putPreference(Const.CURRENT_CONSECUTIVE_DAYS, String(currentStreak));
  }

  const todayStr = convertDate2Str(new Date());
  const todayInfo = await DayInfoApi.queryByKey(todayStr);
  const isTodayDone = todayInfo ? (todayInfo.targetTaskNum > 0 && todayInfo.finTaskNum >= todayInfo.targetTaskNum) : false;
  if (isTodayDone !== store.currentDayStatus) {
    store.currentDayStatus = isTodayDone;
    await PreferencesUtils.putPreference(Const.CURRENT_DAY_STATUS, String(isTodayDone));
  }

  if (maxStreak !== store.maxConsecutiveDays) {
    const isNewAchievement = maxStreak > store.maxConsecutiveDays;
    store.maxConsecutiveDays = maxStreak;
    await PreferencesUtils.putPreference(Const.MAX_CONSECUTIVE_DAYS, String(maxStreak));
    if (isNewAchievement) {
      const achievementDoneIndex = getAchievementDoneIndex(maxStreak);
      if (achievementDoneIndex !== -1) {
        openAchievementCustomDialog(uIContext, achievementDoneIndex, 'global', -1, true);
      }
    }
  }
}

export async function initAchievementStore() {
  const streaks = await calculateStreaksFromDb();
  const maxConsecutiveDays = streaks['maxStreak'];
  const currentConsecutiveDays = streaks['currentStreak'];

  const todayStr = convertDate2Str(new Date());
  const todayInfo = await DayInfoApi.queryByKey(todayStr);
  const currentDayStatus = todayInfo ? (todayInfo.targetTaskNum > 0 && todayInfo.finTaskNum >= todayInfo.targetTaskNum) : false;

  await PreferencesUtils.putPreference(Const.MAX_CONSECUTIVE_DAYS, String(maxConsecutiveDays));
  await PreferencesUtils.putPreference(Const.CURRENT_CONSECUTIVE_DAYS, String(currentConsecutiveDays));
  await PreferencesUtils.putPreference(Const.CURRENT_DAY_STATUS, String(currentDayStatus));

  // Recalculate over-achievements from DB on startup
  const dayTasksForInit = await DayTaskInfoApi.query("SELECT * FROM dayTaskInfo");
  const taskOverAchievement = new Array<number>(Const.TASK_NUM).fill(0);
  for (let i = 0; i < dayTasksForInit.length; i++) {
    const item = dayTasksForInit[i];
    const tId = item.taskId;
    const targetValue = Number(item.targetValue);
    const finValue = Number(item.finValue);
    if (targetValue > 0 && tId >= 0 && tId < Const.TASK_NUM) {
      const percentage = Math.floor(finValue / targetValue * 100);
      if (percentage > taskOverAchievement[tId]) {
        taskOverAchievement[tId] = percentage;
      }
    }
  }
  await PreferencesUtils.putPreference(Const.TASK_OVER_ACHIEVEMENT, JSON.stringify(taskOverAchievement));

  return new AchievementStore(maxConsecutiveDays, currentConsecutiveDays, currentDayStatus, taskOverAchievement);
}

export async function updateAchievementStore(params: TaskInfoDialogParams) {
  await syncStreaksFromDb(params.achievementStore, params.uIContext);
}

export async function syncTaskOverAchievementDb(store: AchievementStore, uIContext: UIContext, taskId: number) {
  const dayTasks = await DayTaskInfoApi.query("SELECT * FROM dayTaskInfo");
  const maxPercentages = new Array<number>(Const.TASK_NUM).fill(0);
  for (let i = 0; i < dayTasks.length; i++) {
    const item = dayTasks[i];
    const tId = item.taskId;
    const targetValue = Number(item.targetValue);
    const finValue = Number(item.finValue);
    if (targetValue > 0 && tId >= 0 && tId < Const.TASK_NUM) {
      const percentage = Math.floor(finValue / targetValue * 100);
      if (percentage > maxPercentages[tId]) {
        maxPercentages[tId] = percentage;
      }
    }
  }

  const oldPercentage = store.taskOverAchievement[taskId];
  const newPercentage = maxPercentages[taskId];

  if (newPercentage !== oldPercentage) {
    store.taskOverAchievement[taskId] = newPercentage;
    store.taskOverAchievement = [...store.taskOverAchievement];
    await PreferencesUtils.putPreference(Const.TASK_OVER_ACHIEVEMENT, JSON.stringify(store.taskOverAchievement));

    const thresholds: number[] = [Const.OVER_ACHIEVEMENT_200, Const.OVER_ACHIEVEMENT_300, Const.OVER_ACHIEVEMENT_400];
    for (let i = 0; i < thresholds.length; i++) {
      if (newPercentage >= thresholds[i] && oldPercentage < thresholds[i]) {
        const overIndex = getTaskOverAchievementDoneIndex(taskId, thresholds[i]);
        if (overIndex !== -1) {
          openAchievementCustomDialog(uIContext, overIndex, 'taskOverAchievement', taskId, true);
        }
      }
    }
  }
}

export async function updateTaskAchievementStore(params: TaskInfoDialogParams) {
  await syncTaskOverAchievementDb(params.achievementStore, params.uIContext, params.dayTaskInfo.taskId);
}
