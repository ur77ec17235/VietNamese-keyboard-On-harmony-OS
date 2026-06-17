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

const LOCAL_CANDIDATE_WORDS: string[] = [
  'anh', 'bao', 'ban', 'bạn', 'bây giờ', 'biết', 'cho', 'chưa', 'có', 'của',
  'cũng', 'đang', 'được', 'em', 'gì', 'hay', 'hôm nay', 'không', 'là', 'làm',
  'mình', 'muốn', 'này', 'nếu', 'ngày', 'người', 'nhé', 'nhưng', 'ở', 'phải',
  'rồi', 'sẽ', 'thì', 'thôi', 'tôi', 'trong', 'và', 'với', 'vì', 'việc'
];

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
  private lastLandscape: boolean = false;

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
      this.refreshPanelLayout().catch((err: Error) => {
        console.error('[GoTiengViet] refreshPanelLayout error:', err);
      });
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

    // Caps lock
    KeyboardBridge.registerCapsLockHandler(() => {
      this.imeManager.toggleCapsLock();
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

    // Chọn candidate: thay thế phần composing hiện tại rồi commit từ được chọn.
    KeyboardBridge.registerCandidateHandler((text: string) => {
      this.commitCandidate(text);
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
        await this.refreshPanelLayout();
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

  private async refreshPanelLayout(): Promise<void> {
    if (!this.panel) {
      return;
    }

    const d = display.getDefaultDisplaySync();
    const isLandscape = d.width > d.height;

    // Dọc: 40% chiều cao màn hình
    // Ngang: 42% chiều cao màn hình (shorter side) – bàn phím ngang thường ~40-45%
    const kbHeightPx = isLandscape
      ? Math.round(d.height * 0.42)
      : Math.round(d.height * 0.40);

    // Chuyển px sang vp cho UI layout
    const density = d.densityPixels > 0 ? d.densityPixels : 3.0;
    const kbHeightVp = Math.round(kbHeightPx / density);

    await this.panel.resize(d.width, kbHeightPx);
    this.lastLandscape = isLandscape;
    AppStorage.setOrCreate('gtv_isLandscape',   isLandscape);
    AppStorage.set('gtv_panelHeight',   kbHeightPx);
    AppStorage.set('gtv_panelHeightVp', kbHeightVp);
    AppStorage.setOrCreate('gtv_screenW', d.width);
    console.info(`[GoTiengViet] Panel: landscape=${isLandscape}, px=${kbHeightPx}, vp=${kbHeightVp}, density=${density}`);
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
        if (this.shouldReplaceComposingOnCommit(key) && this.currentComposing.length > 0) {
          this.inputClient.deleteForwardSync(this.currentComposing.length);
        }
        this.inputClient.insertTextSync(result.commitText);
        this.currentComposing = '';
      } else if (result.composingText.length > 0) {
        const previousLength = this.currentComposing.length;

        if (previousLength > 0) {
          this.inputClient.deleteForwardSync(previousLength);
        }
        this.inputClient.insertTextSync(result.composingText);
        this.currentComposing = result.composingText;
      } else {
        this.currentComposing = '';
      }
    } catch (err) {
      console.error('[GoTiengViet] handleVirtualKey error:', err);
    }

    this.publishComposition(result.composingText, result.candidates);
    AppStorage.set(KEY_IS_SHIFTED, this.imeManager.isShifted());
  }

  private shouldReplaceComposingOnCommit(key: string): boolean {
    if (key.length !== 1 || key === ' ') {
      return false;
    }
    return this.isWordChar(key);
  }

  private publishComposition(composingText: string, candidates: string[]): void {
    AppStorage.set(KEY_COMPOSING, composingText);
    AppStorage.set(KEY_CANDIDATES, this.buildCandidates(composingText, candidates));
  }

  private buildCandidates(composingText: string, engineCandidates: string[]): string[] {
    if (composingText.length === 0) {
      return [];
    }

    const result: string[] = [];
    this.addCandidate(result, composingText);

    for (const candidate of engineCandidates) {
      this.addCandidate(result, candidate);
    }

    const prefix = this.normalizeForCandidate(composingText);
    if (prefix.length >= 2) {
      for (const word of LOCAL_CANDIDATE_WORDS) {
        if (this.normalizeForCandidate(word).startsWith(prefix)) {
          this.addCandidate(result, this.matchCandidateCase(composingText, word));
        }
        if (result.length >= 6) {
          break;
        }
      }
    }

    return result.slice(0, 6);
  }

  private addCandidate(candidates: string[], value: string): void {
    if (value.length === 0 || candidates.includes(value)) {
      return;
    }
    candidates.push(value);
  }

  private matchCandidateCase(source: string, candidate: string): string {
    if (source.length === 0) {
      return candidate;
    }
    const first = source[0];
    if (first === first.toUpperCase() && first !== first.toLowerCase()) {
      return candidate.substring(0, 1).toUpperCase() + candidate.substring(1);
    }
    return candidate;
  }

  private normalizeForCandidate(value: string): string {
    let text = value.toLowerCase();
    text = text.replace(/[àáạảãâầấậẩẫăằắặẳẵ]/g, 'a');
    text = text.replace(/[èéẹẻẽêềếệểễ]/g, 'e');
    text = text.replace(/[ìíịỉĩ]/g, 'i');
    text = text.replace(/[òóọỏõôồốộổỗơờớợởỡ]/g, 'o');
    text = text.replace(/[ùúụủũưừứựửữ]/g, 'u');
    text = text.replace(/[ỳýỵỷỹ]/g, 'y');
    text = text.replace(/đ/g, 'd');
    return text;
  }

  private async commitCandidate(text: string): Promise<void> {
    if (!this.inputClient || text.length === 0) return;

    try {
      if (this.currentComposing.length > 0) {
        this.inputClient.deleteForwardSync(this.currentComposing.length);
      }
      this.inputClient.insertTextSync(text);
      this.currentComposing = '';
      this.imeManager.reset();
      AppStorage.set(KEY_COMPOSING, '');
      AppStorage.set(KEY_CANDIDATES, [] as string[]);
      AppStorage.set(KEY_IS_SHIFTED, this.imeManager.isShifted());
    } catch (err) {
      console.error('[GoTiengViet] commitCandidate error:', err);
    }
  }

  private isWordChar(ch: string): boolean {
    return /^[0-9A-Za-zÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐàáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ_]$/.test(ch);
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
