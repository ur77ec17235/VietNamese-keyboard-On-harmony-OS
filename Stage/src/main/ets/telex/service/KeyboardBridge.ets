/**
 * KeyboardBridge.ets
 * Cầu nối giữa bàn phím UI (KeyboardPage) và GoTiengVietService
 * Sử dụng pattern singleton + callback để truyền sự kiện
 */

export type KeyEventHandler = (key: string) => void;
export type SimpleEventHandler = () => void;
export type PasteTextHandler = (text: string) => void;

class KeyboardBridgeImpl {
  private onKeyHandler: KeyEventHandler | null = null;
  private onShiftHandler: SimpleEventHandler | null = null;
  private onClearShiftHandler: SimpleEventHandler | null = null;
  private onCapsLockHandler: SimpleEventHandler | null = null;
  private onEnterHandler: SimpleEventHandler | null = null;
  private onModeHandler: SimpleEventHandler | null = null;
  private onModeSelectHandler: KeyEventHandler | null = null;
  private onClipboardHandler: SimpleEventHandler | null = null;
  private onPasteSystemClipboardHandler: SimpleEventHandler | null = null;
  private onClearClipboardHistoryHandler: SimpleEventHandler | null = null;
  private onHideHandler: SimpleEventHandler | null = null;
  private onOpenAppHandler: SimpleEventHandler | null = null;
  private onCandidateHandler: KeyEventHandler | null = null;
  private onPasteHandler: PasteTextHandler | null = null;
  private onThemeChangedHandler: SimpleEventHandler | null = null;

  registerThemeChangedHandler(handler: SimpleEventHandler): void {
    this.onThemeChangedHandler = handler;
  }

  sendThemeChanged(): void {
    this.onThemeChangedHandler?.();
  }

  registerKeyHandler(handler: KeyEventHandler): void {
    this.onKeyHandler = handler;
  }

  registerShiftHandler(handler: SimpleEventHandler): void {
    this.onShiftHandler = handler;
  }

  registerClearShiftHandler(handler: SimpleEventHandler): void {
    this.onClearShiftHandler = handler;
  }

  registerCapsLockHandler(handler: SimpleEventHandler): void {
    this.onCapsLockHandler = handler;
  }

  registerEnterHandler(handler: SimpleEventHandler): void {
    this.onEnterHandler = handler;
  }

  registerModeHandler(handler: SimpleEventHandler): void {
    this.onModeHandler = handler;
  }

  registerModeSelectHandler(handler: KeyEventHandler): void {
    this.onModeSelectHandler = handler;
  }

  registerClipboardHandler(handler: SimpleEventHandler): void {
    this.onClipboardHandler = handler;
  }

  registerPasteSystemClipboardHandler(handler: SimpleEventHandler): void {
    this.onPasteSystemClipboardHandler = handler;
  }

  registerClearClipboardHistoryHandler(handler: SimpleEventHandler): void {
    this.onClearClipboardHistoryHandler = handler;
  }

  registerHideHandler(handler: SimpleEventHandler): void {
    this.onHideHandler = handler;
  }

  registerOpenAppHandler(handler: SimpleEventHandler): void {
    this.onOpenAppHandler = handler;
  }

  registerCandidateHandler(handler: KeyEventHandler): void {
    this.onCandidateHandler = handler;
  }

  registerPasteHandler(handler: PasteTextHandler): void {
    this.onPasteHandler = handler;
  }

  sendKey(key: string): void {
    if (this.onKeyHandler) {
      this.onKeyHandler(key);
    }
  }

  sendShift(): void {
    if (this.onShiftHandler) {
      this.onShiftHandler();
    }
  }

  sendClearShift(): void {
    if (this.onClearShiftHandler) {
      this.onClearShiftHandler();
    }
  }

  sendCapsLock(): void {
    if (this.onCapsLockHandler) {
      this.onCapsLockHandler();
    }
  }

  sendEnter(): void {
    if (this.onEnterHandler) {
      this.onEnterHandler();
    }
  }

  sendModeSwitch(): void {
    if (this.onModeHandler) {
      this.onModeHandler();
    }
  }

  sendModeSelect(mode: string): void {
    if (this.onModeSelectHandler) {
      this.onModeSelectHandler(mode);
    }
  }

  sendClipboard(): void {
    if (this.onClipboardHandler) {
      this.onClipboardHandler();
    }
  }

  sendPasteSystemClipboard(): void {
    if (this.onPasteSystemClipboardHandler) {
      this.onPasteSystemClipboardHandler();
    }
  }

  sendClearClipboardHistory(): void {
    if (this.onClearClipboardHistoryHandler) {
      this.onClearClipboardHistoryHandler();
    }
  }

  sendHide(): void {
    if (this.onHideHandler) {
      this.onHideHandler();
    }
  }

  sendOpenApp(): void {
    if (this.onOpenAppHandler) {
      this.onOpenAppHandler();
    }
  }

  sendCandidate(text: string): void {
    if (this.onCandidateHandler) {
      this.onCandidateHandler(text);
    }
  }

  sendPasteText(text: string): void {
    if (this.onPasteHandler) {
      this.onPasteHandler(text);
    }
  }

  clearHandlers(): void {
    this.onKeyHandler = null;
    this.onShiftHandler = null;
    this.onClearShiftHandler = null;
    this.onCapsLockHandler = null;
    this.onEnterHandler = null;
    this.onModeHandler = null;
    this.onModeSelectHandler = null;
    this.onClipboardHandler = null;
    this.onPasteSystemClipboardHandler = null;
    this.onClearClipboardHistoryHandler = null;
    this.onHideHandler = null;
    this.onOpenAppHandler = null;
    this.onCandidateHandler = null;
    this.onPasteHandler = null;
    this.onThemeChangedHandler = null;
  }
}

export const KeyboardBridge = new KeyboardBridgeImpl();
