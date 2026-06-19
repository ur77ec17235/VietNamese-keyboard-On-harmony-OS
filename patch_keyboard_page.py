import re

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/KeyboardPage.ets', 'r') as f:
    content = f.read()

# Add import
content = content.replace('GTV_KEY_COLOR_KEY,', 'GTV_KEY_COLOR_KEY, GTV_TEXT_COLOR_KEY, DEFAULT_KEYBOARD_TEXT_COLOR,')

# Add storage link
content = content.replace(
    '@StorageLink(GTV_KEY_COLOR_KEY) keyBase: string = DEFAULT_KEYBOARD_KEY_COLOR;',
    '@StorageLink(GTV_KEY_COLOR_KEY) keyBase: string = DEFAULT_KEYBOARD_KEY_COLOR;\n  @StorageLink(GTV_TEXT_COLOR_KEY) textBase: string = DEFAULT_KEYBOARD_TEXT_COLOR;'
)

# Pass to getVirtualKeyboardTheme
content = content.replace(
    'return getVirtualKeyboardTheme(this.bgBase, this.keyBase, this.darkMode);',
    'return getVirtualKeyboardTheme(this.bgBase, this.keyBase, this.darkMode, this.textBase);'
)

# Add text color picker to Theme panel
theme_picker_addition = """
        Text('Màu chữ phím').fontSize(14).fontColor(this.textPrimary).width('100%').padding({ left: 20, top: 8, bottom: 8 })
        Scroll() {
          Row() {
            ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
              Circle({ width: 36, height: 36 })
                .fill(color)
                .margin(6)
                .border({ width: this.textBase === color ? 3 : 0, color: '#4FC3F7' })
                .onClick(() => {
                  this.textBase = color;
                  this.saveSetting(GTV_TEXT_COLOR_KEY, color);
                })
            })
          }.width('100%').padding({ left: 14, right: 14 })
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
"""

# Insert after key color picker in KeyboardPage.ets
insert_pos = content.find("this.buildSliderSetting('Độ trong suốt nền'")
if insert_pos != -1:
    content = content[:insert_pos] + theme_picker_addition + content[insert_pos:]

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/KeyboardPage.ets', 'w') as f:
    f.write(content)

print("Done patching keyboard page")
