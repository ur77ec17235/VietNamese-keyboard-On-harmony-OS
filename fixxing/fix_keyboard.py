import re

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/KeyboardPage.ets', 'r') as f:
    content = f.read()

# Fix 1: Error 6,7
content = content.replace(
    'const keyColor = await PreferencesManager.get(GTV_KEY_COLOR_KEY, GTV_TEXT_COLOR_KEY, DEFAULT_KEYBOARD_TEXT_COLOR, DEFAULT_KEYBOARD_KEY_COLOR) as string;',
    'const keyColor = await PreferencesManager.get(GTV_KEY_COLOR_KEY, DEFAULT_KEYBOARD_KEY_COLOR) as string;'
)

content = content.replace(
    'AppStorage.setOrCreate(GTV_KEY_COLOR_KEY, GTV_TEXT_COLOR_KEY, DEFAULT_KEYBOARD_TEXT_COLOR, keyColor);',
    'AppStorage.setOrCreate(GTV_KEY_COLOR_KEY, keyColor);'
)

# Fix 2: Error 8
content = content.replace(
    'this.saveThemeSetting(GTV_KEY_COLOR_KEY, GTV_TEXT_COLOR_KEY, DEFAULT_KEYBOARD_TEXT_COLOR, color);',
    'this.saveThemeSetting(GTV_KEY_COLOR_KEY, color);'
)

# Fix 3: Error 9
content = content.replace(
    'this.saveSetting(GTV_TEXT_COLOR_KEY, color);',
    'this.saveThemeSetting(GTV_TEXT_COLOR_KEY, color);'
)

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/KeyboardPage.ets', 'w') as f:
    f.write(content)

print("Done fixing keyboard page")
