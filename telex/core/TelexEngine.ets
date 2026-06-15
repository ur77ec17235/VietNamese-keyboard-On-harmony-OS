export class TelexEngine {
  private buffer: string = '';
  private cursorPos: number = 0;

  // Bảng ánh xạ Telex -> Unicode
  private readonly telexRules: Map<string, string> = new Map([
  // Nguyên âm đôi
    ['aa', 'â'], ['aw', 'ă'], ['dd', 'đ'],
    ['ee', 'ê'], ['oo', 'ô'], ['ow', 'ơ'],
    ['uw', 'ư'],

    // Dấu thanh (xử lý riêng)
    ['as', 'á'], ['af', 'à'], ['ar', 'ả'], ['ax', 'ã'], ['aj', 'ạ'],
    ['âs', 'ấ'], ['âf', 'ầ'], ['âr', 'ẩ'], ['âx', 'ẫ'], ['âj', 'ậ'],
    ['ăs', 'ắ'], ['ăf', 'ằ'], ['ăr', 'ẳ'], ['ăx', 'ẵ'], ['ăj', 'ặ'],
    ['es', 'é'], ['ef', 'è'], ['er', 'ẻ'], ['ex', 'ẽ'], ['ej', 'ẹ'],
    ['ês', 'ế'], ['êf', 'ề'], ['êr', 'ể'], ['êx', 'ễ'], ['êj', 'ệ'],
    ['is', 'í'], ['if', 'ì'], ['ir', 'ỉ'], ['ix', 'ĩ'], ['ij', 'ị'],
    ['os', 'ó'], ['of', 'ò'], ['or', 'ỏ'], ['ox', 'õ'], ['oj', 'ọ'],
    ['ôs', 'ố'], ['ôf', 'ồ'], ['ôr', 'ổ'], ['ôx', 'ỗ'], ['ôj', 'ộ'],
    ['ơs', 'ớ'], ['ơf', 'ờ'], ['ơr', 'ở'], ['ơx', 'ỡ'], ['ơj', 'ợ'],
    ['us', 'ú'], ['uf', 'ù'], ['ur', 'ủ'], ['ux', 'ũ'], ['uj', 'ụ'],
    ['ưs', 'ứ'], ['ưf', 'ừ'], ['ưr', 'ử'], ['ưx', 'ữ'], ['ưj', 'ự'],
    ['ys', 'ý'], ['yf', 'ỳ'], ['yr', 'ỷ'], ['yx', 'ỹ'], ['yj', 'ỵ']
  ]);

  // Process key press
  processKey(key: string, currentText: string, cursor: number): ProcessResult {
    this.buffer = currentText;
    this.cursorPos = cursor;

    // Handle backspace
    if (key === 'Backspace') {
      return this.handleBackspace();
    }

    // Handle space
    if (key === ' ') {
      this.buffer = this.insertAtCursor(' ');
      this.cursorPos++;
      return { text: this.buffer, cursor: this.cursorPos, suggestions: [] };
    }

    // Add character
    this.buffer = this.insertAtCursor(key);
    this.cursorPos++;

    // Convert Telex
    const converted = this.convertTelex();

    return {
      text: converted,
      cursor: this.cursorPos,
      suggestions: this.getSuggestions(converted)
    };
  }

  private convertTelex(): string {
    let result = this.buffer;

    // Convert từ cuối buffer trở đi (từ đang gõ)
    const currentWord = this.getCurrentWord();
    if (currentWord.length > 1) {
      const convertedWord = this.convertWord(currentWord);
      result = this.replaceCurrentWord(convertedWord);
    }

    return result;
  }

  private convertWord(word: string): string {
    let result = word.toLowerCase();

    // Áp dụng các rules từ dài nhất đến ngắn nhất
    const sortedRules = Array.from(this.telexRules.entries())
      .sort((a, b) => b[0].length - a[0].length);

    for (const [telex, unicode] of sortedRules) {
      if (result.includes(telex)) {
        result = result.replace(new RegExp(telex, 'g'), unicode);
      }
    }

    // Handle special case: dd -> đ
    result = result.replace(/dd/g, 'đ');

    // Restore case
    return this.restoreCase(word, result);
  }

  private restoreCase(original: string, converted: string): string {
    if (original === original.toUpperCase()) {
      return converted.toUpperCase();
    } else if (original[0] === original[0].toUpperCase()) {
      return converted.charAt(0).toUpperCase() + converted.slice(1);
    }
    return converted;
  }

  private getCurrentWord(): string {
    let start = this.cursorPos - 1;
    while (start >= 0 && this.buffer[start] !== ' ' && this.buffer[start] !== '\n') {
      start--;
    }
    start++;

    return this.buffer.substring(start, this.cursorPos);
  }

  private replaceCurrentWord(newWord: string): string {
    let start = this.cursorPos - 1;
    while (start >= 0 && this.buffer[start] !== ' ' && this.buffer[start] !== '\n') {
      start--;
    }
    start++;

    const before = this.buffer.substring(0, start);
    const after = this.buffer.substring(this.cursorPos);

    // Update cursor position
    this.cursorPos = start + newWord.length;

    return before + newWord + after;
  }

  private insertAtCursor(char: string): string {
    return this.buffer.substring(0, this.cursorPos) +
      char +
    this.buffer.substring(this.cursorPos);
  }

  private handleBackspace(): ProcessResult {
    if (this.cursorPos > 0) {
      this.buffer = this.buffer.substring(0, this.cursorPos - 1) +
      this.buffer.substring(this.cursorPos);
      this.cursorPos--;
    }

    return {
      text: this.buffer,
      cursor: this.cursorPos,
      suggestions: []
    };
  }

  private getSuggestions(text: string): string[] {
    // Basic suggestions - sẽ mở rộng sau với từ điển
    const lastWord = text.split(' ').pop() || '';
    if (lastWord.length > 0) {
      return this.generateSuggestions(lastWord);
    }
    return [];
  }

  private generateSuggestions(word: string): string[] {
    // Basic suggestions - thêm vào từ điển sau
    const commonWords = [
      'xin', 'chào', 'cảm', 'ơn', 'tôi', 'bạn',
      'không', 'có', 'đi', 'về', 'nhà', 'trường'
    ];

    return commonWords.filter(w =>
    w.startsWith(word.toLowerCase())
    ).slice(0, 5);
  }
}

export interface ProcessResult {
  text: string;
  cursor: number;
  suggestions: string[];
}