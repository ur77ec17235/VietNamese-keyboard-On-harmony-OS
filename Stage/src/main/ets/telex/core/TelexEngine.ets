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
  readonly name: string = 'Telex';
  private buffer: string = '';
  private rawInput: string = ''; // input chưa xử lý để detect escape

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
      const result = this.applyToneToBuffer(toneIdx);
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
      if (lastChar === keyLower) {
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
        this.buffer += key;
      }
    }
    else if (keyLower === 'w') {
      const lastChar = this.buffer.slice(-1).toLowerCase();
      const lastTwo = this.buffer.slice(-2).toLowerCase();

      if (lastTwo === 'uo') {
        const p1 = this.buffer.slice(-2, -1);
        const p2 = this.buffer.slice(-1);
        this.buffer = this.buffer.slice(0, -2) + (p1 === 'U' ? 'Ư' : 'ư') + (p2 === 'O' ? 'Ơ' : 'ơ');
      } else if (lastTwo === 'ưo' || lastTwo === 'ươ' || lastTwo === 'uơ') {
        // Nếu đã gõ ưo hoặc uơ rồi nhấn thêm w thì thành ươ
        const p1 = this.buffer.slice(-2, -1);
        const p2 = this.buffer.slice(-1);
        this.buffer = this.buffer.slice(0, -2) + (p1 === 'U' || p1 === 'Ư' ? 'Ư' : 'ư') + (p2 === 'O' || p2 === 'Ơ' ? 'Ơ' : 'ơ');
      } else if (lastTwo === 'uu') {
        const p1 = this.buffer.slice(-2, -1);
        const p2 = this.buffer.slice(-1);
        this.buffer = this.buffer.slice(0, -2) + (p1 === 'U' ? 'Ư' : 'ư') + p2;
      } else if (lastChar === 'o') {
        const p1 = this.buffer.slice(-1);
        this.buffer = this.buffer.slice(0, -1) + (p1 === 'O' ? 'Ơ' : 'ơ');
      } else if (lastChar === 'u') {
        const p1 = this.buffer.slice(-1);
        this.buffer = this.buffer.slice(0, -1) + (p1 === 'U' ? 'Ư' : 'ư');
      } else if (lastChar === 'a') {
        const p1 = this.buffer.slice(-1);
        this.buffer = this.buffer.slice(0, -1) + (p1 === 'A' ? 'Ă' : 'ă');
      } else {
        this.buffer += key;
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
    // Tìm vị trí nguyên âm phù hợp trong buffer để đặt dấu
    // Ưu tiên: vần chính của âm tiết
    let result = this.buffer;
    let applied = false;

    // Tìm nguyên âm cuối cùng trong buffer
    // Theo quy tắc tiếng Việt, dấu thanh đặt vào nguyên âm chính
    const positions = this.findTonePosition(result);

    if (positions >= 0) {
      const ch = result[positions];
      const base = getBaseVowel(ch);
      const currentTone = getCurrentTone(ch);

      if (currentTone === toneIdx) {
        // Đã có dấu này rồi → escape (xóa dấu)
        const forms = VOWEL_TABLE.get(base);
        if (forms) {
          const newCh = forms[0]; // về không dấu
          const isUpper = ch === ch.toUpperCase() && ch !== ch.toLowerCase();
          result = result.substring(0, positions) + (isUpper ? newCh.toUpperCase() : newCh) + result.substring(positions + 1);
        }
      } else {
        // Áp dụng dấu mới
        result = result.substring(0, positions) + applyTone(ch, toneIdx) + result.substring(positions + 1);
      }
      applied = true;
    }

    return applied ? result : null;
  }

  private findTonePosition(word: string): number {
    // Quy tắc đặt dấu trong tiếng Việt:
    // 1. Nếu có âm đôi/ba (ươ, uô, iê...) → đặt ở nguyên âm chính
    // 2. Nếu từ kết thúc bằng phụ âm → đặt ở nguyên âm trước phụ âm
    // 3. Nếu không → đặt ở nguyên âm cuối cùng

    const lower = word.toLowerCase();

    // Tìm tất cả vị trí nguyên âm
    const vowelPositions: number[] = [];
    for (let i = 0; i < lower.length; i++) {
      if (isBaseVowel(getBaseVowel(lower[i]))) {
        vowelPositions.push(i);
      }
    }

    if (vowelPositions.length === 0) return -1;
    if (vowelPositions.length === 1) return vowelPositions[0];

    // Kiểm tra có phụ âm cuối không
    const lastChar = lower[lower.length - 1];
    const hasEndConsonant = !isBaseVowel(getBaseVowel(lastChar)) && lastChar !== 'đ';

    if (hasEndConsonant) {
      // Đặt dấu ở nguyên âm cuối trước phụ âm cuối
      return vowelPositions[vowelPositions.length - 1];
    }

    // Không có phụ âm cuối → nguyên âm thứ 2 nếu có 2+ nguyên âm
    if (vowelPositions.length >= 2) {
      return vowelPositions[1];
    }

    return vowelPositions[vowelPositions.length - 1];
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