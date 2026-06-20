import re

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/Index.ets', 'r') as f:
    content = f.read()

# Replace buildMainSettings to buildVoiceSettings
# Search for the start of buildMainSettings
start_idx = content.find('  @Builder\n  buildMainSettings() {')
end_idx = content.find('  @Builder\n  buildSliderSetting(')

if start_idx == -1 or end_idx == -1:
    print("Could not find blocks")
    exit(1)

new_content = """  @Builder
  buildMainSettings() {
    Column() {
      this.buildSectionTitle('Giao diện (Theme)')
      Column() {
        this.buildToggleRow('Chế độ Tối / Sáng', '◐', this.darkMode, (val: boolean) => {
          this.darkMode = val;
          this.saveSetting(GTV_DARK_MODE_KEY, val);
          KeyboardBridge.sendThemeChanged();
        })
        
        Text('Màu nền').fontSize(14).fontColor(this.textPrimary).width('100%').padding({ left: 20, top: 8, bottom: 8 })
        Scroll() {
          Row() {
            ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
              Circle({ width: 36, height: 36 })
                .fill(color)
                .margin(6)
                .border({ width: this.bgBaseColor === color ? 3 : 0, color: '#4FC3F7' })
                .onClick(() => {
                  this.bgBaseColor = color;
                  this.saveSetting(GTV_BG_COLOR_KEY, color);
                  KeyboardBridge.sendThemeChanged();
                })
            })
          }.width('100%').padding({ left: 14, right: 14 })
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)

        Text('Màu phím').fontSize(14).fontColor(this.textPrimary).width('100%').padding({ left: 20, top: 8, bottom: 8 })
        Scroll() {
          Row() {
            ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
              Circle({ width: 36, height: 36 })
                .fill(color)
                .margin(6)
                .border({ width: this.keyBaseColor === color ? 3 : 0, color: '#4FC3F7' })
                .onClick(() => {
                  this.keyBaseColor = color;
                  this.saveSetting(GTV_KEY_COLOR_KEY, color);
                  KeyboardBridge.sendThemeChanged();
                })
            })
          }.width('100%').padding({ left: 14, right: 14 })
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)

        this.buildSliderSetting('Độ trong suốt nền', `${this.backgroundOpacity}%`, this.backgroundOpacity, 10, 100, 1, (value: number) => {
          this.backgroundOpacity = Math.round(value);
          this.saveSetting(GTV_BG_OPACITY_KEY, this.backgroundOpacity);
          KeyboardBridge.sendThemeChanged();
        })
        
        this.buildSliderSetting('Độ trong suốt phím', `${this.keyOpacity}%`, this.keyOpacity, 10, 100, 1, (value: number) => {
          this.keyOpacity = Math.round(value);
          this.saveSetting(GTV_KEY_OPACITY_KEY, this.keyOpacity);
          KeyboardBridge.sendThemeChanged();
        })
      }
      .width('90%')
      .backgroundColor(this.cardBg)
      .borderRadius(16)
      .clip(true)
      .margin({ bottom: 20 })

      this.buildSectionTitle('Cài đặt nhanh (Quick Settings)')
      Column() {
        this.buildChoiceRow('Kích thước cửa sổ', ['180', '220', '260', '300', '340', '380', '420'], `${this.keyboardWindowHeight}`, (value: string) => {
          this.keyboardWindowHeight = parseInt(value);
          this.saveSetting(GTV_KEYBOARD_HEIGHT_VP_KEY, this.keyboardWindowHeight);
          KeyboardBridge.sendThemeChanged();
        })
        this.buildSettingNote('Kéo thanh ngang ở mép trên bàn phím để chỉnh tự do.')
        
        this.buildChoiceRow('Kích thước phím', ['Nhỏ', 'Vừa', 'Lớn'], this.fontWeightLevel, (value: string) => {
          this.fontWeightLevel = value;
          this.saveSetting(GTV_KEY_SIZE_LABEL_KEY, value);
          KeyboardBridge.sendThemeChanged();
        })

        this.buildToggleRow('Âm thanh khi ấn phím', '🔊', this.sound, (val: boolean) => {
          this.sound = val;
          this.saveSetting(GTV_SOUND_ENABLED_KEY, val);
          KeyboardBridge.sendThemeChanged();
        })

        this.buildToggleRow('Rung khi ấn phím', '📳', this.vibration, (val: boolean) => {
          this.vibration = val;
          this.saveSetting(GTV_VIBRATION_ENABLED_KEY, val);
          KeyboardBridge.sendThemeChanged();
        })

        this.buildToggleRow('Bật hàng phím số', '123', this.numberRowEnabled, (val: boolean) => {
          this.numberRowEnabled = val;
          this.saveSetting(GTV_SHOW_NUMBER_ROW_KEY, val);
          KeyboardBridge.sendThemeChanged();
        })

        this.buildToggleRow('Clipboard', '📋', this.clipboardDailyStore, (val: boolean) => {
          this.clipboardDailyStore = val;
          this.saveSetting(GTV_CLIPBOARD_ENABLED_KEY, val);
          KeyboardBridge.sendThemeChanged();
        })

        this.buildToggleRow('Tự động sửa lỗi', '✏️', this.autocorrect, (val: boolean) => {
          this.autocorrect = val;
          // Placeholder for autocorrect logic
        })
      }
      .width('90%')
      .backgroundColor(this.cardBg)
      .borderRadius(16)
      .clip(true)
      .margin({ bottom: 20 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 16 })
  }

"""

final_content = content[:start_idx] + new_content + content[end_idx:]

# Additionally, we need to remove `openedFeature` logic from the main build block.
# Search for `if (this.openedFeature !== '') {`
build_start = final_content.find('        if (this.selectedTab === 0) {')
build_end = final_content.find('        } else if (this.selectedTab === 1) {')

if build_start != -1 and build_end != -1:
    new_build_block = """        if (this.selectedTab === 0) {
          Scroll() {
            this.buildMainSettings()
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
"""
    final_content = final_content[:build_start] + new_build_block + final_content[build_end:]

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/Index.ets', 'w') as f:
    f.write(final_content)

print("Done rewrite")
