import re

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/telex/service/GoTiengVietService.ets', 'r') as f:
    content = f.read()

# Add import
content = content.replace('GTV_KEY_COLOR_KEY,', 'GTV_KEY_COLOR_KEY, GTV_TEXT_COLOR_KEY, DEFAULT_KEYBOARD_TEXT_COLOR,')

# Add to loadAppearanceSettings
content = content.replace(
    'const keyColor = await PreferencesManager.get(GTV_KEY_COLOR_KEY, DEFAULT_KEYBOARD_KEY_COLOR) as string;',
    'const keyColor = await PreferencesManager.get(GTV_KEY_COLOR_KEY, DEFAULT_KEYBOARD_KEY_COLOR) as string;\n    const textColor = await PreferencesManager.get(GTV_TEXT_COLOR_KEY, DEFAULT_KEYBOARD_TEXT_COLOR) as string;'
)

content = content.replace(
    'AppStorage.setOrCreate(GTV_KEY_COLOR_KEY, keyColor);',
    'AppStorage.setOrCreate(GTV_KEY_COLOR_KEY, keyColor);\n    AppStorage.setOrCreate(GTV_TEXT_COLOR_KEY, textColor);'
)

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/telex/service/GoTiengVietService.ets', 'w') as f:
    f.write(content)

print("Done patching service")
