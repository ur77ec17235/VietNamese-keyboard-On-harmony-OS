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
import { ClipboardItem, ClipboardManager } from './ClipboardManager';
import { KeyboardBridge } from './KeyboardBridge';
import display from '@ohos.display';
import { pasteboard } from '@kit.BasicServicesKit';
import { PreferencesManager } from '../core/PreferencesManager';
import { DEFAULT_KEYBOARD_BG_COLOR, DEFAULT_KEYBOARD_DARK_MODE, DEFAULT_KEYBOARD_KEY_COLOR,
  DEFAULT_KEYBOARD_KEY_OPACITY, DEFAULT_KEYBOARD_OPACITY, GTV_BG_COLOR_KEY, GTV_BG_OPACITY_KEY,
  GTV_DARK_MODE_KEY, GTV_KEY_COLOR_KEY, GTV_KEY_OPACITY_KEY, GTV_SHOW_NUMBER_ROW_KEY } from '../ui/KeyboardTheme';
import { CORE_CANDIDATE_WORDS, EXTRA_CANDIDATE_WORDS } from '../dictionary/CandidateDictionary';


// AppStorage keys để sync state với UI
export const KEY_INPUT_MODE = 'gtv_inputMode';
export const KEY_COMPOSING = 'gtv_composingText';
export const KEY_CANDIDATES = 'gtv_candidates';
export const KEY_IS_SHIFTED = 'gtv_isShifted';
export const KEY_SHOW_CLIPBOARD = 'gtv_showClipboard';
export const KEY_CLIPBOARD_ITEMS = 'gtv_clipboardItems';
export const KEY_CLIPBOARD_STATUS = 'gtv_clipboardStatus';

const GTV_BUNDLE_NAME = 'com.example.gotiengviet';
const GTV_MAIN_ABILITY = 'StageAbility';

interface RankedCandidate {
  word: string;
  score: number;
}

export default class GoTiengVietService extends InputMethodExtensionAbility {
  private panel: inputMethodEngine.Panel | null = null;
  private inputClient: inputMethodEngine.InputClient | null = null;
  private kbController: inputMethodEngine.KeyboardController | null = null;
  private imeManager: InputMethodManager = new InputMethodManager();
  private clipboardMgr: ClipboardManager = new ClipboardManager();
  private clipboardItems: ClipboardItem[] = [];
  private clipboardListening: boolean = false;
  private clipboardStartTimer: number = -1;
  private clipboardUpdateListener = () => {
    this.refreshClipboardHistory(false).catch((err: Error) => {
      console.error('[GoTiengViet] clipboard update error:', err);
    });
  };
  private clipboardRefreshInFlight: boolean = false;
  private lastClipboardSignature: string = '';
  private readonly MAX_CLIPBOARD_ITEMS: number = 30;
  private currentComposing: string = '';
  private isShowing: boolean = false;
  private panelReady: boolean = false;
  private userRequestedHide: boolean = false;
  private lastLandscape: boolean = false;

  private async loadAppearanceSettings(forceRefresh: boolean = false): Promise<void> {
    await PreferencesManager.init(this.context, forceRefresh);
    const bgOpacity = await PreferencesManager.get(GTV_BG_OPACITY_KEY, DEFAULT_KEYBOARD_OPACITY) as number;
    const keyOpacity = await PreferencesManager.get(GTV_KEY_OPACITY_KEY, DEFAULT_KEYBOARD_KEY_OPACITY) as number;
    const showNumberRow = await PreferencesManager.get(GTV_SHOW_NUMBER_ROW_KEY, true) as boolean;
    const bgColor = await PreferencesManager.get(GTV_BG_COLOR_KEY, DEFAULT_KEYBOARD_BG_COLOR) as string;
    const keyColor = await PreferencesManager.get(GTV_KEY_COLOR_KEY, DEFAULT_KEYBOARD_KEY_COLOR) as string;
    const darkMode = await PreferencesManager.get(GTV_DARK_MODE_KEY, DEFAULT_KEYBOARD_DARK_MODE) as boolean;

    AppStorage.setOrCreate(GTV_BG_OPACITY_KEY, bgOpacity);
    AppStorage.setOrCreate(GTV_KEY_OPACITY_KEY, keyOpacity);
    AppStorage.setOrCreate(GTV_SHOW_NUMBER_ROW_KEY, showNumberRow);
    AppStorage.setOrCreate(GTV_BG_COLOR_KEY, bgColor);
    AppStorage.setOrCreate(GTV_KEY_COLOR_KEY, keyColor);
    AppStorage.setOrCreate(GTV_DARK_MODE_KEY, darkMode);
  }

