/**
 * TelexEngine.ets
 * Engine gõ tiếng Việt theo phương pháp Telex
 *
 * Nguyên tắc Telex:
 * - Phụ âm đặc biệt: dd → đ
 * - Nguyên âm có dấu: aa→â, aw→ă, ee→ê, oo→ô, ow→ơ, uw→ư
 * - Dấu thanh: s→sắc(´), f→huyền(`), r→hỏi(ả), x→ngã(ã), j→nặng(ạ)
 * - Escape: gõ thêm ký tự cuối để hoàn tác (ví dụ: aas → as, aaw → aw)
 */

import { InputEngineBase, ProcessResult } from './InputEngineBase';

// Bảng nguyên âm tiếng Việt với đầy đủ tổ hợp dấu
const VOWEL_TABLE: Map<string, string[]> = new Map([
  // [base, sắc, huyền, hỏi, ngã, nặng]
  ['a', ['a', 'á', 'à', 'ả', 'ã', 'ạ']],
  ['â', ['â', 'ấ', 'ầ', 'ẩ', 'ẫ', 'ậ']],
  ['ă', ['ă', 'ắ', 'ằ', 'ẳ', 'ẵ', 'ặ']],
  ['e', ['e', 'é', 'è', 'ẻ', 'ẽ', 'ẹ']],
  ['ê', ['ê', 'ế', 'ề', 'ể', 'ễ', 'ệ']],
  ['i', ['i', 'í', 'ì', 'ỉ', 'ĩ', 'ị']],
  ['o', ['o', 'ó', 'ò', 'ỏ', 'õ', 'ọ']],
  ['ô', ['ô', 'ố', 'ồ', 'ổ', 'ỗ', 'ộ']],
  ['ơ', ['ơ', 'ớ', 'ờ', 'ở', 'ỡ', 'ợ']],
  ['u', ['u', 'ú', 'ù', 'ủ', 'ũ', 'ụ']],
  ['ư', ['ư', 'ứ', 'ừ', 'ử', 'ữ', 'ự']],
  ['y', ['y', 'ý', 'ỳ', 'ỷ', 'ỹ', 'ỵ']],
]);

// Index dấu thanh
const TONE_INDEX: Map<string, number> = new Map([
  ['s', 1], // sắc
  ['f', 2], // huyền
  ['r', 3], // hỏi
  ['x', 4], // ngã
  ['j', 5], // nặng
]);

// Ánh xạ Telex → nguyên âm có dấu mũ
const VOWEL_MAP: Map<string, string> = new Map([
  ['aa', 'â'],
  ['aw', 'ă'],
  ['ee', 'ê'],
  ['oo', 'ô'],
  ['ow', 'ơ'],
  ['uw', 'ư'],
  ['w', 'ư'],   // w đứng một mình = ư (theo Telex mở rộng)
]);

const FINAL_CONSONANTS: string[] = ['ng', 'nh', 'ch', 'n', 'm', 't', 'c', 'p', 'g', 'k'];

// Kiểm tra ký tự có phải nguyên âm cơ bản không
function isBaseVowel(ch: string): boolean {
  return ['a', 'â', 'ă', 'e', 'ê', 'i', 'o', 'ô', 'ơ', 'u', 'ư', 'y'].includes(ch.toLowerCase());
}

// Lấy base vowel từ vowel có dấu
function getBaseVowel(ch: string): string {
  for (const base of VOWEL_TABLE.keys()) {
    const forms = VOWEL_TABLE.get(base) as string[];
    if (forms.includes(ch.toLowerCase())) return base;
  }
  return ch.toLowerCase();
}

// Áp dụng dấu thanh vào một nguyên âm
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

// Lấy dấu thanh hiện tại của một ký tự
function getCurrentTone(ch: string): number {
  const lower = ch.toLowerCase();
  for (const base of VOWEL_TABLE.keys()) {
    const forms = VOWEL_TABLE.get(base) as string[];
    const idx = forms.indexOf(lower);
    if (idx > 0) return idx;
  }
  return 0; // không dấu
}

