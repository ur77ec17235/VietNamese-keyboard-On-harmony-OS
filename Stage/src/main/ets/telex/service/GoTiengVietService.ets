/**
 * GoTiengVietService.ets
 * Input Method Extension Service cho HarmonyOS 5.1
 *
 * Đây là service chính của bàn phím GoTiếngViệt.
 * Sử dụng đúng API: InputMethodExtensionAbility + inputMethodEngine
 * Kết nối với KeyboardPage UI qua KeyboardBridge và AppStorage
 */

import InputMethodExtensionAbility from '@ohos.InputMethodExtensionAbility';
import inputMethodEngine from '@ohos.inputMethodEngine';
import Want from '@ohos.app.ability.Want';
import { InputMethodManager } from '../core/InputMethodManager';
import { InputMode } from '../core/InputEngineBase';
import { ClipboardManager } from './ClipboardManager';
import { KeyboardBridge } from './KeyboardBridge';
import display from '@ohos.display';

// AppStorage keys để sync state với UI
export const KEY_INPUT_MODE = 'gtv_inputMode';
export const KEY_COMPOSING = 'gtv_composingText';
export const KEY_CANDIDATES = 'gtv_candidates';
export const KEY_IS_SHIFTED = 'gtv_isShifted';
export const KEY_SHOW_CLIPBOARD = 'gtv_showClipboard';
export const KEY_CLIPBOARD_ITEMS = 'gtv_clipboardItems';

export default class GoTiengVietService extends InputMethodExtensionAbility {
  private panel: inputMethodEngine.Panel | null = null;
  private inputClient: inputMethodEngine.InputClient | null = null;
  private kbController: inputMethodEngine.KeyboardController | null = null;
  private imeManager: InputMethodManager = new InputMethodManager();
  private clipboardMgr: ClipboardManager = new ClipboardManager();
  private currentComposing: string = '';
  private isShowing: boolean = false;
  private panelReady: boolean = false;
  private userRequestedHide: boolean = false;

  onCreate(want: Want): void {
    console.info('[GoTiengViet] Service onCreate');

    // Khởi tạo AppStorage defaults
    AppStorage.setOrCreate(KEY_INPUT_MODE, InputMode.TELEX);
    AppStorage.setOrCreate(KEY_COMPOSING, '');
    AppStorage.setOrCreate(KEY_CANDIDATES, [] as string[]);
    AppStorage.setOrCreate(KEY_IS_SHIFTED, false);
    AppStorage.setOrCreate(KEY_SHOW_CLIPBOARD, false);
    AppStorage.setOrCreate(KEY_CLIPBOARD_ITEMS, []);

    // Đăng ký bridge handlers để UI gửi events vào service
    this.registerBridgeHandlers();

    const ima = inputMethodEngine.getInputMethodAbility();

    // === Lắng nghe input lifecycle ===
    ima.on('inputStart', (kbController: inputMethodEngine.KeyboardController,
      inputClient: inputMethodEngine.InputClient) => {
      console.info('[GoTiengViet] inputStart');
      this.kbController = kbController;
      this.inputClient = inputClient;
      this.imeManager.reset();
      this.currentComposing = '';
      this.userRequestedHide = false;
      AppStorage.set(KEY_COMPOSING, '');
      AppStorage.set(KEY_CANDIDATES, [] as string[]);
      this.isShowing = true;
    });

    ima.on('inputStop', () => {
      console.info('[GoTiengViet] inputStop');
      this.currentComposing = '';
      this.imeManager.reset();
      this.inputClient = null;
      this.kbController = null;
      this.isShowing = false;
      AppStorage.set(KEY_COMPOSING, '');
      AppStorage.set(KEY_CANDIDATES, [] as string[]);
    });

    ima.on('keyboardShow', () => {
      console.info('[GoTiengViet] keyboardShow');
      if (this.userRequestedHide) {
        return;
      }
      this.isShowing = true;
      this.showKeyboard();
    });

    ima.on('keyboardHide', () => {
      console.info('[GoTiengViet] keyboardHide');
      this.isShowing = false;
      AppStorage.set(KEY_SHOW_CLIPBOARD, false);
    });

    // Lắng nghe thay đổi subtype từ hệ thống
    ima.on('setSubtype', (subtype) => {
      const id = subtype?.id || '';
      console.info('[GoTiengViet] setSubtype:', id);
      if (id === 'telex-vi') {
        this.imeManager.setMode(InputMode.TELEX);
      } else if (id === 'vni-vi') {
        this.imeManager.setMode(InputMode.VNI);
      } else if (id === 'en') {
        this.imeManager.setMode(InputMode.ENGLISH);
      }
      AppStorage.set(KEY_INPUT_MODE, this.imeManager.getCurrentMode());
    });

    // Tạo keyboard panel
    this.createKeyboardPanel(ima);
  }

