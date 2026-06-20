import re

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/telex/service/GoTiengVietService.ets', 'r') as f:
    content = f.read()

# Replace the subscriber callback in onCreate:
new_subscriber = """    commonEventManager.createSubscriber(subscribeInfo, (err: Error, subscriber: commonEventManager.CommonEventSubscriber) => {
      if (err) {
        console.error('[GoTiengViet] create settings subscriber failed:', err.message);
        return;
      }

      this.settingsSubscriber = subscriber;
      commonEventManager.subscribe(subscriber, (subscribeErr: Error, data: commonEventManager.CommonEventData) => {
        if (subscribeErr) {
          console.error('[GoTiengViet] settings changed event error:', subscribeErr.message);
          return;
        }
        this.reloadKeyboardSettingsFromPayload(data);
      });
    });"""

content = re.sub(r'commonEventManager\.createSubscriber\(subscribeInfo,\s*\(err:\s*Error,\s*subscriber:\s*commonEventManager\.CommonEventSubscriber\)\s*=>\s*\{.*?\n\s+this\.settingsSubscriber = subscriber;\n\s+commonEventManager\.subscribe\(subscriber,\s*\(subscribeErr:\s*Error\)\s*=>\s*\{.*?\n\s+this\.reloadKeyboardSettingsFromApp\(\);\n\s+\}\);\n\s+\}\);', new_subscriber, content, flags=re.DOTALL)


# Replace registerSettingsChangedListener if any (since there are two!)
new_register = """  private async registerSettingsChangedListener(): Promise<void> {
    try {
      const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
        events: [GTV_SETTINGS_CHANGED_EVENT]
      };

      this.settingsSubscriber =
        await commonEventManager.createSubscriber(subscribeInfo);

      commonEventManager.subscribe(
        this.settingsSubscriber,
        async (err: Error, data: commonEventManager.CommonEventData) => {
          console.info('[GoTiengViet] settings changed in listener');
          this.reloadKeyboardSettingsFromPayload(data);
        }
      );
    } catch (err) {
      console.error('[GoTiengViet] registerSettingsChangedListener failed: '
        + JSON.stringify(err));
    }
  }"""

content = re.sub(r'private async registerSettingsChangedListener\(\):\s*Promise<void>\s*\{.*?\n\s+await this\.refreshPanelLayout\(\);\n\s+\}\n\s+\);\n\s+\}\s*catch\s*\(err\)\s*\{.*?\n\s+\}\n\s+\}', new_register, content, flags=re.DOTALL)

# Add the new function to parse payload
payload_func = """  private reloadKeyboardSettingsFromPayload(eventData: commonEventManager.CommonEventData): void {
    if (eventData && eventData.data) {
      try {
        let payload = JSON.parse(eventData.data);
        if (payload.backgroundOpacity !== undefined) { AppStorage.setOrCreate(GTV_BG_OPACITY_KEY, payload.backgroundOpacity); PreferencesManager.set(GTV_BG_OPACITY_KEY, payload.backgroundOpacity); }
        if (payload.keyOpacity !== undefined) { AppStorage.setOrCreate(GTV_KEY_OPACITY_KEY, payload.keyOpacity); PreferencesManager.set(GTV_KEY_OPACITY_KEY, payload.keyOpacity); }
        if (payload.bgBaseColor !== undefined) { AppStorage.setOrCreate(GTV_BG_COLOR_KEY, payload.bgBaseColor); PreferencesManager.set(GTV_BG_COLOR_KEY, payload.bgBaseColor); }
        if (payload.keyBaseColor !== undefined) { AppStorage.setOrCreate(GTV_KEY_COLOR_KEY, payload.keyBaseColor); PreferencesManager.set(GTV_KEY_COLOR_KEY, payload.keyBaseColor); }
        if (payload.textBaseColor !== undefined) { AppStorage.setOrCreate(GTV_TEXT_COLOR_KEY, payload.textBaseColor); PreferencesManager.set(GTV_TEXT_COLOR_KEY, payload.textBaseColor); }
        if (payload.darkMode !== undefined) { AppStorage.setOrCreate(GTV_DARK_MODE_KEY, payload.darkMode); PreferencesManager.set(GTV_DARK_MODE_KEY, payload.darkMode); }
        if (payload.keyboardWindowHeight !== undefined) { AppStorage.setOrCreate(GTV_KEYBOARD_HEIGHT_VP_KEY, payload.keyboardWindowHeight); PreferencesManager.set(GTV_KEYBOARD_HEIGHT_VP_KEY, payload.keyboardWindowHeight); }
        if (payload.fontWeightLevel !== undefined) { AppStorage.setOrCreate(GTV_KEY_SIZE_LABEL_KEY, payload.fontWeightLevel); PreferencesManager.set(GTV_KEY_SIZE_LABEL_KEY, payload.fontWeightLevel); }
        if (payload.sound !== undefined) { AppStorage.setOrCreate(GTV_SOUND_ENABLED_KEY, payload.sound); PreferencesManager.set(GTV_SOUND_ENABLED_KEY, payload.sound); }
        if (payload.vibration !== undefined) { AppStorage.setOrCreate(GTV_VIBRATION_ENABLED_KEY, payload.vibration); PreferencesManager.set(GTV_VIBRATION_ENABLED_KEY, payload.vibration); }
        if (payload.clipboardDailyStore !== undefined) { AppStorage.setOrCreate(GTV_CLIPBOARD_ENABLED_KEY, payload.clipboardDailyStore); PreferencesManager.set(GTV_CLIPBOARD_ENABLED_KEY, payload.clipboardDailyStore); }
        if (payload.numberRowEnabled !== undefined) { AppStorage.setOrCreate(GTV_SHOW_NUMBER_ROW_KEY, payload.numberRowEnabled); PreferencesManager.set(GTV_SHOW_NUMBER_ROW_KEY, payload.numberRowEnabled); }
        
        console.info('[GoTiengViet] Successfully synced settings from app payload');
        if (this.panel) {
          this.refreshPanelLayout().catch((err: Error) => {
            console.error('[GoTiengViet] refresh layout after payload failed:', err.message);
          });
        }
        return;
      } catch (e) {
        console.error('[GoTiengViet] Parse payload failed:', e);
      }
    }
    // Fallback if payload missing or unparseable
    this.reloadKeyboardSettingsFromApp();
  }

  private reloadKeyboardSettingsFromApp(): void {"""

content = content.replace("  private reloadKeyboardSettingsFromApp(): void {", payload_func)

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/telex/service/GoTiengVietService.ets', 'w') as f:
    f.write(content)
print("Done patching GoTiengVietService.ets")
