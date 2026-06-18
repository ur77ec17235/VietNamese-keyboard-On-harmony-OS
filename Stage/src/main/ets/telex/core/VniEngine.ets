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
  new VowelMod(['e'], 'ê'),
  new VowelMod(['o'], 'ô'),
  new VowelMod(['â'], 'a'),
  new VowelMod(['ê'], 'e'),
  new VowelMod(['ô'], 'o'),
]);
VNI_VOWEL_MOD.set('7', [
  new VowelMod(['o'], 'ơ'),
  new VowelMod(['ơ'], 'o'),
  new VowelMod(['u'], 'ư'),
  new VowelMod(['ư'], 'u'),
]);
VNI_VOWEL_MOD.set('8', [
  new VowelMod(['a'], 'ă'),
  new VowelMod(['ă'], 'a'),
]);
// VNI_VOWEL_MOD.set('9', [
//   new VowelMod(['d'], 'đ'),
//   new VowelMod(['đ'], 'd'),
// ]);

const FINAL_CONSONANTS: string[] = ['ng', 'nh', 'ch', 'n', 'm', 't', 'c', 'p', 'g', 'k'];

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

function applyVowelBase(vowel: string, newBase: string): string {
  const toneIdx = getCurrentTone(vowel);
  const isUpper = vowel === vowel.toUpperCase() && vowel !== vowel.toLowerCase();
  let result = newBase;
  if (toneIdx > 0) {
    const forms = VOWEL_TABLE.get(newBase);
    if (forms) {
      result = forms[toneIdx] || newBase;
    }
  }
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
  readonly name: string;
  private fullInput: boolean;
  private buffer: string = '';

  constructor(fullInput: boolean = true) {
    this.fullInput = fullInput;
    this.name = fullInput ? 'VNI Full' : 'VNI Simple';
  }

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

    // Xử lý số 9 → đ
    if (key === '9') {
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
      const result = this.canApplyToneKey(key) ? this.applyToneToBuffer(toneIdx) : null;
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
      let applied = this.applyVowelModifier(mods, this.fullInput);
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
    const toneKey = this.getToneKey(toneIdx);
    if (toneKey.length > 0 && this.buffer.endsWith(toneKey)) {
      const stem = this.buffer.substring(0, this.buffer.length - 1);
      const restored = this.applyToneToWord(stem, toneIdx, false);
      if (restored !== null) {
        return restored;
      }
    }

    return this.applyToneToWord(this.buffer, toneIdx, true);
  }

  private applyVowelModifier(mods: VowelMod[], allowSeparatedFinal: boolean): boolean {
    let i = this.buffer.length - 1;
    if (allowSeparatedFinal) {
      const finalStart = this.getFinalConsonantStart(this.buffer);
      if (finalStart >= 0) {
        i = finalStart - 1;
      }
    }

    while (i >= 0) {
      const ch = this.buffer[i];
      const chBase = getBaseVowel(ch);
      let j = 0;
      while (j < mods.length) {
        const mod = mods[j];
        if (mod.targets.includes(chBase)) {
          this.buffer = this.buffer.substring(0, i) + applyVowelBase(ch, mod.result) + this.buffer.substring(i + 1);
          return true;
        }
        j++;
      }

      if (allowSeparatedFinal && !isBaseVowel(chBase)) break;
      i--;
    }
    return false;
  }

  private getFinalConsonantStart(word: string): number {
    const lower = word.toLowerCase();
    for (const finalConsonant of FINAL_CONSONANTS) {
      if (lower.endsWith(finalConsonant) && lower.length > finalConsonant.length) {
        return lower.length - finalConsonant.length;
      }
    }
    return -1;
  }

  private canApplyToneKey(toneKey: string): boolean {
    if (this.fullInput) return true;
    if (this.buffer.endsWith(toneKey)) return true;
    if (this.buffer.length === 0) return false;
    const lastChar = this.buffer[this.buffer.length - 1];
    return isBaseVowel(getBaseVowel(lastChar));
  }

  private applyToneToWord(word: string, toneIdx: number, appendToneKeyOnEscape: boolean): string | null {
    const toneKey = this.getToneKey(toneIdx);
    const pos = this.findTonePosition(word);
    if (pos < 0) return null;

    const ch = word[pos];
    const currentTone = getCurrentTone(ch);

    if (currentTone === toneIdx) {
      // Đã có dấu -> escape ra chữ gõ thô, ví dụ: cá + 1 = ca1
      const base = getBaseVowel(ch);
      const forms = VOWEL_TABLE.get(base);
      if (forms) {
        const isUpper = ch === ch.toUpperCase() && ch !== ch.toLowerCase();
        const escaped = word.substring(0, pos) + (isUpper ? forms[0].toUpperCase() : forms[0]) + word.substring(pos + 1);
        return appendToneKeyOnEscape ? escaped + toneKey : escaped;
      }
    }
    return word.substring(0, pos) + applyTone(ch, toneIdx) + word.substring(pos + 1);
  }

  private findTonePosition(word: string): number {
    const lower = word.toLowerCase();
    const runs: number[][] = [];
    let currentRun: number[] = [];
    for (let i = 0; i < lower.length; i++) {
      if (isBaseVowel(getBaseVowel(lower[i]))) {
        currentRun.push(i);
      } else if (currentRun.length > 0) {
        runs.push(currentRun);
        currentRun = [];
      }
    }
    if (currentRun.length > 0) {
      runs.push(currentRun);
    }

    if (runs.length === 0) return -1;

    const vowelPositions = runs[runs.length - 1];
    if (vowelPositions.length === 1) return vowelPositions[0];

    const cluster = this.getVowelCluster(lower, vowelPositions);
    const finalLength = lower.length - vowelPositions[vowelPositions.length - 1] - 1;

    if (cluster === 'ie' || cluster === 'iê' || cluster === 'ye' || cluster === 'yê' ||
      cluster === 'uo' || cluster === 'uô' || cluster === 'ươ') {
      return finalLength > 0 ? vowelPositions[1] : vowelPositions[0];
    }

    if (cluster === 'uyê' || cluster === 'uye') {
      return vowelPositions[vowelPositions.length - 1];
    }

    if (vowelPositions.length >= 3) {
      return vowelPositions[1];
    }

    if (cluster === 'oa' || cluster === 'oe' || cluster === 'uy') {
      return vowelPositions[1];
    }

    return vowelPositions[0];
  }

  private getVowelCluster(word: string, positions: number[]): string {
    let cluster = '';
    for (let i = 0; i < positions.length; i++) {
      cluster += getBaseVowel(word[positions[i]]);
    }
    return cluster;
  }

  private getToneKey(toneIdx: number): string {
    for (const key of VNI_TONE.keys()) {
      if (VNI_TONE.get(key) === toneIdx) {
        return key;
      }
    }
    return '';
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
