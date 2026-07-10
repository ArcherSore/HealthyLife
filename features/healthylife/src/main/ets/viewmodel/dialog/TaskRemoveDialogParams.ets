/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

export class TaskRemoveDialogParams {
  taskName: Resource;
  isDone: boolean;
  canStopRepeat: boolean;
  onSkip: () => void;
  onStop: () => void;

  constructor(taskName: Resource, isDone: boolean, canStopRepeat: boolean, onSkip: () => void,
    onStop: () => void) {
    this.taskName = taskName;
    this.isDone = isDone;
    this.canStopRepeat = canStopRepeat;
    this.onSkip = onSkip;
    this.onStop = onStop;
  }
}