  private registerBridgeHandlers(): void {
    // Nhận phím từ UI keyboard
    KeyboardBridge.registerKeyHandler((key: string) => {
      this.keyQueue.push(key);
      this.processKeyQueue().catch((err: Error) => {
        console.error('[GoTiengViet] processKeyQueue error:', err);
      });
    });

    // Shift
    KeyboardBridge.registerShiftHandler(() => {
      this.imeManager.toggleShift();
      AppStorage.set(KEY_IS_SHIFTED, this.imeManager.isShifted());
    });

    // Enter
    KeyboardBridge.registerEnterHandler(() => {
      this.handleEnter();
    });

    // Chuyển mode gõ
    KeyboardBridge.registerModeHandler(() => {
      const newMode = this.imeManager.cycleMode();
      AppStorage.set(KEY_INPUT_MODE, newMode);
      this.imeManager.reset();
      this.currentComposing = '';
      AppStorage.set(KEY_COMPOSING, '');
      AppStorage.set(KEY_IS_SHIFTED, false);
    });

    // Hiện clipboard
    KeyboardBridge.registerClipboardHandler(async () => {
      await this.loadClipboard();
      AppStorage.set(KEY_SHOW_CLIPBOARD, true);
    });

    // Ẩn keyboard
    KeyboardBridge.registerHideHandler(() => {
      this.currentComposing = '';
      this.imeManager.reset();
      this.userRequestedHide = true;
      this.hideKeyboard();
    });

    // Chọn candidate (tạm vô hiệu trong local composing mode)
    KeyboardBridge.registerCandidateHandler((_text: string) => {
      AppStorage.set(KEY_CANDIDATES, [] as string[]);
    });

    // Dán từ clipboard
    KeyboardBridge.registerPasteHandler((text: string) => {
      this.pasteText(text);
    });
  }

  private async createKeyboardPanel(ima: inputMethodEngine.InputMethodAbility): Promise<void> {
    try {
      const panelInfo: inputMethodEngine.PanelInfo = {
        type: inputMethodEngine.PanelType.SOFT_KEYBOARD,
        flag: inputMethodEngine.PanelFlag.FLG_FIXED
      };

      this.panel = await ima.createPanel(this.context, panelInfo);
      this.panelReady = true;
      console.info('[GoTiengViet] Panel created');

      // Resize panel (BẮT BUỘC TRÊN API 9+ TRƯỚC KHI SHOW)
      try {
        const d = display.getDefaultDisplaySync();
        const kbHeight = Math.floor(d.height * 0.35); // Khoảng 35% chiều cao màn hình
        await this.panel.resize(d.width, kbHeight);
        console.info('[GoTiengViet] Panel resized');
      } catch (e) {
        console.error('[GoTiengViet] resize error:', e);
      }

      // Load keyboard UI vào panel
      await this.panel.setUiContent('pages/KeyboardPage');
      console.info('[GoTiengViet] KeyboardPage loaded');
      
      // Nếu có lệnh show trước khi panel load xong, gọi lại showKeyboard
      if (this.isShowing) {
        this.showKeyboard();
      }
    } catch (err) {
      console.error('[GoTiengViet] createKeyboardPanel error:', JSON.stringify(err));
    }
  }