  onCreate(want: Want): void {
    console.info('[GoTiengViet] Service onCreate');

    // Khởi tạo AppStorage defaults
    AppStorage.setOrCreate(KEY_INPUT_MODE, InputMode.TELEX);
    AppStorage.setOrCreate(KEY_COMPOSING, '');
    AppStorage.setOrCreate(KEY_CANDIDATES, [] as string[]);
    AppStorage.setOrCreate(KEY_IS_SHIFTED, false);
    AppStorage.setOrCreate(KEY_SHOW_CLIPBOARD, false);
    AppStorage.setOrCreate(KEY_CLIPBOARD_ITEMS, []);
    AppStorage.setOrCreate(KEY_CLIPBOARD_STATUS, '');

    // Khởi tạo Preferences và load cấu hình giao diện
    this.loadAppearanceSettings().catch((err: Error) => {
      console.error('[GoTiengViet] load appearance settings failed:', err.message);
    });

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

      // Reload settings every time keyboard opens (force refresh from disk)
      this.loadAppearanceSettings(true).catch((err: Error) => {
        console.error('[GoTiengViet] reload appearance settings failed:', err.message);
      });
      this.currentComposing = '';
      this.userRequestedHide = false;
      AppStorage.set(KEY_COMPOSING, '');
      AppStorage.set(KEY_CANDIDATES, [] as string[]);
      this.isShowing = true;
      this.startClipboardPolling();
    });

    ima.on('inputStop', () => {
      console.info('[GoTiengViet] inputStop');
      this.currentComposing = '';
      this.imeManager.reset();
      this.inputClient = null;
      this.kbController = null;
      this.isShowing = false;
      // this.stopClipboardPolling();
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
      this.loadAppearanceSettings(true).catch((err: Error) => {
        console.error('[GoTiengViet] keyboardShow appearance reload failed:', err.message);
      });
      this.startClipboardPolling();
      this.showKeyboard();
    });

    ima.on('keyboardHide', () => {
      console.info('[GoTiengViet] keyboardHide');
      this.isShowing = false;
      // this.stopClipboardPolling();
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

    // Đăng ký handler thay đổi theme từ Settings
    KeyboardBridge.registerThemeChangedHandler(() => {
      this.loadAppearanceSettings(true).catch((err: Error) => {
        console.error('Reload theme from settings failed:', err.message);
      });
    });

    // Shift
    KeyboardBridge.registerShiftHandler(() => {
      this.imeManager.toggleShift();
      AppStorage.set(KEY_IS_SHIFTED, this.imeManager.isShifted());
    });

    KeyboardBridge.registerClearShiftHandler(() => {
      this.imeManager.clearShift();
      AppStorage.set(KEY_IS_SHIFTED, this.imeManager.isShifted());
    });

    // Caps lock
    KeyboardBridge.registerCapsLockHandler(() => {
      this.imeManager.toggleCapsLock();
      AppStorage.set(KEY_IS_SHIFTED, this.imeManager.isShifted());
    });

    // Enter
    KeyboardBridge.registerEnterHandler(() => {
      this.handleEnter().catch((err: Error) => {
        console.error('[GoTiengViet] handleEnter bridge error:', err);
      });
    });

    // Chuyển mode gõ
    KeyboardBridge.registerModeHandler(() => {
      const newMode = this.imeManager.cycleMode();
      AppStorage.set(KEY_INPUT_MODE, newMode);
      this.imeManager.reset();
      this.currentComposing = '';
      AppStorage.set(KEY_COMPOSING, '');
      AppStorage.set(KEY_IS_SHIFTED, this.imeManager.isShifted());
    });

    KeyboardBridge.registerModeSelectHandler((mode: string) => {
      if (mode === InputMode.TELEX || mode === InputMode.TELEX_SIMPLE ||
        mode === InputMode.VNI || mode === InputMode.VNI_SIMPLE ||
        mode === InputMode.ENGLISH) {
        this.imeManager.setMode(mode as InputMode);
        AppStorage.set(KEY_INPUT_MODE, this.imeManager.getCurrentMode());
        this.imeManager.reset();
        this.currentComposing = '';
        AppStorage.set(KEY_COMPOSING, '');
        AppStorage.set(KEY_CANDIDATES, [] as string[]);
        AppStorage.set(KEY_IS_SHIFTED, this.imeManager.isShifted());
      }
    });

    // Hiện clipboard
    KeyboardBridge.registerClipboardHandler(async () => {
      await this.refreshSystemClipboardPreview();
      AppStorage.set(KEY_SHOW_CLIPBOARD, true);
    });

    // Người dùng chủ động đọc và dán system clipboard.
    KeyboardBridge.registerPasteSystemClipboardHandler(async () => {
      await this.pasteFromSystemClipboard();
    });

    KeyboardBridge.registerClearClipboardHistoryHandler(() => {
      this.clipboardItems = [];
      this.lastClipboardSignature = '';
      AppStorage.set(KEY_CLIPBOARD_ITEMS, []);
      AppStorage.set(KEY_CLIPBOARD_STATUS, 'Đã xóa danh sách hiển thị. Clipboard hệ thống không bị xóa.');
    });

    // Ẩn keyboard
    KeyboardBridge.registerHideHandler(() => {
      this.currentComposing = '';
      this.imeManager.reset();
      this.userRequestedHide = true;
      this.hideKeyboard();
    });

    // Mở app cấu hình chính từ taskbar bàn phím
    KeyboardBridge.registerOpenAppHandler(() => {
      this.hideKeyboard();
      this.openHostApp();
    });

    // Chọn candidate: thay thế phần composing đang hiển thị rồi commit candidate.
    KeyboardBridge.registerCandidateHandler((text: string) => {
      this.commitCandidate(text).catch((err: Error) => {
        console.error('[GoTiengViet] commit candidate bridge error:', err);
      });
    });

    // Dán từ clipboard
    KeyboardBridge.registerPasteHandler((text: string) => {
      this.pasteText(text).catch((err: Error) => {
        console.error('[GoTiengViet] paste text bridge error:', err);
      });
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
      ? Math.round(d.height * 0.62)
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

  private openHostApp(): void {
    const want: Want = {
      bundleName: GTV_BUNDLE_NAME,
      abilityName: GTV_MAIN_ABILITY
    } as Want;

    this.context.startAbility(want).catch((err: Error) => {
      console.error('[GoTiengViet] open host app error:', err);
    });
  }

  private hideKeyboard(): void {
    this.isShowing = false;
    // this.stopClipboardPolling();
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

    try {
      while (this.keyQueue.length > 0) {
        const key = this.keyQueue.shift();
        if (key) {
          await this.handleVirtualKey(key);
        }
      }
    } finally {
      this.isProcessingKey = false;
      if (this.keyQueue.length > 0) {
        this.processKeyQueue().catch((err: Error) => {
          console.error('[GoTiengViet] processKeyQueue drain error:', err);
        });
      }
    }
  }

  private async handleVirtualKey(key: string): Promise<void> {
    if (!this.inputClient) return;

    if (key === 'DeleteWord') {
      this.handleDeleteWord();
      return;
    }

    const result = this.imeManager.processInput(key);

    try {
      if (result.deleteCount > 0 && result.composingText.length === 0 && result.commitText.length === 0) {
        for (let i = 0; i < result.deleteCount; i++) {
          this.inputClient.deleteForward(1).catch((e: Error) => console.error('[GoTiengViet] deleteForward error', e));
        }
        this.currentComposing = '';
      } else if (result.commitText.length > 0) {
        if (this.shouldReplaceComposingOnCommit(key) && this.currentComposing.length > 0) {
          this.inputClient.deleteForward(this.currentComposing.length).catch((e: Error) => console.error('[GoTiengViet] deleteForward error', e));
        }
        this.inputClient.insertText(result.commitText).catch((e: Error) => console.error('[GoTiengViet] insertText error', e));
        this.currentComposing = '';
      } else if (result.composingText.length > 0) {
        const previousLength = this.currentComposing.length;

        if (previousLength > 0) {
          this.inputClient.deleteForward(previousLength).catch((e: Error) => console.error('[GoTiengViet] deleteForward error', e));
        }
        this.inputClient.insertText(result.composingText).catch((e: Error) => console.error('[GoTiengViet] insertText error', e));
        this.currentComposing = result.composingText;
      } else {
        this.currentComposing = '';
      }
    } catch (err) {
      console.error('[GoTiengViet] handleVirtualKey error:', err);
    }

    this.publishComposition(this.currentComposing, result.candidates);
    AppStorage.set(KEY_IS_SHIFTED, this.imeManager.isShifted());
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

    for (const candidate of engineCandidates) {
      this.addCandidate(result, candidate);
    }

    const ranked = this.searchLocalCandidates(composingText);
    for (const candidate of ranked) {
      this.addCandidate(result, this.matchCandidateCase(composingText, candidate.word));
      if (result.length >= 6) {
        break;
      }
    }

    if (result.length === 0) {
      this.addCandidate(result, composingText);
    }

    return result.slice(0, 6);
  }

  private searchLocalCandidates(input: string): RankedCandidate[] {
    const query = this.normalizeForCandidate(input);
    if (query.length < 2) {
      return [];
    }

    const ranked: RankedCandidate[] = [];
    const seen: string[] = [];
    for (const entry of CORE_CANDIDATE_WORDS) {
      const normalized = this.normalizeForCandidate(entry.word);
      const score = this.scoreCandidate(query, normalized, entry.weight);
      if (score <= 0 || seen.includes(entry.word)) {
        continue;
      }
      seen.push(entry.word);
      ranked.push({ word: entry.word, score: score });
    }

    let fallbackWeight = 500;
    for (const word of EXTRA_CANDIDATE_WORDS) {
      const normalized = this.normalizeForCandidate(word);
      const score = this.scoreCandidate(query, normalized, fallbackWeight);
      if (score > 0 && !seen.includes(word)) {
        seen.push(word);
        ranked.push({ word: word, score: score });
      }
      fallbackWeight--;
    }

    ranked.sort((a: RankedCandidate, b: RankedCandidate): number => {
      if (b.score !== a.score) {
        return b.score - a.score;
      }
      return a.word.length - b.word.length;
    });
    return ranked;
  }

  private scoreCandidate(query: string, candidate: string, weight: number): number {
    if (candidate === query) {
      return 9000 + weight;
    }

    if (candidate.startsWith(query)) {
      return 7000 + weight - (candidate.length - query.length);
    }

    const firstWord = candidate.split(' ')[0];
    if (firstWord.startsWith(query)) {
      return 6500 + weight - (firstWord.length - query.length);
    }

    const sameInitial = query[0] === candidate[0];
    if (sameInitial && query.length >= 3) {
      const prefix = candidate.substring(0, Math.min(candidate.length, query.length));
      const prefixDistance = this.editDistance(query, prefix, 2);
      if (prefixDistance === 1) {
        return 5000 + weight - candidate.length;
      }
      if (query.length >= 4 && prefixDistance === 2) {
        return 4200 + weight - candidate.length;
      }

      const fullDistance = this.editDistance(query, candidate, 2);
      if (fullDistance === 1) {
        return 4700 + weight - candidate.length;
      }
      if (query.length >= 4 && fullDistance === 2) {
        return 3900 + weight - candidate.length;
      }
    }

    if (query.length >= 3 && candidate.includes(query)) {
      return 2500 + weight - candidate.indexOf(query);
    }

    return 0;
  }

  private editDistance(a: string, b: string, limit: number): number {
    if (Math.abs(a.length - b.length) > limit) {
      return limit + 1;
    }

    const dp: number[][] = [];
    for (let i = 0; i <= a.length; i++) {
      dp[i] = [];
      dp[i][0] = i;
    }
    for (let j = 0; j <= b.length; j++) {
      dp[0][j] = j;
    }

    for (let i = 1; i <= a.length; i++) {
      let rowMin = limit + 1;
      for (let j = 1; j <= b.length; j++) {
        const cost = a[i - 1] === b[j - 1] ? 0 : 1;
        dp[i][j] = Math.min(
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost
        );

        if (i > 1 && j > 1 && a[i - 1] === b[j - 2] && a[i - 2] === b[j - 1]) {
          dp[i][j] = Math.min(dp[i][j], dp[i - 2][j - 2] + 1);
        }

        rowMin = Math.min(rowMin, dp[i][j]);
      }

      if (rowMin > limit) {
        return limit + 1;
      }
    }

    return dp[a.length][b.length];
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
        this.inputClient.deleteForward(this.currentComposing.length).catch((e: Error) => console.error('[GoTiengViet] deleteForward error', e));
      }
      this.inputClient.insertText(text).catch((e: Error) => console.error('[GoTiengViet] insertText error', e));
      this.currentComposing = '';
      this.imeManager.reset();
      AppStorage.set(KEY_COMPOSING, '');
      AppStorage.set(KEY_CANDIDATES, [] as string[]);
      AppStorage.set(KEY_IS_SHIFTED, this.imeManager.isShifted());
    } catch (err) {
      console.error('[GoTiengViet] commitCandidate error:', err);
    }
  }

  private shouldReplaceComposingOnCommit(key: string): boolean {
    if (key.length !== 1 || key === ' ') {
      return false;
    }
    return this.isWordChar(key);
  }

  private handleDeleteWord(): void {
    if (!this.inputClient) return;

    try {
      if (this.currentComposing.length > 0) {
        this.inputClient.deleteForward(this.currentComposing.length).catch((e: Error) => console.error('[GoTiengViet] deleteForward error', e));
        this.currentComposing = '';
        this.imeManager.reset();
        AppStorage.set(KEY_COMPOSING, '');
        AppStorage.set(KEY_CANDIDATES, [] as string[]);
        return;
      }

      this.inputClient.getForward(64).then((beforeCursor: string) => {
        if (!this.inputClient) return;
        const deleteCount = this.getDeleteWordCount(beforeCursor);
        this.inputClient.deleteForward(deleteCount > 0 ? deleteCount : 1).catch((e: Error) => console.error('[GoTiengViet] deleteForward error', e));
      }).catch((e: Error) => console.error('[GoTiengViet] getForward error', e));

      this.imeManager.reset();
      AppStorage.set(KEY_COMPOSING, '');
      AppStorage.set(KEY_CANDIDATES, [] as string[]);
    } catch (err) {
      console.error('[GoTiengViet] handleDeleteWord error:', err);
    }
  }

  private getDeleteWordCount(text: string): number {
    if (text.length === 0) return 1;

    let i = text.length - 1;
    if (this.isWhitespace(text[i])) {
      while (i >= 0 && this.isWhitespace(text[i])) {
        i--;
      }
      return text.length - 1 - i;
    }

    if (!this.isWordChar(text[i])) {
      return 1;
    }

    while (i >= 0 && this.isWordChar(text[i])) {
      i--;
    }
    return text.length - 1 - i;
  }

  private isWhitespace(ch: string): boolean {
    return ch === ' ' || ch === '\n' || ch === '\t' || ch === '\r';
  }

  private isWordChar(ch: string): boolean {
    return /^[0-9A-Za-zÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐàáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ_]$/.test(ch);
  }

  private async handleEnter(): Promise<void> {
    if (!this.inputClient) return;
    try {
      this.inputClient.insertText('\n').catch((e: Error) => console.error('[GoTiengViet] insertText error', e));
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
      this.inputClient.insertText(text).catch((e: Error) => console.error('[GoTiengViet] insertText error', e));
      this.currentComposing = '';
      this.imeManager.reset();
      AppStorage.set(KEY_COMPOSING, '');
      AppStorage.set(KEY_CANDIDATES, [] as string[]);
      AppStorage.set(KEY_SHOW_CLIPBOARD, false);
    } catch (err) {
      console.error('[GoTiengViet] pasteText error:', err);
    }
  }

  private async refreshSystemClipboardPreview(): Promise<void> {
    await this.refreshClipboardHistory(false);
  }

  private startClipboardPolling(): void {
    if (this.clipboardListening || this.clipboardStartTimer !== -1) {
      return;
    }
    this.clipboardStartTimer = setTimeout(() => {
      this.clipboardStartTimer = -1;
      try {
        if (!this.clipboardListening) {
          pasteboard.getSystemPasteboard().on('update', this.clipboardUpdateListener);
          this.clipboardListening = true;
        }
      } catch (e) {
        console.error('[GoTiengViet] failed to listen pasteboard update', e);
      }
    }, 1500) ;
  }

  private stopClipboardPolling(): void {
    if (this.clipboardStartTimer !== -1) {
      clearTimeout(this.clipboardStartTimer);
      this.clipboardStartTimer = -1;
    }
    if (!this.clipboardListening) {
      return;
    }
    try {
      pasteboard.getSystemPasteboard().off('update', this.clipboardUpdateListener);
    } catch (e) {
      console.error('[GoTiengViet] failed to unlisten pasteboard update', e);
    }
    this.clipboardListening = false;
  }

  private async refreshClipboardHistory(forceStatus: boolean): Promise<void> {
    if (this.clipboardRefreshInFlight) {
      return;
    }
    this.clipboardRefreshInFlight = true;
    try {
      const result = await this.clipboardMgr.readTextItems();
      if (result.items.length === 0) {
        if (forceStatus || this.clipboardItems.length === 0) {
          AppStorage.set(KEY_CLIPBOARD_STATUS, result.message);
        }
        // AppStorage.set(KEY_CLIPBOARD_ITEMS, this.clipboardItems);
        return;
      }

      const signature = result.items.map((item: ClipboardItem) => item.text).join('\u0001');
      if (signature === this.lastClipboardSignature && !forceStatus) {
        return;
      }

      this.lastClipboardSignature = signature;
      this.clipboardItems = this.mergeClipboardItems(result.items, this.clipboardItems);
      AppStorage.set(KEY_CLIPBOARD_ITEMS, this.clipboardItems);
      AppStorage.set(KEY_CLIPBOARD_STATUS, result.message);
    } catch (err) {
      console.error('[GoTiengViet] refreshClipboardHistory error:', err);
      AppStorage.set(KEY_CLIPBOARD_ITEMS, this.clipboardItems);
      AppStorage.set(KEY_CLIPBOARD_STATUS, 'Không đọc được clipboard.');
    } finally {
      this.clipboardRefreshInFlight = false;
    }
  }

  private mergeClipboardItems(incoming: ClipboardItem[], current: ClipboardItem[]): ClipboardItem[] {
    const merged: ClipboardItem[] = [];
    const seen: string[] = [];

    for (const item of incoming) {
      this.pushUniqueClipboardItem(merged, seen, item);
    }

    for (const item of current) {
      this.pushUniqueClipboardItem(merged, seen, item);
    }

    return merged.slice(0, this.MAX_CLIPBOARD_ITEMS);
  }

  private pushUniqueClipboardItem(target: ClipboardItem[], seen: string[], item: ClipboardItem): void {
    const text = item.text.trim();
    if (text.length === 0 || seen.includes(text)) {
      return;
    }
    seen.push(text);
    target.push({
      kind: item.kind,
      text: text,
      timestamp: item.timestamp
    });
  }

  private async pasteFromSystemClipboard(): Promise<void> {
    try {
      await this.refreshClipboardHistory(true);
      if (this.clipboardItems.length > 0) {
        await this.pasteText(this.clipboardItems[0].text);
      }
    } catch (err) {
      console.error('[GoTiengViet] pasteFromSystemClipboard error:', err);
      AppStorage.set(KEY_CLIPBOARD_STATUS, 'Không dán được clipboard.');
    }
  }

  onDestroy(): void {
    console.info('[GoTiengViet] Service onDestroy');
    this.stopClipboardPolling();
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
