
export interface AchievementItem {
  level: number;
  name: string;
  iconOn: Resource;
  iconOff: Resource;
}

export interface TaskOverAchievementItem {
  taskId: number;
  percentage: number;
  name: string;
  iconOn: Resource;
  iconOff: Resource;
}

export const AchievementList: AchievementItem[] = [
  {
    level: 3,
    name: '3',
    iconOn: $r('app.media.ic_badge_3_on'),
    iconOff: $r('app.media.ic_badge_3_off')
  },
  {
    level: 7,
    name: '7',
    iconOn: $r('app.media.ic_badge_7_on'),
    iconOff: $r('app.media.ic_badge_7_off')
  },
  {
    level: 30,
    name: '30',
    iconOn: $r('app.media.ic_badge_30_on'),
    iconOff: $r('app.media.ic_badge_30_off')
  },
  {
    level: 50,
    name: '50',
    iconOn: $r('app.media.ic_badge_50_on'),
    iconOff: $r('app.media.ic_badge_50_off')
  },
  {
    level: 73,
    name: '73',
    iconOn: $r('app.media.ic_badge_73_on'),
    iconOff: $r('app.media.ic_badge_73_off')
  },
  {
    level: 99,
    name: '99',
    iconOn: $r('app.media.ic_badge_99_on'),
    iconOff: $r('app.media.ic_badge_99_off')
  }
]

export const TaskOverAchievementList: TaskOverAchievementItem[] = [
  { taskId: 1, percentage: 200, name: '200', iconOn: $r('app.media.ic_medal_200_on'), iconOff: $r('app.media.ic_medal_200_off') },
  { taskId: 1, percentage: 300, name: '300', iconOn: $r('app.media.ic_medal_300_on'), iconOff: $r('app.media.ic_medal_300_off') },
  { taskId: 1, percentage: 400, name: '400', iconOn: $r('app.media.ic_medal_400_on'), iconOff: $r('app.media.ic_medal_400_off') },
  { taskId: 2, percentage: 200, name: '200', iconOn: $r('app.media.ic_medal_200_on'), iconOff: $r('app.media.ic_medal_200_off') },
  { taskId: 2, percentage: 300, name: '300', iconOn: $r('app.media.ic_medal_300_on'), iconOff: $r('app.media.ic_medal_300_off') },
  { taskId: 2, percentage: 400, name: '400', iconOn: $r('app.media.ic_medal_400_on'), iconOff: $r('app.media.ic_medal_400_off') },
  { taskId: 3, percentage: 200, name: '200', iconOn: $r('app.media.ic_medal_200_on'), iconOff: $r('app.media.ic_medal_200_off') },
  { taskId: 3, percentage: 300, name: '300', iconOn: $r('app.media.ic_medal_300_on'), iconOff: $r('app.media.ic_medal_300_off') },
  { taskId: 3, percentage: 400, name: '400', iconOn: $r('app.media.ic_medal_400_on'), iconOff: $r('app.media.ic_medal_400_off') },
  { taskId: 4, percentage: 200, name: '200', iconOn: $r('app.media.ic_medal_200_on'), iconOff: $r('app.media.ic_medal_200_off') },
  { taskId: 4, percentage: 300, name: '300', iconOn: $r('app.media.ic_medal_300_on'), iconOff: $r('app.media.ic_medal_300_off') },
  { taskId: 4, percentage: 400, name: '400', iconOn: $r('app.media.ic_medal_400_on'), iconOff: $r('app.media.ic_medal_400_off') },
  { taskId: 6, percentage: 200, name: '200', iconOn: $r('app.media.ic_medal_200_on'), iconOff: $r('app.media.ic_medal_200_off') },
  { taskId: 6, percentage: 300, name: '300', iconOn: $r('app.media.ic_medal_300_on'), iconOff: $r('app.media.ic_medal_300_off') },
  { taskId: 6, percentage: 400, name: '400', iconOn: $r('app.media.ic_medal_400_on'), iconOff: $r('app.media.ic_medal_400_off') },
]

export function getAchievementDoneIndex(maxConsecutiveDays: number): number {
  for (let index = 0; index < AchievementList.length; index++) {
    if (AchievementList[index].level === maxConsecutiveDays) {
      return index;
    }
  }
  return -1;
}

export function getTaskOverAchievementDoneIndex(taskId: number, percentage: number): number {
  for (let index = 0; index < TaskOverAchievementList.length; index++) {
    const item = TaskOverAchievementList[index];
    if (item.taskId === taskId && item.percentage === percentage) {
      return index;
    }
  }
  return -1;
}