  private showKeyboard(): void {
    if (!this.panel || !this.panelReady) {
      return;
    }
    this.panel.show().catch((err: Error) => {
      console.error('[GoTiengViet] show panel error:', err);
    });
  }

  private hideKeyboard(): void {
    this.isShowing = false;
    AppStorage.set(KEY_SHOW_CLIPBOARD, false);
    if (this.panel) {
      this.panel.hide().catch((err: Error) => {
        console.error('[GoTiengViet] hide panel error:', err);
      });
    }
  }

  private keyQueue: string[] = [];
  private isProcessingKey: boolean = false;

  private async processKeyQueue(): Promise<void> {
    if (this.isProcessingKey) return;
    this.isProcessingKey = true;

    while (this.keyQueue.length > 0) {
      const key = this.keyQueue.shift();
      if (key) {
        await this.handleVirtualKey(key);
      }
    }

    this.isProcessingKey = false;
  }

  private async handleVirtualKey(key: string): Promise<void> {
    if (!this.inputClient) return;

    const result = this.imeManager.processInput(key);

    try {
      if (result.deleteCount > 0 && result.composingText.length === 0 && result.commitText.length === 0) {
        for (let i = 0; i < result.deleteCount; i++) {
          this.inputClient.deleteForwardSync(1);
        }
        this.currentComposing = '';
      } else if (result.commitText.length > 0) {
        this.inputClient.insertTextSync(result.commitText);
        this.currentComposing = '';
      } else if (result.composingText.length > 0) {
        const previousLength = this.currentComposing.length;
        const nextLength = result.composingText.length;

        if (previousLength > 0) {
          this.inputClient.deleteForwardSync(previousLength);
        }
        this.inputClient.insertTextSync(result.composingText);
        this.currentComposing = result.composingText;

        if (nextLength > 0) {
          for (let i = 0; i < nextLength; i++) {
            this.inputClient.deleteBackwardSync(1);
          }
        }
      } else {
        this.currentComposing = '';
      }
    } catch (err) {
      console.error('[GoTiengViet] handleVirtualKey error:', err);
    }

    AppStorage.set(KEY_COMPOSING, '');
    AppStorage.set(KEY_CANDIDATES, [] as string[]);
    AppStorage.set(KEY_IS_SHIFTED, this.imeManager.isShifted());
  }

  private async handleEnter(): Promise<void> {
    if (!this.inputClient) return;
    try {
      this.inputClient.insertTextSync('\n');
      this.currentComposing = '';
      this.imeManager.reset();
      AppStorage.set(KEY_COMPOSING, '');
      AppStorage.set(KEY_CANDIDATES, [] as string[]);
    } catch (err) {
      console.error('[GoTiengViet] handleEnter error:', err);
    }
  }

  private async pasteText(text: string): Promise<void> {
    if (!this.inputClient || text.length === 0) return;
    try {
      this.inputClient.insertTextSync(text);
      this.currentComposing = '';
      this.imeManager.reset();
      AppStorage.set(KEY_COMPOSING, '');
      AppStorage.set(KEY_CANDIDATES, [] as string[]);
      AppStorage.set(KEY_SHOW_CLIPBOARD, false);
    } catch (err) {
      console.error('[GoTiengViet] pasteText error:', err);
    }
  }

  private async loadClipboard(): Promise<void> {
    try {
      await this.clipboardMgr.getClipboardContent();
      const history = this.clipboardMgr.getHistory();
      AppStorage.set(KEY_CLIPBOARD_ITEMS, history);
    } catch (err) {
      console.error('[GoTiengViet] loadClipboard error:', err);
    }
  }

  onDestroy(): void {
    console.info('[GoTiengViet] Service onDestroy');
    KeyboardBridge.clearHandlers();

    const ima = inputMethodEngine.getInputMethodAbility();
    if (this.panel) {
      ima.destroyPanel(this.panel).catch((err: Error) => {
        console.error('[GoTiengViet] destroyPanel error:', err);
      });
      this.panel = null;
      this.panelReady = false;
    }

    ima.off('keyboardShow');
    ima.off('keyboardHide');
  }
}