export class TelexEngine implements InputEngineBase {
  readonly name: string;
  private fullInput: boolean;
  private buffer: string = '';
  private rawInput: string = ''; // input chưa xử lý để detect escape

  constructor(fullInput: boolean = true) {
    this.fullInput = fullInput;
    this.name = fullInput ? 'Telex Full' : 'Telex Simple';
  }

  processInput(key: string): ProcessResult {
    // Delete / Backspace
    if (key === 'Backspace' || key === 'Delete') {
      if (this.buffer.length > 0) {
        this.buffer = this.buffer.slice(0, -1);
        if (this.rawInput.length > 0) {
          this.rawInput = this.rawInput.slice(0, -1);
        }
        return {
          commitText: '',
          composingText: this.buffer,
          deleteCount: 0,
          candidates: [],
          committed: false
        };
      }
      return { commitText: '', composingText: '', deleteCount: 1, candidates: [], committed: false };
    }

    // Space / Enter - chỉ chèn dấu phân cách, không commit lại cả từ
    if (key === ' ' || key === '\n' || key === 'Enter') {
      const suffix = key === 'Enter' ? '\n' : ' ';
      this.reset();
      return {
        commitText: suffix,
        composingText: '',
        deleteCount: 0,
        candidates: [],
        committed: true
      };
    }

    // Ký tự đặc biệt / dấu câu - chỉ chèn ký tự đó, không commit lại cả từ
    if (!this.isVietnameseKey(key)) {
      this.reset();
      return {
        commitText: key,
        composingText: '',
        deleteCount: 0,
        candidates: [],
        committed: true
      };
    }

    // Thêm vào buffer
    this.rawInput += key.toLowerCase();
    const keyLower = key.toLowerCase();

    // Xử lý dd → đ
    if (keyLower === 'd' && this.buffer.endsWith('d')) {
      this.buffer = this.buffer.slice(0, -1) + 'đ';
      // Escape: ddd → dd + d
      if (this.rawInput.endsWith('ddd')) {
        const escaped = this.buffer.slice(0, -1) + 'dd';
        this.reset();
        return this.commitAndReset(escaped);
      }
    }
    // Xử lý dấu thanh
    else if (TONE_INDEX.has(keyLower)) {
      const toneIdx = TONE_INDEX.get(keyLower)!;
      const result = this.canApplyToneKey(keyLower) ? this.applyToneToBuffer(toneIdx) : null;
      if (result !== null) {
        this.buffer = result;
      } else {
        // Không có nguyên âm để đặt dấu, thêm bình thường
        this.buffer += key;
      }
    }
    // Xử lý nguyên âm có dấu mũ (aa, aw, ee, oo, ow, uw)
    else if (keyLower === 'a' || keyLower === 'e' || keyLower === 'o') {
      const lastChar = this.buffer.slice(-1).toLowerCase();
      const escapeText = this.getTelexEscapeText(lastChar, keyLower);
      if (escapeText.length > 0) {
        this.buffer = this.buffer.slice(0, -1) + this.matchCaseForEscape(this.buffer.slice(-1), escapeText);
      } else if (lastChar === keyLower) {
        // aa → â, ee → ê, oo → ô
        const combo = lastChar + keyLower;
        const mapped = VOWEL_MAP.get(combo);
        if (mapped) {
          // Giữ case của ký tự trước
          const prevChar = this.buffer.slice(-1);
          const isUpper = prevChar === prevChar.toUpperCase() && prevChar !== prevChar.toLowerCase();
          this.buffer = this.buffer.slice(0, -1) + (isUpper ? mapped.toUpperCase() : mapped);
        } else {
          this.buffer += key;
        }
      } else {
        const applied = this.fullInput ? this.applySeparatedVowelModifier(keyLower) : false;
        if (!applied) {
          this.buffer += key;
        }
      }
    }
    else if (keyLower === 'w') {
      const lastChar = this.buffer.slice(-1);
      const lastTwo = this.buffer.slice(-2);
      const lastThree = this.buffer.slice(-3);

      const baseLastChar = getBaseVowel(lastChar);
      const baseLastTwo0 = lastTwo.length === 2 ? getBaseVowel(lastTwo[0]) : '';
      const baseLastTwo1 = lastTwo.length === 2 ? getBaseVowel(lastTwo[1]) : '';
      const baseLastThree0 = lastThree.length === 3 ? getBaseVowel(lastThree[0]) : '';
      const baseLastThree1 = lastThree.length === 3 ? getBaseVowel(lastThree[1]) : '';
      const baseLastThree2 = lastThree.length === 3 ? getBaseVowel(lastThree[2]) : '';

      const escapeText = this.getTelexEscapeText(lastChar.toLowerCase(), keyLower);
      if (escapeText.length > 0) {
        this.buffer = this.buffer.slice(0, -1) + this.matchCaseForEscape(lastChar, escapeText);
      } else if (baseLastThree0 === 'u' && baseLastThree1 === 'o' && baseLastThree2 === 'u') {
        const p1 = this.buffer.slice(-3, -2);
        const p2 = this.buffer.slice(-2, -1);
        const p3 = this.buffer.slice(-1);
        this.buffer = this.buffer.slice(0, -3) + applyVowelBase(p1, 'ư') + applyVowelBase(p2, 'ơ') + p3;
      } else if (baseLastTwo0 === 'u' && baseLastTwo1 === 'o') {
        const p1 = this.buffer.slice(-2, -1);
        const p2 = this.buffer.slice(-1);
        this.buffer = this.buffer.slice(0, -2) + applyVowelBase(p1, 'ư') + applyVowelBase(p2, 'ơ');
      } else if ((baseLastTwo0 === 'ư' || baseLastTwo0 === 'u') && (baseLastTwo1 === 'ơ' || baseLastTwo1 === 'o') && !(baseLastTwo0 === 'u' && baseLastTwo1 === 'o')) {
        const p1 = this.buffer.slice(-2, -1);
        const p2 = this.buffer.slice(-1);
        this.buffer = this.buffer.slice(0, -2) + applyVowelBase(p1, 'ư') + applyVowelBase(p2, 'ơ');
      } else if (baseLastTwo0 === 'u' && baseLastTwo1 === 'u') {
        const p1 = this.buffer.slice(-2, -1);
        const p2 = this.buffer.slice(-1);
        this.buffer = this.buffer.slice(0, -2) + applyVowelBase(p1, 'ư') + p2;
      } else if ((baseLastTwo0 === 'u' || baseLastTwo0 === 'ư') && (baseLastTwo1 === 'a' || baseLastTwo1 === 'ă')) {
        const p3 = this.buffer.length >= 3 ? this.buffer.slice(-3, -2).toLowerCase() : '';
        if (p3 === 'q') {
          if (baseLastTwo0 === 'u' && baseLastTwo1 === 'a') {
            const p1 = this.buffer.slice(-1);
            this.buffer = this.buffer.slice(0, -1) + applyVowelBase(p1, 'ă');
          } else {
            const applied = this.fullInput ? this.applySeparatedWModifier() : false;
            if (!applied) this.buffer += key;
          }
        } else {
          const p1 = this.buffer.slice(-2, -1);
          const p2 = this.buffer.slice(-1);
          if (baseLastTwo0 === 'ư' && baseLastTwo1 === 'a') {
            this.buffer = this.buffer.slice(0, -2) + applyVowelBase(p1, 'u') + p2 + 'w';
          } else if (baseLastTwo0 === 'u' && baseLastTwo1 === 'a') {
            this.buffer = this.buffer.slice(0, -2) + applyVowelBase(p1, 'ư') + p2;
          } else {
            const applied = this.fullInput ? this.applySeparatedWModifier() : false;
            if (!applied) this.buffer += key;
          }
        }
      } else if (baseLastChar === 'o') {
        const p1 = this.buffer.slice(-1);
        this.buffer = this.buffer.slice(0, -1) + applyVowelBase(p1, 'ơ');
      } else if (baseLastChar === 'u') {
        const p1 = this.buffer.slice(-1);
        this.buffer = this.buffer.slice(0, -1) + applyVowelBase(p1, 'ư');
      } else if (baseLastChar === 'a') {
        const p1 = this.buffer.slice(-1);
        this.buffer = this.buffer.slice(0, -1) + applyVowelBase(p1, 'ă');
      } else {
        const applied = this.fullInput ? this.applySeparatedWModifier() : false;
        if (!applied) {
          this.buffer += key;
        }
      }
    }
    else {
      this.buffer += key;
    }

    return {
      commitText: '',
      composingText: this.buffer,
      deleteCount: 0,
      candidates: this.generateCandidates(this.buffer),
      committed: false
    };
  }

