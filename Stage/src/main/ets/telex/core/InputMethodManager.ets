/**
 * InputMethodManager.ets
 * Quản lý chuyển đổi giữa các phương pháp gõ (Telex / VNI / English)
 */

import { InputEngineBase, InputMode, ProcessResult } from './InputEngineBase';
import { TelexEngine } from './TelexEngine';
import { VniEngine } from './VniEngine';

// Engine tiếng Anh đơn giản - pass-through
class EnglishEngine implements InputEngineBase {
  readonly name: string = 'English';
  private buffer: string = '';

  processInput(key: string): ProcessResult {
    if (key === 'Backspace' || key === 'Delete') {
      if (this.buffer.length > 0) {
        this.buffer = this.buffer.slice(0, -1);
        return { commitText: '', composingText: this.buffer, deleteCount: 1, candidates: [], committed: false };
      }
      return { commitText: '', composingText: '', deleteCount: 1, candidates: [], committed: false };
    }
    if (key === ' ' || key === '\n' || key === 'Enter') {
      this.buffer = '';
      return { commitText: key === 'Enter' ? '\n' : ' ', composingText: '', deleteCount: 0, candidates: [], committed: true };
    }
    // Đối với tiếng Anh, commit ngay lập tức
    this.buffer = '';
    return { commitText: key, composingText: '', deleteCount: 0, candidates: [], committed: true };
  }

  reset(): void { this.buffer = ''; }
  getComposingText(): string { return this.buffer; }
}

export class InputMethodManager {
  private engines: Map<InputMode, InputEngineBase>;
  private currentMode: InputMode;
  private isShiftActive: boolean = false;
  private isCapsLock: boolean = false;

  constructor() {
    this.engines = new Map<InputMode, InputEngineBase>();
    this.engines.set(InputMode.TELEX, new TelexEngine(true));
    this.engines.set(InputMode.TELEX_SIMPLE, new TelexEngine(false));
    this.engines.set(InputMode.VNI, new VniEngine(true));
    this.engines.set(InputMode.VNI_SIMPLE, new VniEngine(false));
    this.engines.set(InputMode.ENGLISH, new EnglishEngine());
    this.currentMode = InputMode.TELEX;
  }

  getCurrentMode(): InputMode {
    return this.currentMode;
  }

  setMode(mode: InputMode): void {
    if (this.currentMode !== mode) {
      this.getCurrentEngine().reset();
      this.currentMode = mode;
    }
  }

  cycleMode(): InputMode {
    const modes = [InputMode.TELEX, InputMode.TELEX_SIMPLE, InputMode.VNI, InputMode.VNI_SIMPLE, InputMode.ENGLISH];
    const idx = modes.indexOf(this.currentMode);
    const next = modes[(idx + 1) % modes.length];
    this.setMode(next);
    return next;
  }

  getModeName(): string {
    switch (this.currentMode) {
      case InputMode.TELEX: return 'VI-Telex Full';
      case InputMode.TELEX_SIMPLE: return 'VI-Telex Simple';
      case InputMode.VNI: return 'VI-VNI Full';
      case InputMode.VNI_SIMPLE: return 'VI-VNI Simple';
      case InputMode.ENGLISH: return 'EN';
      default: return 'VI';
    }
  }

  processInput(key: string): ProcessResult {
    let processKey = key;

    // Áp dụng shift/caps
    if (key.length === 1) {
      const code = key.charCodeAt(0);
      const isLetter = (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
      if (isLetter) {
        const shouldUppercase = this.isShiftActive !== this.isCapsLock; // XOR
        processKey = shouldUppercase ? key.toUpperCase() : key.toLowerCase();
        if (this.isShiftActive) {
          this.isShiftActive = false; // Reset shift sau khi dùng
        }
      }
    }

    return this.getCurrentEngine().processInput(processKey);
  }

  toggleShift(): void {
    this.isShiftActive = !this.isShiftActive;
  }

  toggleCapsLock(): void {
    this.isCapsLock = !this.isCapsLock;
    this.isShiftActive = false;
  }

  clearShift(): void {
    this.isShiftActive = false;
  }

  isShifted(): boolean {
    return this.isShiftActive !== this.isCapsLock;
  }

  reset(): void {
    this.getCurrentEngine().reset();
  }

  getComposingText(): string {
    return this.getCurrentEngine().getComposingText();
  }

  private getCurrentEngine(): InputEngineBase {
    return this.engines.get(this.currentMode)!;
  }
}
