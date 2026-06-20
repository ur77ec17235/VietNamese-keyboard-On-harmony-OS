import re

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/Index.ets', 'r') as f:
    content = f.read()

# 1. Remove saveSetting and KeyboardBridge.sendThemeChanged() from color pickers
content = content.replace(
    'this.saveSetting(GTV_TEXT_COLOR_KEY, this.textBaseColor);',
    ''
)
content = content.replace(
    'this.saveSetting(GTV_BG_COLOR_KEY, color);\n                  KeyboardBridge.sendThemeChanged();',
    ''
)
content = content.replace(
    'this.saveSetting(GTV_KEY_COLOR_KEY, color);\n                  KeyboardBridge.sendThemeChanged();',
    ''
)
content = content.replace(
    'this.saveSetting(GTV_TEXT_COLOR_KEY, color);\n                  KeyboardBridge.sendThemeChanged();',
    ''
)

# 2. Remove from opacity sliders
content = content.replace(
    'this.saveSetting(GTV_BG_OPACITY_KEY, op);\n                KeyboardBridge.sendThemeChanged();',
    ''
)
content = content.replace(
    'this.saveSetting(GTV_KEY_OPACITY_KEY, op);\n                KeyboardBridge.sendThemeChanged();',
    ''
)

# 3. Add the "Lưu & Áp dụng" button at the end of the buildThemeSettings section
# Let's find the end of buildThemeSettings.
# I'll look for `buildQuickSettings()`
save_btn = """
        Button('Lưu Giao Diện & Đồng Bộ Bàn Phím')
          .width('100%')
          .margin({ top: 16, bottom: 8 })
          .backgroundColor(this.accentColor)
          .fontColor(Color.White)
          .onClick(async () => {
            await this.saveSetting(GTV_BG_OPACITY_KEY, this.backgroundOpacity);
            await this.saveSetting(GTV_KEY_OPACITY_KEY, this.keyOpacity);
            await this.saveSetting(GTV_BG_COLOR_KEY, this.bgBaseColor);
            await this.saveSetting(GTV_KEY_COLOR_KEY, this.keyBaseColor);
            await this.saveSetting(GTV_TEXT_COLOR_KEY, this.textBaseColor);
            await this.saveSetting(GTV_DARK_MODE_KEY, this.darkMode);
            KeyboardBridge.sendThemeChanged();
            
            // Publish event cho GoTiengVietService (chạy ngầm)
            import('@ohos.commonEventManager').then((commonEventManager) => {
              commonEventManager.default.publish('com.example.gotiengviet.THEME_CHANGED', (err) => {
                if (err) {
                  console.error('Publish THEME_CHANGED error', err);
                } else {
                  console.info('Publish THEME_CHANGED success');
                }
              });
            });
          })
"""
content = content.replace(
    '      }.padding(16)\n    }\n  }\n\n  @Builder buildQuickSettings() {',
    f'{save_btn}\n      }}.padding(16)\n    }}\n  }}\n\n  @Builder buildQuickSettings() {{'
)

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/Index.ets', 'w') as f:
    f.write(content)

print("Done patching Index.ets")