  private applyToneToBuffer(toneIdx: number): string | null {
    const toneKey = this.getToneKey(toneIdx);
    if (toneKey.length > 0 && this.buffer.toLowerCase().endsWith(toneKey)) {
      const stem = this.buffer.substring(0, this.buffer.length - 1);
      const restored = this.applyToneToWord(stem, toneIdx, false);
      if (restored !== null) {
        return restored;
      }
    }

    return this.applyToneToWord(this.buffer, toneIdx, true);
  }

  private applySeparatedVowelModifier(keyLower: string): boolean {
    const targetIndex = this.findModifierTargetIndex([keyLower]);
    if (targetIndex < 0) return false;

    const target = this.buffer[targetIndex];
    const escapeText = this.getTelexEscapeText(target.toLowerCase(), keyLower);
    if (escapeText.length > 0) {
      this.buffer = this.buffer.substring(0, targetIndex) +
        this.matchCaseForEscape(target, escapeText.substring(0, 1)) +
        this.buffer.substring(targetIndex + 1) +
        escapeText.substring(1);
      return true;
    }

    const combo = getBaseVowel(target) + keyLower;
    const mapped = VOWEL_MAP.get(combo);
    if (!mapped) return false;

    this.buffer = this.buffer.substring(0, targetIndex) + applyVowelBase(target, mapped) + this.buffer.substring(targetIndex + 1);
    return true;
  }

