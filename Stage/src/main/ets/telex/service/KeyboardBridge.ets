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
  private onCapsLockHandler: SimpleEventHandler | null = null;
  private onEnterHandler: SimpleEventHandler | null = null;
  private onModeHandler: SimpleEventHandler | null = null;
  private onClipboardHandler: SimpleEventHandler | null = null;
  private onHideHandler: SimpleEventHandler | null = null;
  private onCandidateHandler: KeyEventHandler | null = null;
  private onPasteHandler: PasteTextHandler | null = null;

  registerKeyHandler(handler: KeyEventHandler): void {
    this.onKeyHandler = handler;
  }

  registerShiftHandler(handler: SimpleEventHandler): void {
    this.onShiftHandler = handler;
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

  registerClipboardHandler(handler: SimpleEventHandler): void {
    this.onClipboardHandler = handler;
  }

  registerHideHandler(handler: SimpleEventHandler): void {
    this.onHideHandler = handler;
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

  sendClipboard(): void {
    if (this.onClipboardHandler) {
      this.onClipboardHandler();
    }
  }

  sendHide(): void {
    if (this.onHideHandler) {
      this.onHideHandler();
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
    this.onCapsLockHandler = null;
    this.onEnterHandler = null;
    this.onModeHandler = null;
    this.onClipboardHandler = null;
    this.onHideHandler = null;
    this.onCandidateHandler = null;
    this.onPasteHandler = null;
  }
}

export const KeyboardBridge = new KeyboardBridgeImpl();
