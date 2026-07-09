
import { CommonConstants as Const, taskBaseInfoList, TaskBaseInfo } from 'common';
import { AchievementStore } from '../viewmodel/AchievementStore';
import { openAchievementCustomDialog } from './dialog/AchievementDialog';
import { AchievementItem, AchievementList, TaskOverAchievementItem, TaskOverAchievementList } from '../model/AchievementModel';

@Builder
export function achBuilder() {
  AchievementComponent();
}

@Component
export struct AchievementComponent {
  @Consume achievementStore: AchievementStore;
  @Consume('pathStack') pageStack: NavPathStack;

  build() {
    NavDestination() {
      Column() {
        Row() {
          Image($r('app.media.ach_back'))
            .height($r('app.float.default_40'))
            .width($r('app.float.default_40'))
            .margin({
              right: $r('app.float.default_8')
            })
            .onClick(() => {
              this.pageStack.pop();
            })
          Text($r('app.string.my_achievement'))
            .fontFamily($r(Const.HARMONY_HEI_TI_MEDIUM))
            .fontWeight(FontWeight.Bold)
            .fontColor($r(`sys.color.font_on_primary`))
            .fontSize($r('app.float.default_20'))
            .width(Const.THOUSANDTH_1000)
            .height($r('app.float.default_56'))
        }
        .margin({
          left: $r('app.float.default_12'),
          right: $r('app.float.default_12')
        })

        Scroll() {
          Column() {
            Text($r('app.string.global_streak_title'))
              .fontFamily(Const.HARMONY_HEI_TI_BOLD)
              .fontWeight(FontWeight.Bold)
              .fontColor($r(`sys.color.font_on_primary`))
              .fontSize($r('app.float.default_16'))
              .width(Const.THOUSANDTH_1000)
              .margin({ top: $r('app.float.default_12'), bottom: $r('app.float.default_8') })

            Flex({
              direction: FlexDirection.Row,
              wrap: FlexWrap.Wrap
            }) {
              ForEach(AchievementList, (item: AchievementItem, index: number) => {
                this.globalAchievementBuilder(index, item)
              }, (item: AchievementItem, index: number) => index + JSON.stringify(item))
            }
            .width(Const.THOUSANDTH_1000)

            Text($r('app.string.over_achievement_title'))
              .fontFamily(Const.HARMONY_HEI_TI_BOLD)
              .fontWeight(FontWeight.Bold)
              .fontColor($r(`sys.color.font_on_primary`))
              .fontSize($r('app.float.default_16'))
              .width(Const.THOUSANDTH_1000)
              .margin({ top: $r('app.float.default_24'), bottom: $r('app.float.default_8') })

            ForEach(taskBaseInfoList, (taskInfo: TaskBaseInfo, taskIndex: number) => {
              if (taskInfo.step > 0) {
                Column() {
                  Text(taskInfo.name)
                    .fontFamily(Const.HARMONY_HEI_TI_MEDIUM)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r(`sys.color.font_on_primary`))
                    .fontSize($r('app.float.default_14'))
                    .width(Const.THOUSANDTH_1000)
                    .margin({ bottom: $r('app.float.default_4') })

                  Flex({
                    direction: FlexDirection.Row,
                    wrap: FlexWrap.Wrap
                  }) {
                    ForEach(TaskOverAchievementList.filter((item: TaskOverAchievementItem) => item.taskId === taskIndex),
                      (item: TaskOverAchievementItem, index: number) => {
                        this.taskOverAchievementBuilder(item, index)
                      }, (item: TaskOverAchievementItem, index: number) => `${item.taskId}_${item.percentage}`)
                  }
                  .width(Const.THOUSANDTH_1000)
                }
                .width(Const.THOUSANDTH_1000)
                .margin({ bottom: $r('app.float.default_12') })
              }
            }, (taskInfo: TaskBaseInfo, taskIndex: number) => String(taskIndex))
          }
          .width(Const.THOUSANDTH_1000)
        }
        .width(Const.THOUSANDTH_1000)
        .height(Const.THOUSANDTH_1000)
      }
      .width(Const.THOUSANDTH_1000)
      .height(Const.THOUSANDTH_1000)
      .backgroundColor($r('app.color.ach_bg_color'))
      .justifyContent(FlexAlign.Start)
      .padding({
        left: $r('app.float.default_10'),
        right: $r('app.float.default_10'),
        bottom: $r('app.float.default_10')
      })
    }
    .size({
      width: Const.THOUSANDTH_1000,
      height: Const.THOUSANDTH_1000
    })
    .backgroundColor($r('app.color.ach_bg_color'))
    .hideTitleBar(true)
    .padding({
      top: $r('app.float.default_40')
    })
  }

  @Builder
  globalAchievementBuilder(index: number, item: AchievementItem) {
    Column({
      space: $r('app.float.default_18')
    }) {
      Image(item.level <= this.achievementStore.maxConsecutiveDays ? item.iconOn : item.iconOff)
        .width(Const.THOUSANDTH_1000)
        .height($r('app.float.default_88'))
        .objectFit(ImageFit.Contain)

      Text($r('app.string.achievement_level', item.name))
        .lineHeight($r('app.float.default_16'))
        .fontSize($r('app.float.default_12'))
        .fontColor($r(`sys.color.font_on_primary`))
    }
    .width(Const.THOUSANDTH_333)
    .padding({
      top: $r('app.float.default_38'),
      bottom: $r('app.float.default_10')
    })
    .onClick(() => {
      if (item.level <= this.achievementStore.maxConsecutiveDays) {
        openAchievementCustomDialog(this.getUIContext(), index, 'global', -1);
      }
    })
  }

  @Builder
  taskOverAchievementBuilder(item: TaskOverAchievementItem, localIndex: number) {
    Column({
      space: $r('app.float.default_18')
    }) {
      Image(item.percentage <= this.achievementStore.taskOverAchievement[item.taskId] ? item.iconOn : item.iconOff)
        .width(Const.THOUSANDTH_1000)
        .height($r('app.float.default_88'))
        .objectFit(ImageFit.Contain)

      Text($r('app.string.over_achievement_level', item.name))
        .lineHeight($r('app.float.default_16'))
        .fontSize($r('app.float.default_12'))
        .fontColor($r(`sys.color.font_on_primary`))
    }
    .width(Const.THOUSANDTH_333)
    .padding({
      top: $r('app.float.default_38'),
      bottom: $r('app.float.default_10')
    })
    .onClick(() => {
      if (item.percentage <= this.achievementStore.taskOverAchievement[item.taskId]) {
        const globalIndex = getTaskOverGlobalIndex(item.taskId, item.percentage);
        openAchievementCustomDialog(this.getUIContext(), globalIndex, 'taskOverAchievement', item.taskId);
      }
    })
  }
}

function getTaskOverGlobalIndex(taskId: number, percentage: number): number {
  for (let i = 0; i < TaskOverAchievementList.length; i++) {
    if (TaskOverAchievementList[i].taskId === taskId && TaskOverAchievementList[i].percentage === percentage) {
      return i;
    }
  }
  return 0;
}
