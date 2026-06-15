/**
 * KeyboardPage.ets
 * Trang bàn phím chính - được load vào Panel của IME service
 * Giao tiếp với GoTiengVietService qua KeyboardBridge + AppStorage
 */

import { InputMode } from '../telex/core/InputEngineBase';
import { KeyboardBridge } from '../telex/service/KeyboardBridge';
import { KEY_INPUT_MODE, KEY_COMPOSING, KEY_CANDIDATES,
  KEY_IS_SHIFTED, KEY_SHOW_CLIPBOARD, KEY_CLIPBOARD_ITEMS } from '../telex/service/GoTiengVietService';
import { ClipboardItem } from '../telex/service/ClipboardManager';

// Dùng enum thay vì string union type (ArkTS yêu cầu)
enum KeyLayout {
  LETTERS = 'letters',
  NUMBERS = 'numbers',
  SYMBOLS = 'symbols'
}

// Layout bàn phím QWERTY
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

@Entry
@Component
struct KeyboardPage {
  // Reactive state từ AppStorage (được update bởi GoTiengVietService)
  @StorageLink(KEY_INPUT_MODE) inputMode: InputMode = InputMode.TELEX;
  @StorageLink(KEY_COMPOSING) composingText: string = '';
  @StorageLink(KEY_CANDIDATES) candidates: string[] = [];
  @StorageLink(KEY_IS_SHIFTED) isShifted: boolean = false;
  @StorageLink(KEY_SHOW_CLIPBOARD) showClipboard: boolean = false;
  @StorageLink(KEY_CLIPBOARD_ITEMS) clipboardItems: ClipboardItem[] = [];

  @State layout: KeyLayout = KeyLayout.LETTERS;
  @State pressedKey: string = '';

  // === Theme colors ===
  private readonly bgColor: string = '#111128';
  private readonly keyBgNormal: string = '#1E1E42';
  private readonly keyBgSpecial: string = '#0C0C2E';
  private readonly keyBgAccent: string = '#C62B45';
  private readonly keyBgLang: string = '#162650';
  private readonly keyBgSpace: string = '#1A1A3E';
  private readonly textColor: string = '#E8E8F0';
  private readonly composingColor: string = '#5BC8F5';
  private readonly candidateColor: string = '#E94560';
  private readonly barBg: string = '#0A0A1A';

  // Long-press extras — dùng .set() thay vì constructor array để tránh lỗi ArkTS
  private readonly longPressMap: Map<string, string[]> = new Map<string, string[]>();

  aboutToAppear(): void {
    // Khởi tạo long-press map
    this.longPressMap.set('a', ['à', 'á', 'â', 'ã', 'ạ', 'ă']);
    this.longPressMap.set('e', ['è', 'é', 'ê', 'ẹ']);
    this.longPressMap.set('i', ['ì', 'í', 'ị', 'ĩ']);
    this.longPressMap.set('o', ['ò', 'ó', 'ô', 'ơ', 'ọ']);
    this.longPressMap.set('u', ['ù', 'ú', 'ư', 'ụ']);
    this.longPressMap.set('d', ['đ']);
    this.longPressMap.set('y', ['ỳ', 'ý', 'ỵ']);
    this.longPressMap.set('n', ['ñ']);
    this.longPressMap.set('0', ['°', 'đ']);
    this.longPressMap.set('1', ['!', '¡', '¹']);
    this.longPressMap.set('2', ['@', '²']);
    this.longPressMap.set('3', ['#', '³']);
    this.longPressMap.set('.', ['…', '·']);
    this.longPressMap.set('-', ['—', '–']);
    this.longPressMap.set('!', ['¡']);
  }

  getCurrentRows(): string[][] {
    switch (this.layout) {
      case KeyLayout.NUMBERS: return NUMBER_ROWS;
      case KeyLayout.SYMBOLS: return SYMBOL_ROWS;
      default: return LETTER_ROWS;
    }
  }

  getKeyLabel(key: string): string {
    switch (key) {
      case 'SHIFT': return this.isShifted ? '⬆' : '⇧';
      case 'BACKSPACE': return '⌫';
      case 'SPACE': return this.getModeName();
      case 'ENTER': return '↵';
      case 'LANG': return this.getLangBadge();
      case 'NUMBERS': return '123';
      case 'SYMBOLS': return '#+=';
      case 'LETTERS': return 'ABC';
      default:
        if (this.layout === KeyLayout.LETTERS && this.isShifted) return key.toUpperCase();
        return key;
    }
  }

  getModeName(): string {
    switch (this.inputMode) {
      case InputMode.TELEX: return 'Telex';
      case InputMode.VNI: return 'VNI';
      case InputMode.ENGLISH: return 'English';
      default: return 'VI';
    }
  }

  getLangBadge(): string {
    switch (this.inputMode) {
      case InputMode.TELEX: return 'TX';
      case InputMode.VNI: return 'VN';
      case InputMode.ENGLISH: return 'EN';
      default: return 'VI';
    }
  }

