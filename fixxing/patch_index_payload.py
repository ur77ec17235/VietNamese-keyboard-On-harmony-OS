import re

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/Index.ets', 'r') as f:
    content = f.read()

# Replace the save logic to also broadcast JSON
new_save_logic = """          .onClick(async () => {
            await this.saveSetting(GTV_BG_OPACITY_KEY, this.backgroundOpacity);
            await this.saveSetting(GTV_KEY_OPACITY_KEY, this.keyOpacity);
            await this.saveSetting(GTV_BG_COLOR_KEY, this.bgBaseColor);
            await this.saveSetting(GTV_KEY_COLOR_KEY, this.keyBaseColor);
            await this.saveSetting(GTV_TEXT_COLOR_KEY, this.textBaseColor);
            await this.saveSetting(GTV_DARK_MODE_KEY, this.darkMode);
            await this.saveSetting(GTV_SOUND_ENABLED_KEY, this.sound);
            await this.saveSetting(GTV_VIBRATION_ENABLED_KEY, this.vibration);
            await this.saveSetting(GTV_CLIPBOARD_ENABLED_KEY, this.clipboardDailyStore);
            await this.saveSetting(GTV_SUGGESTION_ENABLED_KEY, this.textSuggestion);
            
            KeyboardBridge.sendThemeChanged();
            
            let payload = JSON.stringify({
              bgOpacity: this.backgroundOpacity,
              keyOpacity: this.keyOpacity,
              bgColor: this.bgBaseColor,
              keyColor: this.keyBaseColor,
              textColor: this.textBaseColor,
              darkMode: this.darkMode,
              soundEnabled: this.sound,
              vibrationEnabled: this.vibration,
              clipboardEnabled: this.clipboardDailyStore,
              suggestionEnabled: this.textSuggestion
            });
            
            import('@ohos.commonEventManager').then((commonEventManager) => {
              commonEventManager.default.publish('com.example.gotiengviet.THEME_CHANGED', { data: payload }, (err) => {
                if (err) {
                  console.error('Publish THEME_CHANGED error', err);
                } else {
                  console.info('Publish THEME_CHANGED success with payload');
                }
              });
            });
          })"""

content = re.sub(r'\.onClick\(async \(\) => \{.*?\n\s+KeyboardBridge.sendThemeChanged\(\);\s+// Publish event cho GoTiengVietService.*?\}\)\;\s+\}\);\s+\}\)', new_save_logic, content, flags=re.DOTALL)

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/Index.ets', 'w') as f:
    f.write(content)
print("Done patching Index.ets payload")
