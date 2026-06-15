/**
 * CandidateView.ets
 * Thanh gợi ý từ - hiển thị phía trên bàn phím
 * Thiết kế đẹp với highlight cho từ được chọn
 */

export interface CandidateCallbacks {
  onSelect: (text: string) => void;
  onClipboard: () => void;
  onHide: () => void;
}

@Component
export struct CandidateView {
  @Prop composingText: string = '';
  @Prop candidates: string[] = [];
  @Prop inputModeName: string = 'VI-Telex';

  callbacks: CandidateCallbacks = {
    onSelect: () => {},
    onClipboard: () => {},
    onHide: () => {},
  };

  build() {
    Row() {
      // Composing text
      if (this.composingText.length > 0) {
        Row() {
          Text(this.composingText)
            .fontSize(14)
            .fontColor('#4FC3F7')
            .fontWeight(FontWeight.Bold)
            .padding({ left: 10, right: 10 })
        }
        .height('100%')
        .alignItems(VerticalAlign.Center)
        .borderRight({ width: 1, color: '#2A2A4A' })
      }

      // Candidates
      Scroll() {
        Row() {
          ForEach(this.candidates, (word: string, idx: number) => {
            Text(word)
              .fontSize(14)
              .fontColor(idx === 0 ? '#E94560' : '#CCCCEE')
              .padding({ left: 14, right: 14, top: 5, bottom: 5 })
              .borderRadius(14)
              .backgroundColor(idx === 0 ? '#1A0A30' : 'transparent')
              .margin({ left: 2, right: 2 })
              .onClick(() => this.callbacks.onSelect(word))
          })
        }
        .padding({ left: 4, right: 4 })
        .constraintSize({ minHeight: '100%' })
        .alignItems(VerticalAlign.Center)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .height('100%')

      // Mode badge
      Text(this.inputModeName)
        .fontSize(10)
        .fontColor('#888899')
        .padding({ left: 6, right: 6 })
        .borderRadius(8)
        .backgroundColor('#1A1A30')
        .margin({ right: 4 })

      // Clipboard button
      Button() {
        Text('📋')
          .fontSize(15)
      }
      .width(34)
      .height(34)
      .backgroundColor('transparent')
      .borderRadius(17)
      .onClick(() => this.callbacks.onClipboard())

      // Hide keyboard button
      Button() {
        Text('⌄')
          .fontSize(16)
          .fontColor('#AAAACC')
      }
      .width(34)
      .height(34)
      .backgroundColor('transparent')
      .borderRadius(17)
      .onClick(() => this.callbacks.onHide())
      .margin({ right: 4 })
    }
    .width('100%')
    .height(42)
    .backgroundColor('#0D0D1E')
    .borderBottom({ width: StyleConstants.DIVIDER_WIDTH, color: '#1E1E3A' })
    .alignItems(VerticalAlign.Center)
    .padding({ left: 2, right: 2 })
  }
}

class StyleConstants {
  static readonly DIVIDER_WIDTH: number = 1;
}