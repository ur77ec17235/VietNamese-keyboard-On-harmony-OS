import re

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/KeyboardPage.ets', 'r') as f:
    content = f.read()

# Add text color picker to Theme panel
theme_picker_addition = """
          Text('Màu chữ phím').fontSize(14).fontColor(this.mutedTxt).width('100%').padding({ left: 16, top: 16, bottom: 8 })
          Scroll() {
            Row() {
              ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
                Circle({ width: 36, height: 36 })
                  .fill(color)
                  .margin({ right: 12 })
                  .border({ width: this.textBase === color ? 3 : 0, color: '#4FC3F7' })
                  .onClick(() => {
                    this.textBase = color;
                    this.saveSetting(GTV_TEXT_COLOR_KEY, color);
                  })
              })
            }.padding({ left: 16, right: 16 })
          }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
"""

# Insert before Độ trong suốt nền
insert_pos = content.find("Text('Độ trong suốt nền')")
if insert_pos != -1:
    # Find the line start
    line_start = content.rfind('\n', 0, insert_pos)
    content = content[:line_start] + theme_picker_addition + content[line_start:]

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/KeyboardPage.ets', 'w') as f:
    f.write(content)

print("Done patching keyboard page 2")
