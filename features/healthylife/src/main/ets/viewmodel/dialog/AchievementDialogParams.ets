
export class AchievementDialogParams {
  uiContext?: UIContext;
  index: number = 3;
  medalType: string = 'global';
  taskId: number = -1;
  opacityValue: number = 0;
  angle: number = 0;
  scaleValue: number = 0;
  autoClose: boolean = false;

  constructor(uiContext: UIContext, index: number, medalType: string, taskId: number,
    opacityValue: number, angle: number, scaleValue: number, autoClose: boolean = false) {
    this.uiContext = uiContext;
    this.index = index;
    this.medalType = medalType;
    this.taskId = taskId;
    this.opacityValue = opacityValue;
    this.angle = angle;
    this.scaleValue = scaleValue;
    this.autoClose = autoClose;
  }
}
