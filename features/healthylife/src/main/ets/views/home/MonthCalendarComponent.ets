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

import { CommonConstants as Const, convertDate2Str, convertStr2Date, DayInfo, DayTaskInfo, taskBaseInfoList } from 'common';
import DayInfoApi from 'common/src/main/ets/database/tables/DayInfoApi';
import DayTaskInfoApi from 'common/src/main/ets/database/tables/DayTaskInfoApi';

class MonthDayInfo {
  date: string;
  day: number;
  inCurrentMonth: boolean;
  dayInfo: DayInfo;
  taskList: DayTaskInfo[];

  constructor(date: string, day: number, inCurrentMonth: boolean, dayInfo: DayInfo, taskList: DayTaskInfo[]) {
    this.date = date;
    this.day = day;
    this.inCurrentMonth = inCurrentMonth;
    this.dayInfo = dayInfo;
    this.taskList = taskList;
  }
}

@Builder
export function monthCalendarBuilder(_name: string, param: string) {
  MonthCalendarComponent({ currentDate: param });
}

@Component
export struct MonthCalendarComponent {
  @Consume('pathStack') pageStack: NavPathStack;
  @State currentDate: string = '';
  @State monthTitle: string = '';
  @State monthDays: MonthDayInfo[] = [];
  @State flag: boolean = false;
  private rowIndexList: number[] = [0, 1, 2, 3, 4, 5];
  private dayIndexList: number[] = [0, 1, 2, 3, 4, 5, 6];

  async aboutToAppear(): Promise<void> {
    await this.refreshMonthDays();
    this.flag = true;
  }

  private async refreshMonthDays(): Promise<void> {
    const selectedDate = convertStr2Date(this.currentDate);
    const year = selectedDate.getFullYear();
    const month = selectedDate.getMonth();
    this.monthTitle = `${year}年${month + 1}月`;

    const firstDayOfMonth = new Date(year, month, 1);
    const dayOfWeek = firstDayOfMonth.getDay();
    const mondayOffset = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
    const firstCellDate = new Date(firstDayOfMonth);
    firstCellDate.setDate(firstDayOfMonth.getDate() - mondayOffset);

    let monthDays: MonthDayInfo[] = [];
    for (let index = 0; index < Const.WEEK_DAY_NUM * 6; index++) {
      const cellDate = new Date(firstCellDate);
      cellDate.setDate(firstCellDate.getDate() + index);
      const dateStr = convertDate2Str(cellDate);
      let dayInfo = await DayInfoApi.queryByKey(dateStr);
      if (dayInfo === null) {
        dayInfo = new DayInfo(dateStr, 0, 0);
      }
      const taskList = await DayTaskInfoApi.queryDayTaskInfo(dateStr);
      monthDays.push(new MonthDayInfo(dateStr, cellDate.getDate(), cellDate.getMonth() === month, dayInfo, taskList));
    }
    this.monthDays = monthDays;
  }

