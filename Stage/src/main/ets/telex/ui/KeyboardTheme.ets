export const GTV_BG_COLOR_KEY = 'gtv_bg_color';
export const GTV_KEY_COLOR_KEY = 'gtv_key_color';
export const GTV_BG_OPACITY_KEY = 'gtv_opacity';
export const GTV_KEY_OPACITY_KEY = 'gtv_key_opacity';
export const GTV_DARK_MODE_KEY = 'gtv_dark_mode';
export const GTV_SHOW_NUMBER_ROW_KEY = 'gtv_show_number_row';

export const DEFAULT_KEYBOARD_BG_COLOR = '#E5E5EA';
export const DEFAULT_KEYBOARD_KEY_COLOR = '#FFFFFF';
export const DEFAULT_KEYBOARD_OPACITY = 100;
export const DEFAULT_KEYBOARD_KEY_OPACITY = 100;
export const DEFAULT_KEYBOARD_DARK_MODE = false;

export const KEYBOARD_COLOR_PALETTE: string[] = [
  '#111111', '#1A1A38', '#2D2D2D', '#1A6A40', '#0B0B20',
  '#4A90D9', '#E94560', '#E5E5EA', '#FFFFFF'
];

export const KEYBOARD_OPACITY_OPTIONS: number[] = [100, 75, 50];

export interface KeyboardThemePreset {
  label: string;
  bgColor: string;
  keyColor: string;
  bgOpacity: number;
  keyOpacity: number;
  darkMode: boolean;
}

export const KEYBOARD_THEME_PRESETS: KeyboardThemePreset[] = [
  {
    label: 'Mặc định tối',
    bgColor: '#0B0B20',
    keyColor: '#2D2D2D',
    bgOpacity: 100,
    keyOpacity: 100,
    darkMode: true
  },
  {
    label: 'Sáng gọn',
    bgColor: DEFAULT_KEYBOARD_BG_COLOR,
    keyColor: DEFAULT_KEYBOARD_KEY_COLOR,
    bgOpacity: 100,
    keyOpacity: 100,
    darkMode: false
  },
  {
    label: 'Xanh dịu',
    bgColor: '#4A90D9',
    keyColor: '#FFFFFF',
    bgOpacity: 100,
    keyOpacity: 100,
    darkMode: false
  }
];

export interface VirtualKeyboardTheme {
  bgColor: string;
  keyBg: string;
  specialBg: string;
  pressedBg: string;
  shiftedBg: string;
  accentColor: string;
  selectedBorder: string;
  selectedFill: string;
  textColor: string;
  mutedTextColor: string;
  barBg: string;
  taskButtonBg: string;
}

export function normalizeKeyboardOpacity(value: number): number {
  return value <= 1 ? value : value / 100;
}

export function getKeyboardTextColor(color: string): string {
  return color === '#FFFFFF' || color === '#E5E5EA' || color === '#D1D5DB' || color === '#B0B4C0'
    ? '#000000'
    : '#FFFFFF';
}

export function getVirtualKeyboardTheme(bgColor: string, keyColor: string, darkMode: boolean): VirtualKeyboardTheme {
  return {
    bgColor: bgColor,
    keyBg: keyColor,
    specialBg: darkMode ? '#3D3D3D' : '#B0B4C0',
    pressedBg: darkMode ? '#4D4D4D' : '#D1D5DB',
    shiftedBg: '#4A90D9',
    accentColor: '#60A5FA',
    selectedBorder: '#3B82F6',
    selectedFill: '#3B82F6',
    textColor: getKeyboardTextColor(keyColor),
    mutedTextColor: darkMode ? '#9CA3AF' : '#566070',
    barBg: darkMode ? '#181818' : '#DADDE5',
    taskButtonBg: darkMode ? '#2D2D2D' : '#C8CDD8'
  };
}

export function getVirtualKeyboardKeyBg(key: string, theme: VirtualKeyboardTheme, pressedKey: string,
  shifted: boolean, special: boolean): string {
  if (key === pressedKey) {
    return theme.pressedBg;
  }
  if (key === 'SHIFT' && shifted) {
    return theme.shiftedBg;
  }
  if (special) {
    return theme.specialBg;
  }
  return theme.keyBg;
}
