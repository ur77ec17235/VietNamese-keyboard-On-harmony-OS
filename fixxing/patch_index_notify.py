import re

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/Index.ets', 'r') as f:
    content = f.read()

old_notify = """  private notifyKeyboardSettingsChanged(): void {
    commonEventManager.publish(GTV_SETTINGS_CHANGED_EVENT, {
      data: String(Date.now())
    }, () =>{});
  }"""

new_notify = """  private notifyKeyboardSettingsChanged(): void {
    let payload = JSON.stringify({
      backgroundOpacity: this.backgroundOpacity,
      keyOpacity: this.keyOpacity,
      bgBaseColor: this.bgBaseColor,
      keyBaseColor: this.keyBaseColor,
      textBaseColor: this.textBaseColor,
      darkMode: this.darkMode,
      keyboardWindowHeight: this.keyboardWindowHeight,
      fontWeightLevel: this.fontWeightLevel,
      sound: this.sound,
      vibration: this.vibration,
      clipboardDailyStore: this.clipboardDailyStore,
      numberRowEnabled: this.numberRowEnabled
    });

    commonEventManager.publish(GTV_SETTINGS_CHANGED_EVENT, {
      data: payload
    }, () =>{});
  }"""

content = content.replace(old_notify, new_notify)

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/Index.ets', 'w') as f:
    f.write(content)
print("Done patching notifyKeyboardSettingsChanged")
