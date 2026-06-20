import re

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/Index.ets', 'r') as f:
    content = f.read()

# Add imports
content = content.replace('GTV_KEY_COLOR_KEY,', 'GTV_KEY_COLOR_KEY, GTV_TEXT_COLOR_KEY, DEFAULT_KEYBOARD_TEXT_COLOR,')

# Add state
content = content.replace(
    '@State keyBaseColor: string = DEFAULT_KEYBOARD_KEY_COLOR;',
    '@State keyBaseColor: string = DEFAULT_KEYBOARD_KEY_COLOR;\n  @State textBaseColor: string = DEFAULT_KEYBOARD_TEXT_COLOR;'
)

# Add to loadSettings
content = content.replace(
    'this.keyBaseColor = await PreferencesManager.get(GTV_KEY_COLOR_KEY, DEFAULT_KEYBOARD_KEY_COLOR) as string;',
    'this.keyBaseColor = await PreferencesManager.get(GTV_KEY_COLOR_KEY, DEFAULT_KEYBOARD_KEY_COLOR) as string;\n    this.textBaseColor = await PreferencesManager.get(GTV_TEXT_COLOR_KEY, DEFAULT_KEYBOARD_TEXT_COLOR) as string;'
)

# Add text color picker
text_picker = """
        Text('Màu chữ phím').fontSize(14).fontColor(this.textPrimary).width('100%').padding({ left: 20, top: 8, bottom: 8 })
        Scroll() {
          Row() {
            ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
              Circle({ width: 36, height: 36 })
                .fill(color)
                .margin(6)
                .border({ width: this.textBaseColor === color ? 3 : 0, color: '#4FC3F7' })
                .onClick(() => {
                  this.textBaseColor = color;
                  this.saveSetting(GTV_TEXT_COLOR_KEY, color);
                  KeyboardBridge.sendThemeChanged();
                })
            })
          }.width('100%').padding({ left: 14, right: 14 })
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
"""

content = content.replace(
    "        this.buildSliderSetting('Độ trong suốt nền'",
    text_picker + "\n        this.buildSliderSetting('Độ trong suốt nền'"
)

# Add demo keyboard builder
demo_builder = """
  @Builder
  buildDemoKeyboard() {
    Column() {
      Row() {
        ForEach(['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'], (key: string) => {
          Text(key)
            .layoutWeight(1)
            .height(40)
            .margin(2)
            .backgroundColor(this.keyBaseColor)
            .fontColor(this.textBaseColor ? this.textBaseColor : this.getKeyTextColor(this.keyBaseColor))
            .fontSize(16)
            .textAlign(TextAlign.Center)
            .borderRadius(4)
        })
      }.width('100%').padding({ left: 2, right: 2 })
      
      Row() {
        ForEach(['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'], (key: string) => {
          Text(key)
            .layoutWeight(1)
            .height(40)
            .margin(2)
            .backgroundColor(this.keyBaseColor)
            .fontColor(this.textBaseColor ? this.textBaseColor : this.getKeyTextColor(this.keyBaseColor))
            .fontSize(16)
            .textAlign(TextAlign.Center)
            .borderRadius(4)
        })
      }.width('90%').padding({ left: 2, right: 2 })
      
      Row() {
        Text('⇧')
          .width(45)
          .height(40)
          .margin(2)
          .backgroundColor(this.darkMode ? '#3D3D3D' : '#B0B4C0')
          .fontColor(this.darkMode ? '#FFFFFF' : '#000000')
          .fontSize(16)
          .textAlign(TextAlign.Center)
          .borderRadius(4)
          
        ForEach(['Z', 'X', 'C', 'V', 'B', 'N', 'M'], (key: string) => {
          Text(key)
            .layoutWeight(1)
            .height(40)
            .margin(2)
            .backgroundColor(this.keyBaseColor)
            .fontColor(this.textBaseColor ? this.textBaseColor : this.getKeyTextColor(this.keyBaseColor))
            .fontSize(16)
            .textAlign(TextAlign.Center)
            .borderRadius(4)
        })
        
        Text('⌫')
          .width(45)
          .height(40)
          .margin(2)
          .backgroundColor(this.darkMode ? '#3D3D3D' : '#B0B4C0')
          .fontColor(this.darkMode ? '#FFFFFF' : '#000000')
          .fontSize(16)
          .textAlign(TextAlign.Center)
          .borderRadius(4)
      }.width('100%').padding({ left: 2, right: 2 })
      
      Row() {
        Text('?123')
          .layoutWeight(1)
          .height(40)
          .margin(2)
          .backgroundColor(this.darkMode ? '#3D3D3D' : '#B0B4C0')
          .fontColor(this.darkMode ? '#FFFFFF' : '#000000')
          .fontSize(14)
          .textAlign(TextAlign.Center)
          .borderRadius(4)
          
        Text('GoTiengViet')
          .layoutWeight(4)
          .height(40)
          .margin(2)
          .backgroundColor(this.keyBaseColor)
          .fontColor(this.textBaseColor ? this.textBaseColor : this.getKeyTextColor(this.keyBaseColor))
          .fontSize(14)
          .textAlign(TextAlign.Center)
          .borderRadius(4)
          
        Text('⏎')
          .layoutWeight(1)
          .height(40)
          .margin(2)
          .backgroundColor('#4A90D9')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .textAlign(TextAlign.Center)
          .borderRadius(4)
      }.width('100%').padding({ left: 2, right: 2 })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .backgroundColor(this.bgBaseColor)
    .borderRadius(8)
    .margin({ top: 10, bottom: 10 })
    .opacity(this.backgroundOpacity / 100)
  }
"""

content = content.replace("  @Builder\n  buildMainSettings() {", demo_builder + "\n  @Builder\n  buildMainSettings() {")

# Add the call to buildDemoKeyboard inside buildMainSettings
content = content.replace(
    "this.buildSectionTitle('Giao diện (Theme)')\n      Column() {",
    "this.buildSectionTitle('Giao diện (Theme)')\n      Column() {\n        this.buildDemoKeyboard()"
)

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/Index.ets', 'w') as f:
    f.write(content)

print("Done patching Index.ets")
