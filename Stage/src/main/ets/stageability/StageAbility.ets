/**
 * StageAbility.ets
 * UIAbility chính - mở Settings page khi người dùng khởi động app
 */

import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';

export default class StageAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('[GoTiengViet] StageAbility onCreate');
  }

  onDestroy(): void {
    console.info('[GoTiengViet] StageAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    console.info('[GoTiengViet] StageAbility onWindowStageCreate');

    // Thiết lập status bar trong suốt
    windowStage.getMainWindow().then((win) => {
      win.setWindowSystemBarEnable(['status']).catch((err: Error) => {
        console.warn('setWindowSystemBarEnable:', err);
      });
    }).catch((err: Error) => {
      console.warn('getMainWindow:', err);
    });

    // Load settings page
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        console.error('[GoTiengViet] loadContent failed:', JSON.stringify(err));
        return;
      }
      console.info('[GoTiengViet] loadContent success');
    });
  }

  onWindowStageDestroy(): void {
    console.info('[GoTiengViet] StageAbility onWindowStageDestroy');
  }

  onForeground(): void {
    console.info('[GoTiengViet] StageAbility onForeground');
  }

  onBackground(): void {
    console.info('[GoTiengViet] StageAbility onBackground');
  }
}