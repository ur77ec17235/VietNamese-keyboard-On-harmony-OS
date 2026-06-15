/**
 * VniEngine.ets
 * Engine gõ tiếng Việt theo phương pháp VNI
 *
 * VNI: 6→â/ô, 7→ơ, 8→ă, 9→ư, 0→đ, số 1-5 = dấu thanh
 */

import { InputEngineBase, ProcessResult } from './InputEngineBase';

// Bảng nguyên âm tiếng Việt
const VOWEL_TABLE: Map<string, string[]> = new Map<string, string[]>();
VOWEL_TABLE.set('a', ['a', 'á', 'à', 'ả', 'ã', 'ạ']);
VOWEL_TABLE.set('â', ['â', 'ấ', 'ầ', 'ẩ', 'ẫ', 'ậ']);
VOWEL_TABLE.set('ă', ['ă', 'ắ', 'ằ', 'ẳ', 'ẵ', 'ặ']);
VOWEL_TABLE.set('e', ['e', 'é', 'è', 'ẻ', 'ẽ', 'ẹ']);
VOWEL_TABLE.set('ê', ['ê', 'ế', 'ề', 'ể', 'ễ', 'ệ']);
VOWEL_TABLE.set('i', ['i', 'í', 'ì', 'ỉ', 'ĩ', 'ị']);
VOWEL_TABLE.set('o', ['o', 'ó', 'ò', 'ỏ', 'õ', 'ọ']);
VOWEL_TABLE.set('ô', ['ô', 'ố', 'ồ', 'ổ', 'ỗ', 'ộ']);
VOWEL_TABLE.set('ơ', ['ơ', 'ớ', 'ờ', 'ở', 'ỡ', 'ợ']);
VOWEL_TABLE.set('u', ['u', 'ú', 'ù', 'ủ', 'ũ', 'ụ']);
VOWEL_TABLE.set('ư', ['ư', 'ứ', 'ừ', 'ử', 'ữ', 'ự']);
VOWEL_TABLE.set('y', ['y', 'ý', 'ỳ', 'ỷ', 'ỹ', 'ỵ']);

// VNI tone keys (1-5) → dấu thanh (index 1-5)
const VNI_TONE: Map<string, number> = new Map<string, number>();
VNI_TONE.set('1', 1);
VNI_TONE.set('2', 2);
VNI_TONE.set('3', 3);
VNI_TONE.set('4', 4);
VNI_TONE.set('5', 5);

// VowelMod dùng class để ArkTS có thể type-check object literals
class VowelMod {
  targets: string[];
  result: string;
  constructor(targets: string[], result: string) {
    this.targets = targets;
    this.result = result;
  }
}

// VNI modifier keys: số → biến đổi nguyên âm
const VNI_VOWEL_MOD: Map<string, VowelMod[]> = new Map<string, VowelMod[]>();
VNI_VOWEL_MOD.set('6', [
  new VowelMod(['a'], 'â'),
  new VowelMod(['o'], 'ô'),
  new VowelMod(['â'], 'a'),
  new VowelMod(['ô'], 'o'),
]);
VNI_VOWEL_MOD.set('7', [
  new VowelMod(['o'], 'ơ'),
  new VowelMod(['ơ'], 'o'),
]);
VNI_VOWEL_MOD.set('8', [
  new VowelMod(['a'], 'ă'),
  new VowelMod(['ă'], 'a'),
]);
VNI_VOWEL_MOD.set('9', [
  new VowelMod(['u'], 'ư'),
  new VowelMod(['ư'], 'u'),
]);

function getBaseVowel(ch: string): string {
  for (const base of VOWEL_TABLE.keys()) {
    const forms = VOWEL_TABLE.get(base) as string[];
    if (forms.includes(ch.toLowerCase())) return base;
  }
  return ch.toLowerCase();
}

function isBaseVowel(ch: string): boolean {
  return ['a', 'â', 'ă', 'e', 'ê', 'i', 'o', 'ô', 'ơ', 'u', 'ư', 'y'].includes(ch.toLowerCase());
}

function applyTone(vowel: string, toneIdx: number): string {
  const base = getBaseVowel(vowel);
  const isUpper = vowel === vowel.toUpperCase() && vowel !== vowel.toLowerCase();
  const forms = VOWEL_TABLE.get(base);
  if (!forms) return vowel;
  const result = forms[toneIdx] || vowel;
  return isUpper ? result.toUpperCase() : result;
}

function getCurrentTone(ch: string): number {
  const lower = ch.toLowerCase();
  for (const base of VOWEL_TABLE.keys()) {
    const forms = VOWEL_TABLE.get(base) as string[];
    const idx = forms.indexOf(lower);
    if (idx > 0) return idx;
  }
  return 0;
}

export class VniEngine implements InputEngineBase {
  readonly name: string = 'VNI';
  private buffer: string = '';

