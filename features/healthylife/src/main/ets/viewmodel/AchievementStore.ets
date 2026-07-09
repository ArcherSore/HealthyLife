
import { JSON } from '@kit.ArkTS';
import { CommonConstants as Const, taskBaseInfoList, DayTaskInfo } from 'common';
import { getAchievementDoneIndex, getTaskOverAchievementDoneIndex } from '../model/AchievementModel';
import { TaskInfoDialogParams } from './dialog/TaskInfoDialogParams';
import { PreferencesUtils } from 'common/src/main/ets/utils/PreferencesUtils';
import { openAchievementCustomDialog } from '../views/dialog/AchievementDialog';

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

export async function initAchievementStore() {
  const maxConsecutiveDays = Number(await PreferencesUtils.getPreference(Const.MAX_CONSECUTIVE_DAYS));
  const currentConsecutiveDays = Number(await PreferencesUtils.getPreference(Const.CURRENT_CONSECUTIVE_DAYS));
  const currentDayStatusStr: string = await PreferencesUtils.getPreference(Const.CURRENT_DAY_STATUS);
  const currentDayStatus = JSON.parse(currentDayStatusStr) as boolean;

  const taskOverStr: string = await PreferencesUtils.getPreference(Const.TASK_OVER_ACHIEVEMENT);
  let taskOverAchievement: number[] = JSON.parse(taskOverStr) as number[];
  if (taskOverAchievement.length !== Const.TASK_NUM) {
    taskOverAchievement = new Array<number>(Const.TASK_NUM).fill(0);
  }

  return new AchievementStore(maxConsecutiveDays, currentConsecutiveDays, currentDayStatus, taskOverAchievement);
}

export async function updateAchievementStore(params: TaskInfoDialogParams) {
  const dayInfo = params.homeStore.weekList[params.homeStore.selectedDay];
  if (dayInfo.finTaskNum < dayInfo.targetTaskNum || params.achievementStore.currentDayStatus) {
    return;
  }

  params.achievementStore.currentConsecutiveDays += 1;
  await PreferencesUtils.putPreference(Const.CURRENT_CONSECUTIVE_DAYS,
    String(params.achievementStore.currentConsecutiveDays));
  params.achievementStore.currentDayStatus = true;
  await PreferencesUtils.putPreference(Const.CURRENT_DAY_STATUS, String(params.achievementStore.currentDayStatus));

  if (params.achievementStore.currentConsecutiveDays > params.achievementStore.maxConsecutiveDays) {
    params.achievementStore.maxConsecutiveDays = params.achievementStore.currentConsecutiveDays;
    await PreferencesUtils.putPreference(Const.MAX_CONSECUTIVE_DAYS,
      String(params.achievementStore.maxConsecutiveDays));
    const achievementDoneIndex = getAchievementDoneIndex(params.achievementStore.maxConsecutiveDays);
    if (achievementDoneIndex !== -1) {
      openAchievementCustomDialog(params.uIContext, achievementDoneIndex, 'global', -1);
    }
  }
}

export async function updateTaskAchievementStore(params: TaskInfoDialogParams) {
  const taskId = params.dayTaskInfo.taskId;
  const store = params.achievementStore;
  const currentTask = params.homeStore.taskList.find((task: DayTaskInfo) => task.taskId === taskId);
  if (!currentTask) {
    return;
  }

  const step = taskBaseInfoList[taskId].step;
  if (step > 0) {
    const targetValue = Number(currentTask.targetValue);
    const finValue = Number(currentTask.finValue);
    if (targetValue > 0) {
      const percentage = Math.floor(finValue / targetValue * 100);
      if (percentage > store.taskOverAchievement[taskId]) {
        store.taskOverAchievement[taskId] = percentage;
        await PreferencesUtils.putPreference(Const.TASK_OVER_ACHIEVEMENT, JSON.stringify(store.taskOverAchievement));
        const thresholds: number[] = [Const.OVER_ACHIEVEMENT_200, Const.OVER_ACHIEVEMENT_300, Const.OVER_ACHIEVEMENT_400];
        for (let i = 0; i < thresholds.length; i++) {
          if (percentage >= thresholds[i]) {
            const overIndex = getTaskOverAchievementDoneIndex(taskId, thresholds[i]);
            if (overIndex !== -1) {
              openAchievementCustomDialog(params.uIContext, overIndex, 'taskOverAchievement', taskId);
            }
          }
        }
      }
    }
  }
}
