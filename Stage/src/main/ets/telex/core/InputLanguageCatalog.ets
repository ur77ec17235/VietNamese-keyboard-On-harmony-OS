import { InputMode } from './InputEngineBase';

export class InputLanguageOption {
  id: string;
  title: string;
  subtitle: string;
  methods: InputMode[];
  defaultMode: InputMode;
  installed: boolean;

  constructor(id: string, title: string, subtitle: string, methods: InputMode[],
    defaultMode: InputMode, installed: boolean) {
    this.id = id;
    this.title = title;
    this.subtitle = subtitle;
    this.methods = methods;
    this.defaultMode = defaultMode;
    this.installed = installed;
  }
}

export const INSTALLED_INPUT_LANGUAGES: InputLanguageOption[] = [
  new InputLanguageOption('vi', 'Tiếng Việt', 'Telex, Telex gọn, VNI, VNI gọn',
    [InputMode.TELEX, InputMode.TELEX_SIMPLE, InputMode.VNI, InputMode.VNI_SIMPLE], InputMode.TELEX, true),
  new InputLanguageOption('en', 'English', 'QWERTY', [InputMode.ENGLISH], InputMode.ENGLISH, true)
];
