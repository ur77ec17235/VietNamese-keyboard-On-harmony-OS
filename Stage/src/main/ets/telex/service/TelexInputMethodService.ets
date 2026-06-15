import { InputMethodExtensionAbility } from '@ohos.inputmethodextension';
import { TelexEngine } from '../core/TelexEngine';
import { CandidateView } from '../ui/CandidateView';
import { VirtualKeyboard } from '../ui/VirtualKeyboard';

export default class TelexInputMethodService extends InputMethodExtensionAbility {
  private telexEngine: TelexEngine = new TelexEngine();
  private candidateView: CandidateView | null = null;
  private keyboardView: VirtualKeyboard | null = null;

  onCreate(want): void {
    console.log('TelexInputMethodService onCreate');
    this.telexEngine = new TelexEngine();
    this.initViews();
  }

  onDestroy(): void {
    console.log('TelexInputMethodService onDestroy');
  }

  private initViews(): void {
    // Khởi tạo các view
    // Note: Trong thực tế, cần sử dụng window manager
  }

  // Called when the input method is bound to a client
  onBindInput(client): void {
    console.log('onBindInput:', client);
  }

  // Called when starting input
  onStartInput(client, info): void {
    console.log('onStartInput:', info);
    this.showKeyboard();
  }

  // Called when stopping input
  onStopInput(client): void {
    console.log('onStopInput');
    this.hideKeyboard();
  }

  // Handle keyboard events
  handleKeyEvent(keyEvent): boolean {
    console.log('handleKeyEvent:', keyEvent);

    // Get current text from editor
    const editor = this.getEditor();
    if (!editor) return false;

    const currentText = editor.getTextBeforeCursor(1000);
    const cursorPos = editor.getCursorPosition();

    // Convert key code to character
    const char = this.keyCodeToChar(keyEvent.keyCode, keyEvent.shiftPressed);

    if (char) {
      const result = this.telexEngine.processKey(char, currentText, cursorPos);

      // Update editor
      editor.replaceText(result.text);
      editor.setCursorPosition(result.cursor);

      // Show suggestions
      if (result.suggestions.length > 0) {
        this.showSuggestions(result.suggestions);
      }

      return true;
    }

    // Handle special keys
    switch (keyEvent.keyCode) {
      case 67: // Backspace
        const backspaceResult = this.telexEngine.processKey('Backspace', currentText, cursorPos);
        editor.replaceText(backspaceResult.text);
        editor.setCursorPosition(backspaceResult.cursor);
        return true;
      case 62: // Space
        const spaceResult = this.telexEngine.processKey(' ', currentText, cursorPos);
        editor.replaceText(spaceResult.text);
        editor.setCursorPosition(spaceResult.cursor);
        return true;
    }

    return false;
  }

  private keyCodeToChar(keyCode: number, shift: boolean): string | null {
    // Map HarmonyOS key codes to characters
    const keyMap: Record<number, string> = {
      29: 'a', 30: 'b', 31: 'c', 32: 'd', 33: 'e',
      34: 'f', 35: 'g', 36: 'h', 37: 'i', 38: 'j',
      39: 'k', 40: 'l', 41: 'm', 42: 'n', 43: 'o',
      44: 'p', 45: 'q', 46: 'r', 47: 's', 48: 't',
      49: 'u', 50: 'v', 51: 'w', 52: 'x', 53: 'y',
      54: 'z'
    };

    const char = keyMap[keyCode];
    if (char) {
      return shift ? char.toUpperCase() : char;
    }

    return null;
  }

  private getEditor(): any {
    // Lấy editor hiện tại
    // Trong thực tế, cần implement logic để lấy editor từ client
    return {
      getTextBeforeCursor: (length: number) => '',
      getCursorPosition: () => 0,
      replaceText: (text: string) => {},
      setCursorPosition: (pos: number) => {}
    };
  }

  private showKeyboard(): void {
    console.log('Showing virtual keyboard');
    // Implement show keyboard UI
  }

  private hideKeyboard(): void {
    console.log('Hiding virtual keyboard');
    // Implement hide keyboard UI
  }

  private showSuggestions(suggestions: string[]): void {
    console.log('Showing suggestions:', suggestions);
    // Update candidate view
  }
}