  getKeyWidth(key: string): string {
    switch (key) {
      case 'SPACE': return '35%';
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

  getKeyBg(key: string): string {
    if (key === this.pressedKey) return this.keyBgAccent;
    if (key === 'SHIFT' && this.isShifted) return this.keyBgAccent;
    if (key === 'LANG') return this.keyBgLang;
    if (key === 'SPACE') return this.keyBgSpace;
    if (this.isSpecialKey(key)) return this.keyBgSpecial;
    return this.keyBgNormal;
  }

  onKeyPress(key: string): void {
    this.pressedKey = key;
    this.processKey(key);
    setTimeout(() => { this.pressedKey = ''; }, 120);
  }

  processKey(key: string): void {
    switch (key) {
      case 'SHIFT':
        KeyboardBridge.sendShift();
        break;
      case 'BACKSPACE':
        KeyboardBridge.sendKey('Delete');
        break;
      case 'SPACE':
        KeyboardBridge.sendKey(' ');
        break;
      case 'ENTER':
        KeyboardBridge.sendEnter();
        break;
      case 'LANG':
        KeyboardBridge.sendModeSwitch();
        break;
      case 'NUMBERS':
        this.layout = KeyLayout.NUMBERS;
        break;
      case 'SYMBOLS':
        this.layout = KeyLayout.SYMBOLS;
        break;
      case 'LETTERS':
        this.layout = KeyLayout.LETTERS;
        break;
      default:
        const ch = (this.layout === KeyLayout.LETTERS && this.isShifted)
          ? key.toUpperCase() : key;
        KeyboardBridge.sendKey(ch);
    }
  }

  handleLongPress(_key: string): void {
    // Tạm tắt long-press để tránh double input / miss tap trên SDK 23.
  }

  build() {
    Column() {
      // === Simple Top Bar ===
      this.buildTopBar()

      // === Clipboard Panel (khi mở) ===
      if (this.showClipboard) {
        this.buildClipboardPanel()
      }

      // === Keyboard Body ===
      Column() {
        ForEach(this.getCurrentRows(), (row: string[]) => {
          Row() {
            ForEach(row, (key: string) => {
              this.buildKey(key)
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 3, bottom: 3 })
        })
      }
      .width('100%')
      .backgroundColor(this.bgColor)
      .padding({ top: 4, bottom: 10, left: 2, right: 2 })
    }
    .width('100%')
    .backgroundColor(this.bgColor)
  }

  @Builder
  buildTopBar() {
    Row() {
      Blank().layoutWeight(1)

      // Nút Clipboard
      Button() {
        Text('📋')
          .fontSize(16)
      }
      .width(38)
      .height(38)
      .backgroundColor(this.showClipboard ? '#1A3050' : 'transparent')
      .borderRadius(8)
      .onClick(() => {
        if (this.showClipboard) {
          this.showClipboard = false;
        } else {
          KeyboardBridge.sendClipboard();
        }
      })

      // Nút ẩn keyboard
      Button() {
        Text('⌄')
          .fontSize(20)
          .fontColor('#8888AA')
      }
      .width(38)
      .height(38)
      .backgroundColor('transparent')
      .onClick(() => KeyboardBridge.sendHide())
      .margin({ right: 2 })
    }
    .width('100%')
    .height(44)
    .backgroundColor(this.barBg)
    .border({ width: { bottom: 1 }, color: '#1E1E3A' })
    .alignItems(VerticalAlign.Center)
    .padding({ left: 4, right: 2 })
  }

  @Builder
  buildClipboardPanel() {
    Column() {
      // Clipboard header
      Row() {
        Text('📋  Clipboard')
          .fontSize(13)
          .fontColor('#AAAACC')
          .fontWeight(FontWeight.Bold)
          .padding({ left: 12 })
        Blank()
        Button('✕')
          .width(28)
          .height(28)
          .fontSize(13)
          .fontColor('#666688')
          .backgroundColor('transparent')
          .onClick(() => { this.showClipboard = false; })
          .margin({ right: 8 })
      }
      .width('100%')
      .height(34)
      .backgroundColor('#0D0D22')
      .alignItems(VerticalAlign.Center)

      if (this.clipboardItems.length === 0) {
        Text('Chưa có nội dung clipboard')
          .fontSize(13)
          .fontColor('#444466')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 14, bottom: 14 })
      } else {
        Scroll() {
          Column() {
            ForEach(this.clipboardItems, (item: ClipboardItem) => {
              if (item.type !== 'image') {
                Row() {
                  Text(item.text || '')
                    .fontSize(13)
                    .fontColor('#CCCCEE')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                    .margin({ right: 8 })

                  Button('Dán')
                    .fontSize(12)
                    .fontColor('#4FC3F7')
                    .height(26)
                    .padding({ left: 10, right: 10 })
                    .backgroundColor('#101030')
                    .borderRadius(6)
                    .onClick(() => KeyboardBridge.sendPasteText(item.text || ''))
                }
                .width('100%')
                .padding({ left: 12, right: 10, top: 7, bottom: 7 })
                .border({ width: { bottom: 1 }, color: '#181830' })
                .alignItems(VerticalAlign.Center)
              }
            })
          }
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .constraintSize({ maxHeight: 110 })
      }
    }
    .width('100%')
    .backgroundColor('#0D0D1E')
    .border({ width: { top: 1 }, color: '#1E1E3A' })
  }

  @Builder
  buildKey(key: string) {
    Button() {
      Text(this.getKeyLabel(key))
        .fontSize(this.isSpecialKey(key) ? 12 : 18)
        .fontColor(this.textColor)
        .fontWeight(this.isSpecialKey(key) ? FontWeight.Medium : FontWeight.Regular)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .padding({ left: 2, right: 2 })
    }
    .width(this.getKeyWidth(key))
    .height(46)
    .margin({ left: 2, right: 2 })
    .backgroundColor(this.getKeyBg(key))
    .borderRadius(9)
    .shadow({
      radius: 1.5,
      color: '#00000055',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => this.onKeyPress(key))
  }
}
