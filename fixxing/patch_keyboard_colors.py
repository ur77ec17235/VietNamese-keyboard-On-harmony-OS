import re

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/KeyboardPage.ets', 'r') as f:
    content = f.read()

old_bg = """          Text('Màu nền').fontSize(14).fontColor(this.mutedTxt).width('100%').padding({ left: 16, bottom: 8 })
          Scroll() {
            Row() {
              ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
                Circle({ width: 36, height: 36 })
                  .fill(color)
                  .margin(6)
                  .border({ width: this.bgBase === color ? 3 : 0, color: this.kbTheme().selectedBorder })
                  .onClick(() => {
                    this.bgBase = color;
                    this.saveThemeSetting(GTV_BG_COLOR_KEY, color);
                  })
              })
            }.width('100%').padding({ left: 10, right: 10 })
          }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)"""

new_bg = """          Text('Màu nền').fontSize(14).fontColor(this.mutedTxt).width('100%').padding({ left: 16, bottom: 8 })
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
              Rect({ width: 40, height: 40 })
                .radius(8)
                .fill(color)
                .margin(6)
                .border({ width: this.bgBase === color ? 3 : 1, color: this.bgBase === color ? this.kbTheme().selectedBorder : '#444' })
                .onClick(() => {
                  this.bgBase = color;
                  this.saveThemeSetting(GTV_BG_COLOR_KEY, color);
                })
            })
          }.width('100%').padding({ left: 10, right: 10 })"""

old_key = """          Text('Màu phím').fontSize(14).fontColor(this.mutedTxt).width('100%').padding({ left: 16, top: 8, bottom: 8 })
          Scroll() {
            Row() {
              ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
                Circle({ width: 36, height: 36 })
                  .fill(color)
                  .margin(6)
                  .border({ width: this.keyBase === color ? 3 : 0, color: this.kbTheme().selectedBorder })
                  .onClick(() => {
                    this.keyBase = color;
                    this.saveThemeSetting(GTV_KEY_COLOR_KEY, color);
                  })
              })
            }.width('100%').padding({ left: 10, right: 10 })
          }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)"""

new_key = """          Text('Màu phím').fontSize(14).fontColor(this.mutedTxt).width('100%').padding({ left: 16, top: 8, bottom: 8 })
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
              Rect({ width: 40, height: 40 })
                .radius(8)
                .fill(color)
                .margin(6)
                .border({ width: this.keyBase === color ? 3 : 1, color: this.keyBase === color ? this.kbTheme().selectedBorder : '#444' })
                .onClick(() => {
                  this.keyBase = color;
                  this.saveThemeSetting(GTV_KEY_COLOR_KEY, color);
                })
            })
          }.width('100%').padding({ left: 10, right: 10 })"""

old_txt = """          Text('Màu chữ phím').fontSize(14).fontColor(this.mutedTxt).width('100%').padding({ left: 16, top: 16, bottom: 8 })
          Scroll() {
            Row() {
              ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
                Circle({ width: 36, height: 36 })
                  .fill(color)
                  .margin({ right: 12 })
                  .border({ width: this.textBase === color ? 3 : 0, color: '#4FC3F7' })
                  .onClick(() => {
                    this.textBase = color;
                    this.saveThemeSetting(GTV_TEXT_COLOR_KEY, color);
                  })
              })
            }.padding({ left: 16, right: 16 })
          }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)"""

new_txt = """          Text('Màu chữ phím').fontSize(14).fontColor(this.mutedTxt).width('100%').padding({ left: 16, top: 16, bottom: 8 })
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
              Rect({ width: 40, height: 40 })
                .radius(8)
                .fill(color)
                .margin(6)
                .border({ width: this.textBase === color ? 3 : 1, color: this.textBase === color ? '#4FC3F7' : '#444' })
                .onClick(() => {
                  this.textBase = color;
                  this.saveThemeSetting(GTV_TEXT_COLOR_KEY, color);
                })
            })
          }.width('100%').padding({ left: 10, right: 10 })"""

content = content.replace(old_bg, new_bg).replace(old_key, new_key).replace(old_txt, new_txt)

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/KeyboardPage.ets', 'w') as f:
    f.write(content)
print("Done patching color layout")