  private applySeparatedWModifier(): boolean {
    if (this.applySeparatedUowModifier()) return true;
    if (this.applySeparatedUawModifier()) return true;

    const targetIndex = this.findModifierTargetIndex(['a', 'o', 'u', 'ă', 'ơ', 'ư']);
    if (targetIndex < 0) return false;

    const target = this.buffer[targetIndex];
    const escapeText = this.getTelexEscapeText(target.toLowerCase(), 'w');
    if (escapeText.length > 0) {
      this.buffer = this.buffer.substring(0, targetIndex) +
        this.matchCaseForEscape(target, escapeText.substring(0, 1)) +
        this.buffer.substring(targetIndex + 1) +
        escapeText.substring(1);
      return true;
    }

    const combo = getBaseVowel(target) + 'w';
    const mapped = VOWEL_MAP.get(combo);
    if (!mapped) return false;

    this.buffer = this.buffer.substring(0, targetIndex) + applyVowelBase(target, mapped) + this.buffer.substring(targetIndex + 1);
    return true;
  }

  private applySeparatedUawModifier(): boolean {
    const finalStart = this.getFinalConsonantStart(this.buffer);
    // 'ưa' không đi với phụ âm cuối. Nếu có phụ âm cuối, w sẽ tác động lên 'a' thành 'ă'
    if (finalStart !== this.buffer.length || finalStart < 2) return false;

    const secondIndex = finalStart - 1;
    const firstIndex = finalStart - 2;
    const firstBase = getBaseVowel(this.buffer[firstIndex]);
    const secondBase = getBaseVowel(this.buffer[secondIndex]);
    const canApplyUaw = (firstBase === 'u' || firstBase === 'ư') && (secondBase === 'a' || secondBase === 'ă');
    if (!canApplyUaw) return false;

    if (firstIndex > 0) {
      const p3 = this.buffer[firstIndex - 1].toLowerCase();
      if (p3 === 'q') {
        return false; // let findClosestModifierTargetIndex handle a -> ă
      }
    }

    const first = this.buffer[firstIndex];
    const second = this.buffer[secondIndex];

    if (firstBase === 'ư' && secondBase === 'a') {
      this.buffer = this.buffer.substring(0, firstIndex) +
        this.matchCaseForEscape(first, 'u') +
        this.matchCaseForEscape(second, 'a') +
        this.buffer.substring(secondIndex + 1) +
        'w';
      return true;
    }

    if (firstBase === 'u' && secondBase === 'a') {
      this.buffer = this.buffer.substring(0, firstIndex) +
        applyVowelBase(first, 'ư') +
        applyVowelBase(second, 'a') +
        this.buffer.substring(secondIndex + 1);
      return true;
    }
    return false;
  }

