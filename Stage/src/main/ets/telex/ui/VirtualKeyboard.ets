/**
 * VirtualKeyboard.ets
 * Component bàn phím ảo - được sử dụng trong KeyboardPage
 * Thiết kế với dark theme, glassmorphism, và animation mượt mà
 */

import { InputMode } from '../core/InputEngineBase';

type KeyLayout = 'letters' | 'numbers' | 'symbols';

export interface KeyboardCallbacks {
  onKey: (key: string) => void;
  onShift: () => void;
  onBackspace: () => void;
  onSpace: () => void;
  onEnter: () => void;
  onModeSwitch: () => void;
  onLayoutChange: (layout: KeyLayout) => void;
  onClipboard: () => void;
  onHide: () => void;
}

const LETTER_ROWS: string[][] = [
  ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
  ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
  ['SHIFT', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'BACKSPACE'],
  ['LANG', 'NUMBERS', 'SPACE', 'ENTER'],
];

const NUMBER_ROWS: string[][] = [
  ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
  ['-', '/', ':', ';', '(', ')', '$', '&', '@', '"'],
  ['SYMBOLS', '.', ',', '?', '!', "'", 'BACKSPACE'],
  ['LANG', 'LETTERS', 'SPACE', 'ENTER'],
];

const SYMBOL_ROWS: string[][] = [
  ['[', ']', '{', '}', '#', '%', '^', '*', '+', '='],
  ['_', '\\', '|', '~', '<', '>', '€', '£', '¥', '·'],
  ['NUMBERS', '.', ',', '?', '!', "'", 'BACKSPACE'],
  ['LANG', 'LETTERS', 'SPACE', 'ENTER'],
];

@Component
export struct VirtualKeyboard {
  @Prop isShifted: boolean = false;
  @Prop inputMode: InputMode = InputMode.TELEX;
  @State layout: KeyLayout = 'letters';
  @State pressedKey: string = '';

  callbacks: KeyboardCallbacks = {
    onKey: () => {},
    onShift: () => {},
    onBackspace: () => {},
    onSpace: () => {},
    onEnter: () => {},
    onModeSwitch: () => {},
    onLayoutChange: () => {},
    onClipboard: () => {},
    onHide: () => {},
  };

  // Theme
  private bgColor = '#1A1A2E';
  private keyBg = '#16213E';
  private specialBg = '#0F3460';
  private accentColor = '#E94560';
  private textColor = '#EAEAEA';

  getModeShortLabel(): string {
    switch (this.inputMode) {
      case InputMode.TELEX: return 'TEX';
      case InputMode.VNI: return 'VNI';
      case InputMode.ENGLISH: return 'EN';
      default: return 'VI';
    }
  }

  getModeSpaceLabel(): string {
    switch (this.inputMode) {
      case InputMode.TELEX: return 'Telex';
      case InputMode.VNI: return 'VNI';
      case InputMode.ENGLISH: return 'English';
      default: return 'Tiếng Việt';
    }
  }

  getKeyLabel(key: string): string {
    switch (key) {
      case 'SHIFT': return this.isShifted ? '⬆' : '⇧';
      case 'BACKSPACE': return '⌫';
      case 'SPACE': return this.getModeSpaceLabel();
      case 'ENTER': return '↵';
      case 'LANG': return this.getModeShortLabel();
      case 'NUMBERS': return '123';
      case 'SYMBOLS': return '#+=';
      case 'LETTERS': return 'ABC';
      default:
        if (this.layout === 'letters' && this.isShifted) return key.toUpperCase();
        return key;
    }
  }

  getKeyWidth(key: string): string {
    switch (key) {
      case 'SPACE': return '36%';
      case 'SHIFT':
      case 'BACKSPACE': return '13%';
      case 'ENTER': return '16%';
      case 'LANG': return '9%';
      case 'NUMBERS':
      case 'LETTERS':
      case 'SYMBOLS': return '11%';
      default: return '9%';
    }
  }

  isSpecialKey(key: string): boolean {
    return ['SHIFT', 'BACKSPACE', 'SPACE', 'ENTER', 'LANG',
      'NUMBERS', 'SYMBOLS', 'LETTERS'].includes(key);
  }

  getKeyBg(key: string): ResourceColor {
    if (key === this.pressedKey) return this.accentColor;
    if (key === 'SHIFT' && this.isShifted) return this.accentColor;
    if (key === 'LANG') return '#1A3A6E';
    if (this.isSpecialKey(key)) return this.specialBg;
    return this.keyBg;
  }

  getCurrentRows(): string[][] {
    switch (this.layout) {
      case 'numbers': return NUMBER_ROWS;
      case 'symbols': return SYMBOL_ROWS;
      default: return LETTER_ROWS;
    }
  }

  onPress(key: string): void {
    this.pressedKey = key;
    switch (key) {
      case 'SHIFT': this.callbacks.onShift(); break;
      case 'BACKSPACE': this.callbacks.onBackspace(); break;
      case 'SPACE': this.callbacks.onSpace(); break;
      case 'ENTER': this.callbacks.onEnter(); break;
      case 'LANG': this.callbacks.onModeSwitch(); break;
      case 'NUMBERS': this.layout = 'numbers'; this.callbacks.onLayoutChange('numbers'); break;
      case 'SYMBOLS': this.layout = 'symbols'; this.callbacks.onLayoutChange('symbols'); break;
      case 'LETTERS': this.layout = 'letters'; this.callbacks.onLayoutChange('letters'); break;
      default:
        const ch = (this.layout === 'letters' && this.isShifted) ? key.toUpperCase() : key;
        this.callbacks.onKey(ch);
    }
    setTimeout(() => { this.pressedKey = ''; }, 80);
  }

  build() {
    Column() {
      ForEach(this.getCurrentRows(), (row: string[]) => {
        Row() {
          ForEach(row, (key: string) => {
            Stack() {
              Column()
                .width('100%')
                .height('100%')
                .borderRadius(8)
                .backgroundColor(this.getKeyBg(key))

              Text(this.getKeyLabel(key))
                .fontSize(this.isSpecialKey(key) ? 12 : 17)
                .fontColor(this.textColor)
                .fontWeight(this.isSpecialKey(key) ? FontWeight.Medium : FontWeight.Regular)
                .textAlign(TextAlign.Center)
                .maxLines(1)
            }
            .width(this.getKeyWidth(key))
            .height(48)
            .margin(2)
            .onClick(() => this.onPress(key))
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 3, bottom: 3 })
      })
    }
    .width('100%')
    .backgroundColor(this.bgColor)
    .padding({ top: 4, bottom: 8, left: 2, right: 2 })
  }
}