  build() {
    NavDestination() {
      if (this.flag) {
        Column() {
          Row() {
            Text($r('app.string.cancel'))
              .fontColor($r('app.color.text_font_color'))
              .fontSize($r('app.float.default_18'))
              .onClick(() => {
                this.pageStack.pop();
              })

            Blank()

            Text(this.monthTitle)
              .fontFamily(Const.HARMONY_HEI_TI_MEDIUM)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
              .fontSize($r('app.float.default_20'))

            Blank()
          }
          .height($r('app.float.default_56'))
          .width(Const.THOUSANDTH_940)
          .padding({
            left: $r('app.float.default_12'),
            right: $r('app.float.default_12')
          })

          Row() {
            ForEach(Const.WEEK_SHORTHAND_LIST, (item: Resource) => {
              Text(item)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('app.float.default_12'))
                .textAlign(TextAlign.Center)
                .width(Const.PERCENTAGE_100_EXCEPT_7)
            }, (item: Resource, index: number) => `${index}`)
          }
          .width(Const.THOUSANDTH_940)
          .height($r('app.float.default_32'))

          Column() {
            ForEach(this.rowIndexList, (rowIndex: number) => {
              Row() {
                ForEach(this.dayIndexList, (dayIndex: number) => {
                  this.monthDayBuilder(this.monthDays[rowIndex * Const.WEEK_DAY_NUM + dayIndex])
                }, (dayIndex: number) => `${rowIndex}_${dayIndex}`)
              }
              .width(Const.THOUSANDTH_940)
              .height($r('app.float.default_88'))
            }, (rowIndex: number) => `${rowIndex}`)
          }
          .width(Const.THOUSANDTH_940)
          .backgroundColor($r('sys.color.background_primary'))
          .borderRadius($r('app.float.default_16'))
          .padding({
            top: $r('app.float.default_8'),
            bottom: $r('app.float.default_8')
          })
        }
        .width(Const.THOUSANDTH_1000)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .size({
      width: Const.THOUSANDTH_1000,
      height: Const.THOUSANDTH_1000
    })
    .hideTitleBar(true)
    .padding({
      top: $r('app.float.default_40')
    })
    .backgroundColor($r('sys.color.background_secondary'))
  }

  @Builder
  monthDayBuilder(item: MonthDayInfo) {
    Column() {
      Text(`${item.day}`)
        .fontSize($r('app.float.default_14'))
        .fontColor(item.inCurrentMonth ? $r('sys.color.font_primary') : $r('sys.color.font_tertiary'))
        .fontWeight(FontWeight.Medium)

      Image(item.dayInfo.getProgressImg())
        .height($r('app.float.default_14'))
        .objectFit(ImageFit.Contain)
        .opacity(item.inCurrentMonth ? Const.ANIMATE_OPACITY_1 : 0.4)

      this.taskProgressBars(item.taskList)
    }
    .width(Const.PERCENTAGE_100_EXCEPT_7)
    .height(Const.THOUSANDTH_1000)
    .justifyContent(FlexAlign.SpaceAround)
    .opacity(item.inCurrentMonth ? Const.ANIMATE_OPACITY_1 : 0.45)
  }

  @Builder
  taskProgressBars(taskList: DayTaskInfo[]) {
    Column({ space: $r('app.float.default_1') }) {
      ForEach(taskList, (item: DayTaskInfo, index: number) => {
        Stack({ alignContent: Alignment.Start }) {
          Row()
            .width($r('app.float.default_24'))
            .height($r('app.float.default_2'))
            .borderRadius($r('app.float.default_2'))
            .backgroundColor($r('sys.color.background_tertiary'))

          Row()
            .width(`${this.calculateTaskProgress(item)}%`)
            .height($r('app.float.default_2'))
            .borderRadius($r('app.float.default_2'))
            .backgroundColor(this.getTaskProgressColor(index))
        }
        .width($r('app.float.default_24'))
        .height($r('app.float.default_2'))
      }, (item: DayTaskInfo, index: number) => `${item.date}_${item.taskId}_${index}`)
    }
    .height($r('app.float.default_22'))
    .justifyContent(FlexAlign.Center)
  }

  private calculateTaskProgress(item: DayTaskInfo): number {
    if (item.isDone) {
      return Const.DEFAULT_100;
    }
    const step = taskBaseInfoList[item.taskId].step;
    if (step === 0) {
      return Const.DEFAULT_0;
    }
    const targetValue = Number(item.targetValue);
    const finValue = Number(item.finValue || '0');
    if (targetValue <= 0 || finValue <= 0) {
      return Const.DEFAULT_0;
    }
    return Math.min(Const.DEFAULT_100, Math.ceil(finValue / targetValue * Const.DEFAULT_100));
  }

  private getTaskProgressColor(index: number): string {
    const colorList: string[] = ['#0A59F7', '#00A870', '#FFB000', '#E84026', '#7A5AF8', '#00A3A3', '#D948AE'];
    return colorList[index % colorList.length];
  }
}