  private applySeparatedUowModifier(): boolean {
    const finalStart = this.getFinalConsonantStart(this.buffer);
    if (finalStart < 2) return false;

    let i = finalStart - 1;
    while (i > 0) {
      if (!isBaseVowel(getBaseVowel(this.buffer[i]))) break;

      const secondIndex = i;
      const firstIndex = i - 1;
      const firstBase = getBaseVowel(this.buffer[firstIndex]);
      const secondBase = getBaseVowel(this.buffer[secondIndex]);
      const canApplyUow = (firstBase === 'u' || firstBase === 'ư') && (secondBase === 'o' || secondBase === 'ơ');

      if (canApplyUow) {
        const first = this.buffer[firstIndex];
        const second = this.buffer[secondIndex];
        if (firstBase === 'ư' && secondBase === 'ơ') {
          this.buffer = this.buffer.substring(0, firstIndex) +
            this.matchCaseForEscape(first, 'u') +
            this.matchCaseForEscape(second, 'o') +
            this.buffer.substring(secondIndex + 1) +
            'w';
          return true;
        }

        this.buffer = this.buffer.substring(0, firstIndex) +
          applyVowelBase(first, 'ư') +
          applyVowelBase(second, 'ơ') +
          this.buffer.substring(secondIndex + 1);
        return true;
      }
      i--;
    }
    return false;
  }

  private findModifierTargetIndex(targets: string[]): number {
    const finalStart = this.getFinalConsonantStart(this.buffer);

    let i = finalStart - 1;
    while (i >= 0) {
      const base = getBaseVowel(this.buffer[i]);
      if (targets.includes(base)) return i;
      for (const target of targets) {
        if (this.getTelexEscapeText(this.buffer[i].toLowerCase(), target).length > 0) return i;
      }
      if (!isBaseVowel(base)) break;
      i--;
    }
    return -1;
  }



  private getTelexEscapeText(ch: string, keyLower: string): string {
    const base = getBaseVowel(ch);
    if (keyLower === 'a') {
      if (base === 'â') return 'aa';
      if (base === 'ă') return 'aw';
    }
    if (keyLower === 'e' && base === 'ê') return 'ee';
    if (keyLower === 'o') {
      if (base === 'ô') return 'oo';
      if (base === 'ơ') return 'ow';
    }
    if (keyLower === 'w') {
      if (base === 'ă') return 'aw';
      if (base === 'ơ') return 'ow';
      if (base === 'ư') return 'uw';
    }
    return '';
  }

