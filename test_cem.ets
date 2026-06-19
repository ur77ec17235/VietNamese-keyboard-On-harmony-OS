import commonEventManager from '@ohos.commonEventManager';

export class EventManager {
  static publishThemeChange() {
    commonEventManager.publish('com.example.gotiengviet.THEME_CHANGED', (err) => {
      if (err) {
        console.error('Publish error', err);
      }
    });
  }
}
