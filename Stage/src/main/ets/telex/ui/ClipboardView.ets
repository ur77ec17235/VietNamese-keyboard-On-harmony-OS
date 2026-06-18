/**
 * ClipboardView.ets
 * Panel hiển thị clipboard text
 */

import { ClipboardItem } from '../service/ClipboardManager';

export interface ClipboardViewCallbacks {
  onPasteText: (text: string) => void;
  onClose: () => void;
}

@Component
export struct ClipboardView {
  @Prop items: ClipboardItem[] = [];
  callbacks: ClipboardViewCallbacks = {
    onPasteText: () => {},
    onClose: () => {},
  };

  build() {
    Column() {
      // Header
      Row() {
        Text('📋 Clipboard')
          .fontSize(14)
          .fontColor('#CCCCEE')
          .fontWeight(FontWeight.Bold)
          .padding({ left: 12 })
        Blank()
        Button('✕')
          .width(30)
          .height(30)
          .fontSize(14)
          .fontColor('#888899')
          .backgroundColor('transparent')
          .onClick(() => this.callbacks.onClose())
          .margin({ right: 8 })
      }
      .width('100%')
      .height(36)
      .backgroundColor('#0D0D24')
      .alignItems(VerticalAlign.Center)

      // Clipboard items
      if (this.items.length === 0) {
        Column() {
          Text('Chưa có nội dung clipboard')
            .fontSize(13)
            .fontColor('#555577')
            .margin({ top: 20 })
        }
        .width('100%')
        .height(80)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.items, (item: ClipboardItem) => {
              Row() {
                Text(item.text)
                  .fontSize(13)
                  .fontColor('#CCCCEE')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
                  .margin({ right: 8 })

                Button('Dán')
                  .fontSize(12)
                  .fontColor('#4FC3F7')
                  .height(28)
                  .backgroundColor('#1A1A40')
                  .borderRadius(6)
                  .onClick(() => this.callbacks.onPasteText(item.text))
              }
              .width('100%')
              .padding({ left: 10, right: 10, top: 8, bottom: 8 })
              .borderBottom({ width: 1, color: '#1E1E3A' })
              .alignItems(VerticalAlign.Center)
            })
          }
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .height(120)
      }
    }
    .width('100%')
    .backgroundColor('#0D0D1E')
    .border({ width: { top: 1 }, color: '#1E1E3A' })
  }
}
