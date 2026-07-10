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

import { HomeComponent } from '../views/HomeComponent';
import { MineComponent } from '../views/MineComponent';
import { NavList, TabId } from '../model/NavItemModel';
import {
  AgentUtils,
  CommonConstants as Const,
  convertDate2Str,
  convertStr2Date,
  taskBaseInfoList
} from 'common';
import DayInfoApi from 'common/src/main/ets/database/tables/DayInfoApi';
import DayTaskInfoApi from 'common/src/main/ets/database/tables/DayTaskInfoApi';
import TaskInfoApi from 'common/src/main/ets/database/tables/TaskInfoApi';
import { AchievementStore, initAchievementStore } from '../viewmodel/AchievementStore';
import { HomeStore, initCurrentDateInfo } from '../viewmodel/HomeStore';
import { common } from '@kit.AbilityKit';
import { initUserProfileStore, UserProfileStore } from '../viewmodel/UserProfileStore';

@Component
export struct HealthyLifePage {
  @State currentIndex: number = 0;
  @StorageLink(Const.FOREGROUND_DATE) @Watch('onForegroundDateChange') foregroundDate: string = '';
  @Provide achievementStore: AchievementStore = new AchievementStore(0, 0, false, new Array<number>(7).fill(0));
  @Provide userProfileStore: UserProfileStore = new UserProfileStore();
  @Provide('pathStack') pageStack: NavPathStack = new NavPathStack();
  @Provide homeStore: HomeStore = new HomeStore([], -1, '', []);
  private context = this.getUIContext()?.getHostContext() as common.UIAbilityContext;
  private windowClass = this.context.windowStage.getMainWindowSync();
  private refreshingDate: boolean = false;

  onForegroundDateChange(): void {
    this.refreshCurrentDay(this.foregroundDate);
  }

  private async refreshCurrentDay(date: string): Promise<void> {
    if (!date || this.refreshingDate || this.homeStore.currentDate === date) {
      return;
    }
    this.refreshingDate = true;
    try {
      await DayInfoApi.initAchievementStoreByDayInfo(date);
      await DayInfoApi.initDayInfo(date);
      await this.reconcileReminderAgents(date);
      this.homeStore = await initCurrentDateInfo(convertStr2Date(date));
      this.achievementStore = await initAchievementStore();
    } finally {
      this.refreshingDate = false;
    }
  }

  private async reconcileReminderAgents(date: string): Promise<void> {
    let taskList = await TaskInfoApi.queryAllTaskInfo();
    for (let taskInfo of taskList) {
      let taskBaseInfo = taskBaseInfoList[taskInfo.taskId];
      if (!taskBaseInfo.supportReminder) {
        continue;
      }
      let oldReminderId = taskInfo.reminderId;
      if (oldReminderId !== -1) {
        if (!await AgentUtils.deleteAgent(oldReminderId)) {
          continue;
        }
        taskInfo.reminderId = -1;
      }
      let dayTaskKey = await DayTaskInfoApi.queryKeyByDateAndTaskId(date, taskInfo.taskId);
      if (taskInfo.isOpen && dayTaskKey !== -1 && AgentUtils.shouldScheduleReminder(taskInfo, date)) {
        taskInfo.reminderId = await AgentUtils.creatAgent(taskInfo, taskBaseInfo, date, this.getUIContext());
      }
      if (oldReminderId !== taskInfo.reminderId) {
        await TaskInfoApi.update(taskInfo.taskId, taskInfo);
      }
    }
  }

  async aboutToAppear(): Promise<void> {
    try {
      await this.windowClass.setWindowLayoutFullScreen(true);
      await this.windowClass.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: '#FF000000'
      })
    } catch (error) {
      console.error(`an error occurred: ${error}`);
    }
    await this.refreshCurrentDay(convertDate2Str(new Date()));
    this.userProfileStore = await initUserProfileStore();
  }

  onPageShow(): void {
    let today = convertDate2Str(new Date());
    if (today !== this.homeStore.currentDate && !this.refreshingDate) {
      this.foregroundDate = today;
    }
  }

  build() {
    Navigation(this.pageStack) {
      Tabs({ barPosition: BarPosition.End }) {
        TabContent() {
          HomeComponent()
        }
        .tabBar(this.tabBuilder(TabId.HOME))

        TabContent() {
          MineComponent()
        }
        .tabBar(this.tabBuilder(TabId.MINE))
      }
      .backgroundColor($r('sys.color.background_secondary'))
      .scrollable(false)
      .width(Const.THOUSANDTH_1000)
      .height(Const.THOUSANDTH_1000)
      .barWidth(Const.THOUSANDTH_940)
      .vertical(false)
      .padding({
        bottom: $r('app.float.default_20')
      })
      .divider({
        strokeWidth: 1,
        color: $r('sys.color.background_tertiary')
      })
      .onChange((index) => {
        this.currentIndex = index;
      })
    }
    .mode(NavigationMode.Stack)
  }

  @Builder
  tabBuilder(index: number) {
    Column() {
      Image(index === this.currentIndex ? NavList[index].icon_selected : NavList[index].icon)
        .width($r('app.float.default_24'))
        .height($r('app.float.default_24'))
        .objectFit(ImageFit.Contain);

      Text(NavList[index].text)
        .fontSize($r('app.float.default_10'))
        .fontWeight(FontWeight.Regular)
        .fontColor(this.currentIndex === index ? $r('app.color.text_font_color') : $r('sys.color.font_tertiary'))
        .margin({
          top: $r('app.float.default_4')
        })
    }
    .justifyContent(FlexAlign.Center)
    .width(Const.THOUSANDTH_1000)
    .height(Const.THOUSANDTH_1000)
  }
}