  private matchCaseForEscape(source: string, text: string): string {
    const isUpper = source === source.toUpperCase() && source !== source.toLowerCase();
    return isUpper ? text.toUpperCase() : text;
  }

  private getFinalConsonantStart(word: string): number {
    const lower = word.toLowerCase();
    for (const finalConsonant of FINAL_CONSONANTS) {
      if (lower.endsWith(finalConsonant) && lower.length > finalConsonant.length) {
        return lower.length - finalConsonant.length;
      }
    }
    return word.length;
  }

  private canApplyToneKey(toneKey: string): boolean {
    if (this.fullInput) return true;
    if (this.buffer.toLowerCase().endsWith(toneKey)) return true;
    if (this.buffer.length === 0) return false;
    const lastChar = this.buffer[this.buffer.length - 1];
    return isBaseVowel(getBaseVowel(lastChar));
  }

  private applyToneToWord(word: string, toneIdx: number, appendToneKeyOnEscape: boolean): string | null {
    const positions = this.findTonePosition(word);
    if (positions < 0) return null;

    let strippedWord = '';
    let existingTone = 0;
    
    for (let i = 0; i < word.length; i++) {
      const ch = word[i];
      const base = getBaseVowel(ch);
      if (isBaseVowel(base)) {
        const tone = getCurrentTone(ch);
        if (tone > 0) existingTone = tone;
        
        const isUpper = ch === ch.toUpperCase() && ch !== ch.toLowerCase();
        strippedWord += isUpper ? base.toUpperCase() : base;
      } else {
        strippedWord += ch;
      }
    }

    let result = strippedWord;

    if (existingTone === toneIdx) {
      // Escape
      if (appendToneKeyOnEscape) {
        result += this.getToneKey(toneIdx);
      }
      return result;
    } 

    // Apply new tone
    const ch = result[positions];
    result = result.substring(0, positions) + applyTone(ch, toneIdx) + result.substring(positions + 1);
    
    return result;
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
    
    // Gi- rules (giữ, giá, giêng)
    if (vowelPositions.length >= 2 && vowelPositions[0] > 0 && lower[vowelPositions[0] - 1] === 'g' && getBaseVowel(lower[vowelPositions[0]]) === 'i') {
      return vowelPositions[1]; 
    }

    // Qu- rules
    if (vowelPositions.length >= 2 && vowelPositions[0] > 0 && lower[vowelPositions[0] - 1] === 'q' && getBaseVowel(lower[vowelPositions[0]]) === 'u') {
      if (vowelPositions.length === 2) return vowelPositions[1]; // quá, quy
      if (vowelPositions.length === 3) {
        if (cluster === 'uye' || cluster === 'uyê') return vowelPositions[2];
        return vowelPositions[1]; // quay, quai
      }
      if (vowelPositions.length === 4) {
        return vowelPositions[2]; 
      }
    }

    if (cluster === 'ie' || cluster === 'iê' || cluster === 'ye' || cluster === 'yê' ||
      cluster === 'uo' || cluster === 'uô' || cluster === 'ươ') {
      return vowelPositions[1];
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
    for (const key of TONE_INDEX.keys()) {
      if (TONE_INDEX.get(key) === toneIdx) {
        return key;
      }
    }
    return '';
  }

  private isVietnameseKey(key: string): boolean {
    return /^[a-zA-ZàáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỶỸĐ]$/.test(key);
  }

  private commitAndReset(text: string): ProcessResult {
    this.reset();
    return {
      commitText: text,
      composingText: '',
      deleteCount: 0,
      candidates: [],
      committed: true
    };
  }

  reset(): void {
    this.buffer = '';
    this.rawInput = '';
  }

  getComposingText(): string {
    return this.buffer;
  }

  private generateCandidates(word: string): string[] {
    if (word.length < 2) return [];
    // Placeholder - sẽ kết nối từ điển sau
    return [];
  }
}
