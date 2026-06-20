import re

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/telex/service/GoTiengVietService.ets', 'r') as f:
    content = f.read()

old_payload = """        let payload = JSON.parse(eventData.data);
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
        if (payload.numberRowEnabled !== undefined) { AppStorage.setOrCreate(GTV_SHOW_NUMBER_ROW_KEY, payload.numberRowEnabled); PreferencesManager.set(GTV_SHOW_NUMBER_ROW_KEY, payload.numberRowEnabled); }"""

new_payload = """        let payload = JSON.parse(eventData.data) as Record<string, Object>;
        if (payload['backgroundOpacity'] !== undefined) { AppStorage.setOrCreate(GTV_BG_OPACITY_KEY, payload['backgroundOpacity'] as number); PreferencesManager.set(GTV_BG_OPACITY_KEY, payload['backgroundOpacity'] as number); }
        if (payload['keyOpacity'] !== undefined) { AppStorage.setOrCreate(GTV_KEY_OPACITY_KEY, payload['keyOpacity'] as number); PreferencesManager.set(GTV_KEY_OPACITY_KEY, payload['keyOpacity'] as number); }
        if (payload['bgBaseColor'] !== undefined) { AppStorage.setOrCreate(GTV_BG_COLOR_KEY, payload['bgBaseColor'] as string); PreferencesManager.set(GTV_BG_COLOR_KEY, payload['bgBaseColor'] as string); }
        if (payload['keyBaseColor'] !== undefined) { AppStorage.setOrCreate(GTV_KEY_COLOR_KEY, payload['keyBaseColor'] as string); PreferencesManager.set(GTV_KEY_COLOR_KEY, payload['keyBaseColor'] as string); }
        if (payload['textBaseColor'] !== undefined) { AppStorage.setOrCreate(GTV_TEXT_COLOR_KEY, payload['textBaseColor'] as string); PreferencesManager.set(GTV_TEXT_COLOR_KEY, payload['textBaseColor'] as string); }
        if (payload['darkMode'] !== undefined) { AppStorage.setOrCreate(GTV_DARK_MODE_KEY, payload['darkMode'] as boolean); PreferencesManager.set(GTV_DARK_MODE_KEY, payload['darkMode'] as boolean); }
        if (payload['keyboardWindowHeight'] !== undefined) { AppStorage.setOrCreate(GTV_KEYBOARD_HEIGHT_VP_KEY, payload['keyboardWindowHeight'] as number); PreferencesManager.set(GTV_KEYBOARD_HEIGHT_VP_KEY, payload['keyboardWindowHeight'] as number); }
        if (payload['fontWeightLevel'] !== undefined) { AppStorage.setOrCreate(GTV_KEY_SIZE_LABEL_KEY, payload['fontWeightLevel'] as string); PreferencesManager.set(GTV_KEY_SIZE_LABEL_KEY, payload['fontWeightLevel'] as string); }
        if (payload['sound'] !== undefined) { AppStorage.setOrCreate(GTV_SOUND_ENABLED_KEY, payload['sound'] as boolean); PreferencesManager.set(GTV_SOUND_ENABLED_KEY, payload['sound'] as boolean); }
        if (payload['vibration'] !== undefined) { AppStorage.setOrCreate(GTV_VIBRATION_ENABLED_KEY, payload['vibration'] as boolean); PreferencesManager.set(GTV_VIBRATION_ENABLED_KEY, payload['vibration'] as boolean); }
        if (payload['clipboardDailyStore'] !== undefined) { AppStorage.setOrCreate(GTV_CLIPBOARD_ENABLED_KEY, payload['clipboardDailyStore'] as boolean); PreferencesManager.set(GTV_CLIPBOARD_ENABLED_KEY, payload['clipboardDailyStore'] as boolean); }
        if (payload['numberRowEnabled'] !== undefined) { AppStorage.setOrCreate(GTV_SHOW_NUMBER_ROW_KEY, payload['numberRowEnabled'] as boolean); PreferencesManager.set(GTV_SHOW_NUMBER_ROW_KEY, payload['numberRowEnabled'] as boolean); }"""

content = content.replace(old_payload, new_payload)

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/telex/service/GoTiengVietService.ets', 'w') as f:
    f.write(content)
print("Done fixing ArkTS any type error")