  processInput(key: string): ProcessResult {
    // Delete / Backspace
    if (key === 'Backspace' || key === 'Delete') {
      if (this.buffer.length > 0) {
        this.buffer = this.buffer.slice(0, -1);
        return { commitText: '', composingText: this.buffer, deleteCount: 0, candidates: [], committed: false };
      }
      return { commitText: '', composingText: '', deleteCount: 1, candidates: [], committed: false };
    }

    // Space / Enter - chỉ chèn dấu phân cách
    if (key === ' ' || key === '\n' || key === 'Enter') {
      const suffix = key === 'Enter' ? '\n' : ' ';
      this.reset();
      return { commitText: suffix, composingText: '', deleteCount: 0, candidates: [], committed: true };
    }

    // Ký tự không phải chữ hoặc số VNI - chỉ chèn ký tự đó
    if (!this.isVniKey(key)) {
      this.reset();
      return { commitText: key, composingText: '', deleteCount: 0, candidates: [], committed: true };
    }

    // Xử lý số 0 → đ
    if (key === '0') {
      if (this.buffer.endsWith('d') || this.buffer.endsWith('D')) {
        const isUpper = this.buffer.slice(-1) === 'D';
        this.buffer = this.buffer.slice(0, -1) + (isUpper ? 'Đ' : 'đ');
      } else if (this.buffer.endsWith('đ') || this.buffer.endsWith('Đ')) {
        const isUpper = this.buffer.slice(-1) === 'Đ';
        this.buffer = this.buffer.slice(0, -1) + (isUpper ? 'D' : 'd');
      } else {
        this.buffer += key;
      }
      return this.buildResult();
    }

    // Xử lý dấu thanh (1-5)
    if (VNI_TONE.has(key)) {
      const toneIdx = VNI_TONE.get(key) as number;
      const result = this.applyToneToBuffer(toneIdx);
      if (result !== null) {
        this.buffer = result;
      } else {
        this.buffer += key;
      }
      return this.buildResult();
    }

    // Xử lý nguyên âm modifier (6-9)
    if (VNI_VOWEL_MOD.has(key)) {
      const mods = VNI_VOWEL_MOD.get(key) as VowelMod[];
      let applied = false;
      // Tìm nguyên âm trong buffer để biến đổi (từ cuối về đầu)
      let i = this.buffer.length - 1;
      while (i >= 0 && !applied) {
        const ch = this.buffer[i];
        const chLower = ch.toLowerCase();
        const chBase = getBaseVowel(chLower);
        let j = 0;
        while (j < mods.length && !applied) {
          const mod = mods[j];
          if (mod.targets.includes(chLower) || mod.targets.includes(chBase)) {
            const isUpper = ch === ch.toUpperCase() && ch !== ch.toLowerCase();
            const newCh = isUpper ? mod.result.toUpperCase() : mod.result;
            this.buffer = this.buffer.substring(0, i) + newCh + this.buffer.substring(i + 1);
            applied = true;
          }
          j++;
        }
        i--;
      }
      if (!applied) {
        this.buffer += key;
      }
      return this.buildResult();
    }

    // Ký tự chữ thường
    this.buffer += key;
    return this.buildResult();
  }

  private applyToneToBuffer(toneIdx: number): string | null {
    const pos = this.findTonePosition(this.buffer);
    if (pos < 0) return null;

    const ch = this.buffer[pos];
    const currentTone = getCurrentTone(ch);

    if (currentTone === toneIdx) {
      // Đã có dấu → escape về không dấu
      const base = getBaseVowel(ch);
      const forms = VOWEL_TABLE.get(base);
      if (forms) {
        const isUpper = ch === ch.toUpperCase() && ch !== ch.toLowerCase();
        return this.buffer.substring(0, pos) + (isUpper ? forms[0].toUpperCase() : forms[0]) + this.buffer.substring(pos + 1);
      }
    }
    return this.buffer.substring(0, pos) + applyTone(ch, toneIdx) + this.buffer.substring(pos + 1);
  }

  private findTonePosition(word: string): number {
    const lower = word.toLowerCase();
    const vowelPositions: number[] = [];
    for (let i = 0; i < lower.length; i++) {
      if (isBaseVowel(getBaseVowel(lower[i]))) {
        vowelPositions.push(i);
      }
    }
    if (vowelPositions.length === 0) return -1;
    if (vowelPositions.length === 1) return vowelPositions[0];

    const lastChar = lower[lower.length - 1];
    const hasEndConsonant = !isBaseVowel(getBaseVowel(lastChar)) && lastChar !== 'đ';
    if (hasEndConsonant) {
      return vowelPositions[vowelPositions.length - 1];
    }
    if (vowelPositions.length >= 2) return vowelPositions[1];
    return vowelPositions[vowelPositions.length - 1];
  }

  private isVniKey(key: string): boolean {
    if (key.length !== 1) return false;
    const code = key.charCodeAt(0);
    if ((code >= 65 && code <= 90) || (code >= 97 && code <= 122)) return true;
    if (code >= 48 && code <= 57) return true;
    return false;
  }

  private buildResult(): ProcessResult {
    return {
      commitText: '',
      composingText: this.buffer,
      deleteCount: 0,
      candidates: [],
      committed: false
    };
  }

  reset(): void {
    this.buffer = '';
  }

  getComposingText(): string {
    return this.buffer;
  }
}
