@Component
export struct VirtualKeyboard {
  @State private shift: boolean = false;
  @State private currentLayout: 'letters' | 'numbers' = 'letters';

  private letterRows: string[][] = [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['shift', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'backspace'],
    ['123', 'lang', 'space', '.', 'enter']
  ];

  private numberRows: string[][] = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['-', '/', ':', ';', '(', ')', '$', '&', '@', '"'],
    ['#+=', '.', ',', '?', '!', '\'', 'backspace'],
    ['abc', 'lang', 'space', '.', 'enter']
  ];

  build() {
    Column() {
      // Keyboard layout
      Column() {
        ForEach(this.getCurrentRows(), (row: string[], rowIndex: number) => {
          this.buildRow(row, rowIndex)
        })
      }
      .width('100%')
      .backgroundColor('#f0f0f0')
      .padding(5)
    }
  }

  @Builder
  buildRow(row: string[], rowIndex: number) {
    Row() {
      ForEach(row, (key: string) => {
        this.buildKey(key)
      })
    }
    .justifyContent(FlexAlign.Center)
    .margin({ top: 2, bottom: 2 })
  }

  @Builder
  buildKey(key: string) {
    const isSpecial = ['shift', 'backspace', 'space', 'enter', '123', 'abc', 'lang', '#+='].includes(key);
    const width = key === 'space' ? '40%' : '10%';

    Button(this.getKeyLabel(key)) {
      Text(this.getKeyLabel(key))
        .fontSize(16)
        .fontColor(isSpecial ? Color.White : Color.Black)
    }
    .width(width)
    .height(50)
    .backgroundColor(isSpecial ? '#5f6368' : '#ffffff')
    .borderRadius(5)
    .onClick(() => this.onKeyPress(key))
    .margin(1)
  }

  private getKeyLabel(key: string): string {
    switch (key) {
      case 'shift': return this.shift ? '⇧' : '↑';
      case 'backspace': return '⌫';
      case 'space': return 'Space';
      case 'enter': return '⏎';
      case 'lang': return '🌐';
      case '123': return '123';
      case 'abc': return 'ABC';
      case '#+=': return '#+=';
      default:
        if (this.currentLayout === 'letters' && this.shift) {
          return key.toUpperCase();
        }
        return key;
    }
  }

  private getCurrentRows(): string[][] {
    return this.currentLayout === 'letters' ? this.letterRows : this.numberRows;
  }

  private onKeyPress(key: string): void {
    console.log('Key pressed:', key);

    // Send key event to service
    this.sendKeyEvent(key);

    // Handle special keys
    switch (key) {
      case 'shift':
        this.shift = !this.shift;
        break;
      case '123':
        this.currentLayout = 'numbers';
        break;
      case 'abc':
        this.currentLayout = 'letters';
        break;
      case 'space':
        this.sendKeyEvent(' ');
        break;
      case 'enter':
        this.sendKeyEvent('Enter');
        break;
    }
  }

  private sendKeyEvent(key: string): void {
    // Dispatch event to input method service
    // In real implementation, use IPC or event bus
    console.log('Dispatching key:', key);
  }
}