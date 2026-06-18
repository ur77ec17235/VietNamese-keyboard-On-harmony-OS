/**
 * KeyboardPage.ets  —  Bàn phím tiếng Việt GoTiengViet
 *
 * CẤU TRÚC 5 HÀNG CỐ ĐỊNH (dùng layoutWeight – không cần tính pixel):
 *   Bar  : thanh gợi ý  (height cố định bằng KBConfig.barH)
 *   Row0 : hàng số / hàng ký tự 0
 *   Row1 : hàng chữ / ký tự 1
 *   Row2 : hàng chữ / ký tự 2
 *   Row3 : ⇧ ... ⌫  (Backspace luôn ở ĐÂY, hàng thứ 4)
 *   Row4 : 123/ABC , [SPACE] . ↵  (hàng action, Enter luôn ở ĐÂY)
 *
 * ĐỂ THAY ĐỔI KÍCH THƯỚC: chỉ cần sửa KBConfig bên dưới.
 */

import { InputMode } from '../telex/core/InputEngineBase';
import { InputLanguageOption, INSTALLED_INPUT_LANGUAGES } from '../telex/core/InputLanguageCatalog';
import { KeyboardBridge } from '../telex/service/KeyboardBridge';
import { KEY_INPUT_MODE, KEY_COMPOSING, KEY_CANDIDATES,
  KEY_IS_SHIFTED, KEY_SHOW_CLIPBOARD, KEY_CLIPBOARD_ITEMS, KEY_CLIPBOARD_STATUS } from '../telex/service/GoTiengVietService';
import { ClipboardItem } from '../telex/service/ClipboardManager';
import { PreferencesManager } from '../telex/core/PreferencesManager';
import preferences from '@ohos.data.preferences';
import display from '@ohos.display';
import { DEFAULT_KEYBOARD_BG_COLOR, DEFAULT_KEYBOARD_DARK_MODE, DEFAULT_KEYBOARD_KEY_COLOR, DEFAULT_KEYBOARD_KEY_OPACITY,
  DEFAULT_KEYBOARD_OPACITY, getVirtualKeyboardKeyBg, getVirtualKeyboardTheme, GTV_BG_COLOR_KEY,
  GTV_BG_OPACITY_KEY, GTV_DARK_MODE_KEY, GTV_KEY_COLOR_KEY, GTV_KEY_OPACITY_KEY, KEYBOARD_COLOR_PALETTE,
  GTV_SHOW_NUMBER_ROW_KEY, KEYBOARD_OPACITY_OPTIONS, normalizeKeyboardOpacity, VirtualKeyboardTheme } from '../telex/ui/KeyboardTheme';

// ─────────────────────────────────────────────────────────
//  TRUNG TÂM CẤU HÌNH  ← SỬA ĐÂY ĐỂ THAY ĐỔI KÍCH THƯỚC
// ─────────────────────────────────────────────────────────
class KBCfg {
  // --- Chiều cao thanh gợi ý (vp) ---
  barH: number = 32;
  // --- Khoảng cách ngang giữa các phím (vp, mỗi bên) ---
  mH: number = 2;
  // --- Khoảng cách dọc trên/dưới mỗi hàng (vp) ---
  mV: number = 0.6;
  // --- Bo góc phím thường ---
  rKey: number = 9;
  // --- Bo góc nút cách ---
  rSpace: number = 10;
  // --- Chiều cao phím = x% chiều cao hàng (layoutWeight) ---
  kH: string = '85.5%';
  // --- Font chữ thường ---
  fs: number = 18;
  // --- Font phím đặc biệt ---
  fsS: number = 14;
  // --- Trọng số chiều rộng các phím trong hàng action ---
  wMode: number = 1.4;    // nút 123/ABC
  wEmoji: number = 0.9;   // nút 😊
  wComma: number = 0.7;   // nút ,
  wSpace: number = 3.8;   // phím cách
  wDot: number = 0.7;     // nút .
  wEnter: number = 1.4;   // nút ↵
  // --- Trọng số SHIFT / BACKSPACE trong hàng shift ---
  wShift: number = 1.5;
  wBS: number = 1.5;
}

class KBCfgLandscape {
  barH: number = 26;
  mH: number = 1.5;
  mV: number = 0.3;
  rKey: number = 7;
  rSpace: number = 8;
  kH: string = '85.5%';
  fs: number = 14;
  fsS: number = 11;
  wMode: number = 1.3;
  wEmoji: number = 0.8;
  wComma: number = 0.6;
  wSpace: number = 4.5;
  wDot: number = 0.6;
  wEnter: number = 1.3;
  wShift: number = 1.5;
  wBS: number = 1.5;
}

const CFG_P = new KBCfg();
const CFG_L = new KBCfgLandscape();

// ─────────────────────────────────────────────────────────
//  HẰNG SỐ APPSTORAGE
// ─────────────────────────────────────────────────────────
const KEY_IS_LANDSCAPE    = 'gtv_isLandscape';
const KEY_PANEL_HEIGHT_VP = 'gtv_panelHeightVp';

enum KeyLayout { LETTERS = 'l', NUMBERS = 'n', SYMBOLS = 's' }
enum TaskPanel { NONE = 'none', MODE = 'mode', LANGUAGE = 'language', TRANSLATE = 'translate', CLIPBOARD = 'clipboard', STICKER = 'sticker', SETTINGS = 'settings', THEME = 'theme' }

class ModeOption {
  label: string; value: InputMode;
  constructor(label: string, value: InputMode) { this.label = label; this.value = value; }
}

class StickerItem {
  title: string; value: string;
  constructor(title: string, value: string) { this.title = title; this.value = value; }
}

class SettingsItem {
  icon: string; title: string; value: string; action: string;
  constructor(icon: string, title: string, value: string, action: string) {
    this.icon = icon;
    this.title = title;
    this.value = value;
    this.action = action;
  }
}

class EmojiCategory {
  name: string; icon: string; items: string[];
  constructor(n: string, i: string, it: string[]) { this.name=n; this.icon=i; this.items=it; }
}


class LayoutSpec {
  row0: string[];
  row1: string[];
  row2: string[];
  row3Inner: string[];
  row3Left: string;
  row5Left: string;
  row3LeftTarget: KeyLayout | null;
  row5LeftTarget: KeyLayout | null;
  constructor(r0: string[], r1: string[], r2: string[], r3: string[], left3: string, left5: string,
    row3Target: KeyLayout | null, row5Target: KeyLayout | null) {
    this.row0 = r0;
    this.row1 = r1;
    this.row2 = r2;
    this.row3Inner = r3;
    this.row3Left = left3;
    this.row5Left = left5;
    this.row3LeftTarget = row3Target;
    this.row5LeftTarget = row5Target;
  }
}

// ─────────────────────────────────────────────────────────
//  DỮ LIỆU HÀNG PHÍM – PORTRAIT
// ─────────────────────────────────────────────────────────

// Chữ (portrait) — Row3 KHÔNG có BACKSPACE (nó là wBS, build riêng)
const P_LTR_R0: string[] = ['1','2','3','4','5','6','7','8','9','0'];
const P_LTR_R1: string[] = ['q','w','e','r','t','y','u','i','o','p'];
const P_LTR_R2: string[] = ['a','s','d','f','g','h','j','k','l'];
const P_LTR_R3_INNER: string[] = ['z','x','c','v','b','n','m'];  // giữa SHIFT và BS

// Số (portrait)
const P_NUM_R0: string[] = ['1','2','3','4','5','6','7','8','9','0'];
const P_NUM_R1: string[] = ['-','/',':',';','(',')','\$','&','@','"'];
const P_NUM_R2: string[] = ['.',',','?','!','\'','_','+','=','~','*'];
const P_NUM_R3_INNER: string[] = ['©','®','™','°','§','¶','µ','∞'];  // giữa #+=  và BS

// Symbols (portrait)
const P_SYM_R0: string[] = ['[',']','{','}','#','%','^','*','<','>'];
const P_SYM_R1: string[] = ['\\','|','`','€','£','¥','₫','÷','×','±'];
const P_SYM_R2: string[] = ['←','→','↑','↓','↔','≈','≤','≥','≠','…'];
const P_SYM_R3_INNER: string[] = ['♠','♥','♦','♣','★','☆','✓','✗'];  // giữa 123 và BS

// ─────────────────────────────────────────────────────────
//  DỮ LIỆU HÀNG PHÍM – LANDSCAPE
// ─────────────────────────────────────────────────────────

const L_LTR_R0: string[] = ['1','2','3','4','5','6','7','8','9','0'];
const L_LTR_R1: string[] = ['q','w','e','r','t','y','u','i','o','p'];
const L_LTR_R2: string[] = ['a','s','d','f','g','h','j','k','l'];
const L_LTR_R3_INNER: string[] = ['z','x','c','v','b','n','m'];

const L_NUM_R0: string[] = ['1','2','3','4','5','6','7','8','9','0'];
const L_NUM_R1: string[] = ['-','/',':',';','(',')','\$','&','@','"'];
const L_NUM_R2: string[] = ['.',',','?','!','\'','=','*','#','%','^'];
const L_NUM_R3_INNER: string[] = ['©','®','™','°','§','¶','µ','∞'];

const L_SYM_R0: string[] = ['[',']','{','}','<','>','«','»','~','`'];
const L_SYM_R1: string[] = ['€','£','¥','₫','_','+','|','¢','₴','÷'];
const L_SYM_R2: string[] = ['←','→','↑','↓','½','≈','≤','≥','≠','±'];
const L_SYM_R3_INNER: string[] = ['♠','♥','♦','♣','×','…','✓','✗'];


const P_LAYOUTS: Map<KeyLayout, LayoutSpec> = new Map<KeyLayout, LayoutSpec>([
  [KeyLayout.LETTERS, new LayoutSpec(P_LTR_R0, P_LTR_R1, P_LTR_R2, P_LTR_R3_INNER, 'SHIFT', '123', null, KeyLayout.NUMBERS)],
  [KeyLayout.NUMBERS, new LayoutSpec(P_NUM_R0, P_NUM_R1, P_NUM_R2, P_NUM_R3_INNER, '#+=', 'ABC', KeyLayout.SYMBOLS, KeyLayout.LETTERS)],
  [KeyLayout.SYMBOLS, new LayoutSpec(P_SYM_R0, P_SYM_R1, P_SYM_R2, P_SYM_R3_INNER, '123', 'ABC', KeyLayout.NUMBERS, KeyLayout.LETTERS)]
]);

const L_LAYOUTS: Map<KeyLayout, LayoutSpec> = new Map<KeyLayout, LayoutSpec>([
  [KeyLayout.LETTERS, new LayoutSpec(L_LTR_R0, L_LTR_R1, L_LTR_R2, L_LTR_R3_INNER, 'SHIFT', '123', null, KeyLayout.NUMBERS)],
  [KeyLayout.NUMBERS, new LayoutSpec(L_NUM_R0, L_NUM_R1, L_NUM_R2, L_NUM_R3_INNER, '#+=', 'ABC', KeyLayout.SYMBOLS, KeyLayout.LETTERS)],
  [KeyLayout.SYMBOLS, new LayoutSpec(L_SYM_R0, L_SYM_R1, L_SYM_R2, L_SYM_R3_INNER, '123', 'ABC', KeyLayout.NUMBERS, KeyLayout.LETTERS)]
]);

// ─────────────────────────────────────────────────────────
//  EMOJI
// ─────────────────────────────────────────────────────────
const EMOJI_CATS: EmojiCategory[] = [
new EmojiCategory('smileys_people', '😀', [
'😀','😃','😄','😁','😆','😅','🤣','😂','🙂','🙃','🫠','😉','😊','😇','🥰','😍','🤩','😘','😗','☺️','😚','😙','🥲','😋','😛','😜','🤪','😝','🤑','🤗','🤭','🫢','🫣','🤫','🤔','🫡','🤐','🤨','😐','😑','😶','🫥','😶‍🌫️','😏','😒','🙄','😬','😮‍💨','🤥','🫨','🙂‍↔️','🙂‍↕️','😌','😔','😪','🤤','😴','🫩','😷','🤒','🤕','🤢','🤮','🤧','🥵','🥶','🥴','😵','😵‍💫','🤯','🤠','🥳','🥸','😎','🤓','🧐','😕','🫤','😟','🙁','☹️','😮','😯','😲','😳','🥺','🥹','😦','😧','😨','😰','😥','😢','😭','😱','😖','😣','😞','😓','😩','😫','🥱','😤','😡','😠','🤬','😈','👿','💀','☠️','💩','🤡','👹','👺','👻','👽','👾','🤖','😺','😸','😹','😻','😼','😽','🙀','😿','😾',
'🙈','🙉','🙊','💋','💯','💢','💥','💫','💦','💨','🕳️','💤',
'👋','🤚','🖐️','✋','🖖','🫱','🫲','🫳','🫴','🫷','🫸','👌','🤌','🤏','✌️','🤞','🫰','🤟','🤘','🤙','👈','👉','👆','🖕','👇','☝️','🫵','👍','👎','✊','👊','🤛','🤜','👏','🙌','🫶','👐','🤲','🤝','🙏','✍️','💅','🤳','💪','🦾','🦿','🦵','🦶','👂','🦻','👃','🧠','🫀','🫁','🦷','🦴','👀','👁️','👅','👄','🫦',
'👶','🧒','👦','👧','🧑','👱','👨','🧔','👨‍🦰','👨‍🦱','👨‍🦳','👨‍🦲','👩','👩‍🦰','🧑‍🦰','👩‍🦱','🧑‍🦱','👩‍🦳','🧑‍🦳','👩‍🦲','🧑‍🦲','👱‍♀️','👱‍♂️','🧓','👴','👵',
'🙍','🙍‍♂️','🙍‍♀️','🙎','🙎‍♂️','🙎‍♀️','🙅','🙅‍♂️','🙅‍♀️','🙆','🙆‍♂️','🙆‍♀️','💁','💁‍♂️','💁‍♀️','🙋','🙋‍♂️','🙋‍♀️','🧏','🧏‍♂️','🧏‍♀️','🙇','🙇‍♂️','🙇‍♀️','🤦','🤦‍♂️','🤦‍♀️','🤷','🤷‍♂️','🤷‍♀️',
'🫅','🤴','👸','👳','👲','🧕','🤵','👰','🤰','🤱','👩‍🍼','👨‍🍼','🧑‍🍼','💃','🕺','🛀','🛌',
'🧑‍🤝‍🧑','👭','👫','👬','💏','👩‍❤️‍💋‍👨','👨‍❤️‍💋‍👨','👩‍❤️‍💋‍👩','💑','👩‍❤️‍👨','👨‍❤️‍👨','👩‍❤️‍👩',
'💌','💘','💝','💖','💗','💓','💞','💕','💟','❣️','💔','❤️‍🔥','❤️‍🩹','❤️','🩷','🧡','💛','💚','💙','🩵','💜','🤎','🖤','🩶','🤍'
]),

new EmojiCategory('animals_nature', '🐶', [
'🐵','🐒','🦍','🦧','🐶','🐕','🦮','🐕‍🦺','🐩','🐺','🦊','🦝','🐱','🐈','🐈‍⬛','🦁','🐯','🐅','🐆','🐴','🫎','🫏','🐎','🦄','🦓','🦌','🦬','🐮','🐂','🐃','🐄','🐷','🐖','🐗','🐽','🐏','🐑','🐐','🐪','🐫','🦙','🦒','🐘','🦣','🦏','🦛','🐭','🐁','🐀','🐹','🐰','🐇','🐿️','🦫','🦔','🦇','🐻','🐻‍❄️','🐨','🐼','🦥','🦦','🦨','🦘','🦡','🐾',
'🦃','🐔','🐓','🐣','🐤','🐥','🐦','🐧','🕊️','🦅','🦆','🦢','🦉','🦤','🪶','🦩','🦚','🦜','🪽','🐦‍⬛','🪿','🐦‍🔥',
'🐸','🐊','🐢','🦎','🐍','🐲','🐉','🦕','🦖','🐳','🐋','🐬','🦭','🐟','🐠','🐡','🦈','🐙','🐚','🪸','🪼','🦀','🦞','🦐','🦑','🦪','🐌','🦋','🐛','🐜','🐝','🪲','🐞','🦗','🪳','🕷️','🕸️','🦂','🦟','🪰','🪱','🦠',
'💐','🌸','💮','🪷','🏵️','🌹','🥀','🌺','🌻','🌼','🌷','🪻','🌱','🪴','🌲','🌳','🌴','🌵','🌾','🌿','☘️','🍀','🍁','🍂','🍃','🪹','🪺','🍄','🪾'
]),

new EmojiCategory('food_drink', '🍔', [
'🍇','🍈','🍉','🍊','🍋','🍋‍🟩','🍌','🍍','🥭','🍎','🍏','🍐','🍑','🍒','🍓','🫐','🥝','🍅','🫒','🥥','🥑','🍆','🥔','🥕','🌽','🌶️','🫑','🥒','🥬','🥦','🧄','🧅','🥜','🫘','🌰','🫚','🫛','🍄‍🟫','🫜',
'🍞','🥐','🥖','🫓','🥨','🥯','🥞','🧇','🧀',
'🍖','🍗','🥩','🥓','🍔','🍟','🍕','🌭','🥪','🌮','🌯','🫔','🥙','🧆','🥚','🍳','🥘','🍲','🫕','🥣','🥗','🍿','🧈','🧂','🥫',
'🍱','🍘','🍙','🍚','🍛','🍜','🍝','🍠','🍢','🍣','🍤','🍥','🥮','🍡','🥟','🥠','🥡',
'🍦','🍧','🍨','🍩','🍪','🎂','🍰','🧁','🥧','🍫','🍬','🍭','🍮','🍯',
'🍼','🥛','☕','🫖','🍵','🍶','🍾','🍷','🍸','🍹','🍺','🍻','🥂','🥃','🫗','🥤','🧋','🧃','🧉','🧊',
'🥢','🍽️','🍴','🥄','🔪','🫙','🏺'
]),

new EmojiCategory('activities', '⚽', [
'🎃','🎄','🎆','🎇','🧨','✨','🎈','🎉','🎊','🎋','🎍','🎎','🎏','🎐','🎑','🧧','🎀','🎁','🎗️','🎟️','🎫','🎖️','🏆','🏅','🥇','🥈','🥉',
'⚽','⚾','🥎','🏀','🏐','🏈','🏉','🎾','🥏','🎳','🏏','🏑','🏒','🥍','🏓','🏸','🥊','🥋','🥅','⛳','⛸️','🎣','🤿','🎽','🎿','🛷','🥌','🎯','🪀','🪁','🔫','🎱','🔮','🪄','🎮','🕹️','🎰','🎲','🧩','🧸','🪅','🪩','🪆','♠️','♥️','♦️','♣️','♟️','🃏','🀄','🎴','🎭','🖼️','🎨','🧵','🪡','🧶','🪢',
'🧑‍⚕️','👨‍⚕️','👩‍⚕️','🧑‍🎓','👨‍🎓','👩‍🎓','🧑‍🏫','👨‍🏫','👩‍🏫','🧑‍⚖️','👨‍⚖️','👩‍⚖️','🧑‍🌾','👨‍🌾','👩‍🌾','🧑‍🍳','👨‍🍳','👩‍🍳','🧑‍🔧','👨‍🔧','👩‍🔧','🧑‍🏭','👨‍🏭','👩‍🏭','🧑‍💼','👨‍💼','👩‍💼','🧑‍🔬','👨‍🔬','👩‍🔬','🧑‍💻','👨‍💻','👩‍💻','🧑‍🎤','👨‍🎤','👩‍🎤','🧑‍🎨','👨‍🎨','👩‍🎨','🧑‍✈️','👨‍✈️','👩‍✈️','🧑‍🚀','👨‍🚀','👩‍🚀','🧑‍🚒','👨‍🚒','👩‍🚒',
'👮','👮‍♂️','👮‍♀️','🕵️','🕵️‍♂️','🕵️‍♀️','💂','💂‍♂️','💂‍♀️','🥷','👷','👷‍♂️','👷‍♀️','👼','🎅','🤶','🧑‍🎄','🦸','🦸‍♂️','🦸‍♀️','🦹','🦹‍♂️','🦹‍♀️','🧙','🧙‍♂️','🧙‍♀️','🧚','🧚‍♂️','🧚‍♀️','🧛','🧛‍♂️','🧛‍♀️','🧜','🧜‍♂️','🧜‍♀️','🧝','🧝‍♂️','🧝‍♀️','🧞','🧞‍♂️','🧞‍♀️','🧟','🧟‍♂️','🧟‍♀️','🧌',
'🧔','🧔‍♂️','🧔‍♀️','👳','👳‍♂️','👳‍♀️','🤵','🤵‍♂️','🤵‍♀️','👰','👰‍♂️','👰‍♀️','🤰','🫃','🫄','💆','💆‍♂️','💆‍♀️',
'🚶','🚶‍♂️','🚶‍♀️','🚶‍➡️','🚶‍♀️‍➡️','🚶‍♂️‍➡️','🧍','🧍‍♂️','🧍‍♀️','🧎','🧎‍♂️','🧎‍♀️','🧎‍➡️','🧎‍♀️‍➡️','🧎‍♂️‍➡️',
'🧑‍🦯','🧑‍🦯‍➡️','👨‍🦯','👨‍🦯‍➡️','👩‍🦯','👩‍🦯‍➡️','🧑‍🦼','🧑‍🦼‍➡️','👨‍🦼','👨‍🦼‍➡️','👩‍🦼','👩‍🦼‍➡️','🧑‍🦽','🧑‍🦽‍➡️','👨‍🦽','👨‍🦽‍➡️','👩‍🦽','👩‍🦽‍➡️',
'🏃','🏃‍♂️','🏃‍♀️','🏃‍➡️','🏃‍♀️‍➡️','🏃‍♂️‍➡️','💇','💇‍♂️','💇‍♀️','🕴️','👯','👯‍♂️','👯‍♀️','🧖','🧖‍♂️','🧖‍♀️','🧗','🧗‍♂️','🧗‍♀️','🤺','🏇','⛷️','🏂','🏌️','🏌️‍♂️','🏌️‍♀️','🏄','🏄‍♂️','🏄‍♀️','🚣','🚣‍♂️','🚣‍♀️','🏊','🏊‍♂️','🏊‍♀️','⛹️','⛹️‍♂️','⛹️‍♀️','🏋️','🏋️‍♂️','🏋️‍♀️','🚴','🚴‍♂️','🚴‍♀️','🚵','🚵‍♂️','🚵‍♀️','🤸','🤸‍♂️','🤸‍♀️','🤼','🤼‍♂️','🤼‍♀️','🤽','🤽‍♂️','🤽‍♀️','🤾','🤾‍♂️','🤾‍♀️','🤹','🤹‍♂️','🤹‍♀️','🧘','🧘‍♂️','🧘‍♀️'
]),

new EmojiCategory('travel_places', '🌍', [
'🌍','🌎','🌏','🌐','🗺️','🗾','🧭','🏔️','⛰️','🌋','🗻','🏕️','🏖️','🏜️','🏝️','🏞️','🏟️','🏛️','🏗️','🧱','🪨','🪵','🛖','🏘️','🏚️','🏠','🏡','🏢','🏣','🏤','🏥','🏦','🏨','🏩','🏪','🏫','🏬','🏭','🏯','🏰','💒','🗼','🗽','⛪','🕌','🛕','🕍','⛩️','🕋','⛲','⛺','🌁','🌃','🏙️','🌄','🌅','🌆','🌇','🌉','♨️','🎠','🛝','🎡','🎢','💈','🎪',
'🚂','🚃','🚄','🚅','🚆','🚇','🚈','🚉','🚊','🚝','🚞','🚋','🚌','🚍','🚎','🚐','🚑','🚒','🚓','🚔','🚕','🚖','🚗','🚘','🚙','🛻','🚚','🚛','🚜','🏎️','🏍️','🛵','🦽','🦼','🛺','🚲','🛴','🛹','🛼','🚏','🛣️','🛤️','🛢️','⛽','🛞','🚨','🚥','🚦','🛑','🚧',
'⚓','🛟','⛵','🛶','🚤','🛳️','⛴️','🛥️','🚢','✈️','🛩️','🛫','🛬','🪂','💺','🚁','🚟','🚠','🚡','🛰️','🚀','🛸','🛎️','🧳',
'⌛','⏳','⌚','⏰','⏱️','⏲️','🕰️','🕛','🕧','🕐','🕜','🕑','🕝','🕒','🕞','🕓','🕟','🕔','🕠','🕕','🕡','🕖','🕢','🕗','🕣','🕘','🕤','🕙','🕥','🕚','🕦',
'🌑','🌒','🌓','🌔','🌕','🌖','🌗','🌘','🌙','🌚','🌛','🌜','🌡️','☀️','🌝','🌞','🪐','⭐','🌟','🌠','🌌','☁️','⛅','⛈️','🌤️','🌥️','🌦️','🌧️','🌨️','🌩️','🌪️','🌫️','🌬️','🌀','🌈','🌂','☂️','☔','⛱️','⚡','❄️','☃️','⛄','☄️','🔥','💧','🌊'
]),

new EmojiCategory('objects', '📱', [
'👓','🕶️','🥽','🥼','🦺','👔','👕','👖','🧣','🧤','🧥','🧦','👗','👘','🥻','🩱','🩲','🩳','👙','👚','🪭','👛','👜','👝','🛍️','🎒','🩴','👞','👟','🥾','🥿','👠','👡','🩰','👢','🪮','👑','👒','🎩','🎓','🧢','🪖','⛑️','📿','💄','💍','💎',
'🔇','🔈','🔉','🔊','📢','📣','📯','🔔','🔕','🎼','🎵','🎶','🎙️','🎚️','🎛️','🎤','🎧','📻','🎷','🪗','🎸','🎹','🎺','🎻','🪕','🥁','🪘','🪇','🪈','🪉',
'📱','📲','☎️','📞','📟','📠','🔋','🪫','🔌','💻','🖥️','🖨️','⌨️','🖱️','🖲️','💽','💾','💿','📀','🧮','🎥','🎞️','📽️','🎬','📺','📷','📸','📹','📼','🔍','🔎','🕯️','💡','🔦','🏮','🪔',
'📔','📕','📖','📗','📘','📙','📚','📓','📒','📃','📜','📄','📰','🗞️','📑','🔖','🏷️',
'💰','🪙','💴','💵','💶','💷','💸','💳','🧾','💹',
'✉️','📧','📨','📩','📤','📥','📦','📫','📪','📬','📭','📮','🗳️',
'✏️','✒️','🖋️','🖊️','🖌️','🖍️','📝','💼','📁','📂','🗂️','📅','📆','🗒️','🗓️','📇','📈','📉','📊','📋','📌','📍','📎','🖇️','📏','📐','✂️','🗃️','🗄️','🗑️',
'🔒','🔓','🔏','🔐','🔑','🗝️','🔨','🪓','⛏️','⚒️','🛠️','🗡️','⚔️','💣','🪃','🏹','🛡️','🪚','🔧','🪛','🔩','⚙️','🗜️','⚖️','🦯','🔗','⛓️‍💥','⛓️','🪝','🧰','🧲','🪜','🪏',
'⚗️','🧪','🧫','🧬','🔬','🔭','📡','💉','🩸','💊','🩹','🩼','🩺','🩻',
'🚪','🛗','🪞','🪟','🛏️','🛋️','🪑','🚽','🪠','🚿','🛁','🪤','🪒','🧴','🧷','🧹','🧺','🧻','🪣','🧼','🫧','🪥','🧽','🧯','🛒','🚬','⚰️','🪦','⚱️','🧿','🪬','🗿','🪧','🪪'
]),

new EmojiCategory('symbols', '✅', [
'🏧','🚮','🚰','♿','🚹','🚺','🚻','🚼','🚾','🛂','🛃','🛄','🛅','🗣️','👤','👥','🫂','👣','🫆','⚠️','🚸','⛔','🚫','🚳','🚭','🚯','🚱','🚷','📵','🔞','☢️','☣️',
'⬆️','↗️','➡️','↘️','⬇️','↙️','⬅️','↖️','↕️','↔️','↩️','↪️','⤴️','⤵️','🔃','🔄','🔙','🔚','🔛','🔜','🔝','🛐',
'⚛️','🕉️','✡️','☸️','☯️','✝️','☦️','☪️','☮️','🕎','🔯','🪯',
'♈','♉','♊','♋','♌','♍','♎','♏','♐','♑','♒','♓','⛎',
'🔀','🔁','🔂','▶️','⏩','⏭️','⏯️','◀️','⏪','⏮️','🔼','⏫','🔽','⏬','⏸️','⏹️','⏺️','⏏️','🎦',
'🔅','🔆','📶','🛜','📳','📴','♀️','♂️','⚧️','✖️','➕','➖','➗','🟰','♾️','‼️','⁉️','❓','❔','❕','❗','〰️','💱','💲','⚕️','♻️','⚜️','🔱','📛','🔰','⭕','✅','☑️','✔️','❌','❎','➰','➿','〽️','✳️','✴️','❇️','©️','®️','™️','🫟',
'#️⃣','*️⃣','0️⃣','1️⃣','2️⃣','3️⃣','4️⃣','5️⃣','6️⃣','7️⃣','8️⃣','9️⃣','🔟',
'🔠','🔡','🔢','🔣','🔤','🅰️','🆎','🅱️','🆑','🆒','🆓','ℹ️','🆔','Ⓜ️','🆕','🆖','🅾️','🆗','🅿️','🆘','🆙','🆚',
'🈁','🈂️','🈷️','🈶','🈯','🉐','🈹','🈚','🈲','🉑','🈸','🈴','🈳','㊗️','㊙️','🈺','🈵',
'🔴','🟠','🟡','🟢','🔵','🟣','🟤','⚫','⚪','🟥','🟧','🟨','🟩','🟦','🟪','🟫','⬛','⬜','◼️','◻️','◾','◽','▪️','▫️','🔶','🔷','🔸','🔹','🔺','🔻','💠','🔘','🔳','🔲',
'💬','👁️‍🗨️','🗨️','🗯️','💭',
'👨‍👩‍👦','👨‍👩‍👧','👨‍👩‍👧‍👦','👨‍👩‍👦‍👦','👨‍👩‍👧‍👧','👨‍👨‍👦','👨‍👨‍👧','👨‍👨‍👧‍👦','👨‍👨‍👦‍👦','👨‍👨‍👧‍👧','👩‍👩‍👦','👩‍👩‍👧','👩‍👩‍👧‍👦','👩‍👩‍👦‍👦','👩‍👩‍👧‍👧','👨‍👦','👨‍👦‍👦','👨‍👧','👨‍👧‍👦','👨‍👧‍👧','👩‍👦','👩‍👦‍👦','👩‍👧','👩‍👧‍👦','👩‍👧‍👧','👪','🧑‍🧑‍🧒','🧑‍🧑‍🧒‍🧒','🧑‍🧒','🧑‍🧒‍🧒'
]),

new EmojiCategory('flags', '🇻🇳', [
'🏁','🚩','🎌','🏴','🏳️','🏳️‍🌈','🏳️‍⚧️','🏴‍☠️',
'🇦🇨','🇦🇩','🇦🇪','🇦🇫','🇦🇬','🇦🇮','🇦🇱','🇦🇲','🇦🇴','🇦🇶','🇦🇷','🇦🇸','🇦🇹','🇦🇺','🇦🇼','🇦🇽','🇦🇿',
'🇧🇦','🇧🇧','🇧🇩','🇧🇪','🇧🇫','🇧🇬','🇧🇭','🇧🇮','🇧🇯','🇧🇱','🇧🇲','🇧🇳','🇧🇴','🇧🇶','🇧🇷','🇧🇸','🇧🇹','🇧🇻','🇧🇼','🇧🇾','🇧🇿',
'🇨🇦','🇨🇨','🇨🇩','🇨🇫','🇨🇬','🇨🇭','🇨🇮','🇨🇰','🇨🇱','🇨🇲','🇨🇳','🇨🇴','🇨🇵','🇨🇶','🇨🇷','🇨🇺','🇨🇻','🇨🇼','🇨🇽','🇨🇾','🇨🇿',
'🇩🇪','🇩🇬','🇩🇯','🇩🇰','🇩🇲','🇩🇴','🇩🇿',
'🇪🇦','🇪🇨','🇪🇪','🇪🇬','🇪🇭','🇪🇷','🇪🇸','🇪🇹','🇪🇺',
'🇫🇮','🇫🇯','🇫🇰','🇫🇲','🇫🇴','🇫🇷',
'🇬🇦','🇬🇧','🇬🇩','🇬🇪','🇬🇫','🇬🇬','🇬🇭','🇬🇮','🇬🇱','🇬🇲','🇬🇳','🇬🇵','🇬🇶','🇬🇷','🇬🇸','🇬🇹','🇬🇺','🇬🇼','🇬🇾',
'🇭🇰','🇭🇲','🇭🇳','🇭🇷','🇭🇹','🇭🇺',
'🇮🇨','🇮🇩','🇮🇪','🇮🇱','🇮🇲','🇮🇳','🇮🇴','🇮🇶','🇮🇷','🇮🇸','🇮🇹',
'🇯🇪','🇯🇲','🇯🇴','🇯🇵',
'🇰🇪','🇰🇬','🇰🇭','🇰🇮','🇰🇲','🇰🇳','🇰🇵','🇰🇷','🇰🇼','🇰🇾','🇰🇿',
'🇱🇦','🇱🇧','🇱🇨','🇱🇮','🇱🇰','🇱🇷','🇱🇸','🇱🇹','🇱🇺','🇱🇻','🇱🇾',
'🇲🇦','🇲🇨','🇲🇩','🇲🇪','🇲🇫','🇲🇬','🇲🇭','🇲🇰','🇲🇱','🇲🇲','🇲🇳','🇲🇴','🇲🇵','🇲🇶','🇲🇷','🇲🇸','🇲🇹','🇲🇺','🇲🇻','🇲🇼','🇲🇽','🇲🇾','🇲🇿',
'🇳🇦','🇳🇨','🇳🇪','🇳🇫','🇳🇬','🇳🇮','🇳🇱','🇳🇴','🇳🇵','🇳🇷','🇳🇺','🇳🇿',
'🇴🇲',
'🇵🇦','🇵🇪','🇵🇫','🇵🇬','🇵🇭','🇵🇰','🇵🇱','🇵🇲','🇵🇳','🇵🇷','🇵🇸','🇵🇹','🇵🇼','🇵🇾',
'🇶🇦',
'🇷🇪','🇷🇴','🇷🇸','🇷🇺','🇷🇼',
'🇸🇦','🇸🇧','🇸🇨','🇸🇩','🇸🇪','🇸🇬','🇸🇭','🇸🇮','🇸🇯','🇸🇰','🇸🇱','🇸🇲','🇸🇳','🇸🇴','🇸🇷','🇸🇸','🇸🇹','🇸🇻','🇸🇽','🇸🇾','🇸🇿',
'🇹🇦','🇹🇨','🇹🇩','🇹🇫','🇹🇬','🇹🇭','🇹🇯','🇹🇰','🇹🇱','🇹🇲','🇹🇳','🇹🇴','🇹🇷','🇹🇹','🇹🇻','🇹🇼','🇹🇿',
'🇺🇦','🇺🇬','🇺🇲','🇺🇳','🇺🇸','🇺🇾','🇺🇿',
'🇻🇦','🇻🇨','🇻🇪','🇻🇬','🇻🇮','🇻🇳','🇻🇺',
'🇼🇫','🇼🇸',
'🇽🇰',
'🇾🇪','🇾🇹',
'🇿🇦','🇿🇲','🇿🇼',
'🏴','🏴','🏴'
]),

new EmojiCategory('monochrome', '☺︎', [
'☺︎','☹︎','☠︎','❣︎','❤︎','☘︎','⛸︎','♠︎','♥︎','♦︎','♣︎','♟︎','⛷︎','⛰︎','⛩︎','♨︎','⛴︎','✈︎','☀︎','⏱︎','⏲︎','☁︎','⛈︎','☂︎','⛱︎','❄︎','☃︎','☄︎','⛑︎','☎︎','⌨︎','✏︎','✒︎','✉︎','✂︎','⛏︎','⚒︎','⚔︎','⚙︎','⚖︎','⛓︎','⚗︎','⚰︎','⚱︎','⚠︎','☢︎','☣︎','⬆︎','↗︎','➡︎','↘︎','⬇︎','↙︎','⬅︎','↖︎','↕︎','↔︎','↩︎','↪︎','⤴︎','⤵︎','⚛︎','✡︎','☸︎','☯︎','✝︎','☦︎','☪︎','☮︎','▶︎','⏭︎','⏯︎','◀︎','⏮︎','⏸︎','⏹︎','⏺︎','⏏︎','♀︎','♂︎','⚧︎','✖︎','♾︎','‼︎','⁉︎','⚕︎','♻︎','⚜︎','☑︎','✔︎','〽︎','✳︎','✴︎','❇︎','©︎','®︎','™︎','🅰︎','🅱︎','ℹ︎','Ⓜ︎','🅾︎','🅿︎','🈂︎','🈷︎','㊗︎','㊙︎','◼︎','◻︎','▪︎','▫︎'
])
];

const MODE_OPTIONS: ModeOption[] = [
  new ModeOption('Telex', InputMode.TELEX),
  new ModeOption('Telex gọn', InputMode.TELEX_SIMPLE),
  new ModeOption('VNI', InputMode.VNI),
  new ModeOption('VNI gọn', InputMode.VNI_SIMPLE),
  new ModeOption('Tiếng Anh', InputMode.ENGLISH)
];

const TRANSLATE_LANGS: string[] = ['Tự động', 'Tiếng Việt', 'Tiếng Anh', 'Tiếng Nhật', 'Tiếng Hàn', 'Tiếng Trung'];

const STICKER_ITEMS: StickerItem[] = [
  new StickerItem('Xin chào', '👋'),
  new StickerItem('Cảm ơn', '🙏'),
  new StickerItem('Đồng ý', '✅'),
  new StickerItem('Yêu thích', '❤️'),
  new StickerItem('Chúc mừng', '🎉'),
  new StickerItem('Cười', '😂')
];

@Entry
@Component
struct KeyboardPage {
  @StorageLink(KEY_INPUT_MODE)      inputMode: InputMode       = InputMode.TELEX;
  @StorageLink(KEY_COMPOSING)       composingText: string      = '';
  @StorageLink(KEY_CANDIDATES)      candidates: string[]       = [];
  @StorageLink(KEY_IS_SHIFTED)      isShifted: boolean         = false;
  @StorageLink(KEY_SHOW_CLIPBOARD)  showClipboard: boolean     = false;
  @StorageLink(KEY_CLIPBOARD_ITEMS) clipboardItems: ClipboardItem[] = [];
  @StorageLink(KEY_CLIPBOARD_STATUS) clipboardStatus: string   = '';
  @StorageLink(KEY_IS_LANDSCAPE)    isLandscape: boolean       = false;
  @StorageLink(KEY_PANEL_HEIGHT_VP) panelVp: number            = 280;

  @State layout: KeyLayout = KeyLayout.LETTERS;
  @State pressedKey: string = '';
  @State showEmoji: boolean = false;
  @State emojiCat: number = 0;
  @State layoutBeforeEmoji: KeyLayout = KeyLayout.LETTERS;
  @State activePanel: TaskPanel = TaskPanel.NONE;
  @State stickerGrid: boolean = true;
  @State translateInput: string = '';
  @State translateOutput: string = 'Đang phát triển: dịch tự động sẽ hiển thị tại đây.';
  @State translateSourceLangIndex: number = 0;
  @State translateTargetLangIndex: number = 2;
  @State translateEnabled: boolean = false;
  @State clipboardEnabled: boolean = true;
  @State vibrationEnabled: boolean = true;
  @State keySoundEnabled: boolean = false;
  @State keySizeLabel: string = 'Vừa';
  @State inputLanguageIndex: number = 0;
  @State themeColor: string = '#1E1E1E';
  @State devNotice: string = '';
  @State showDevelopingPopup: boolean = false;
  @State developingFeature: string = '';
  @State accentPopupVisible: boolean = false;
  @State accentPopupKey: string = '';
  @State accentPopupChars: string[] = [];

  private lastShiftTapAt: number = 0;
  private shiftTouchDownAt: number = 0;
  private shiftLongHandled: boolean = false;
  private accentHoldTimeoutId: number = -1;
  private accentLongHandled: boolean = false;
  private accentOutsideKeyPending: string = '';
  private accentOutsideActionPending: boolean = false;
  private backspaceHoldTimeoutId: number = -1;
  private backspaceWordTimeoutId: number = -1;
  private backspaceRepeatIntervalId: number = -1;
  private backspaceRepeating: boolean = false;
  private readonly backspaceRepeatDelayMs: number = 260;
  private readonly backspaceRepeatMs: number = 45;
  private readonly backspaceWordDelayMs: number = 3000;
  private readonly backspaceWordRepeatMs: number = 150;

  // ── Theme ──
  @StorageLink(GTV_DARK_MODE_KEY) darkMode: boolean = DEFAULT_KEYBOARD_DARK_MODE;
  @StorageLink(GTV_BG_COLOR_KEY) bgBase: string = DEFAULT_KEYBOARD_BG_COLOR;
  @StorageLink(GTV_KEY_COLOR_KEY) keyBase: string = DEFAULT_KEYBOARD_KEY_COLOR;
  @StorageLink(GTV_BG_OPACITY_KEY) bgOpacity: number = DEFAULT_KEYBOARD_OPACITY;
  @StorageLink(GTV_KEY_OPACITY_KEY) keyOpacity: number = DEFAULT_KEYBOARD_KEY_OPACITY;
  @StorageLink(GTV_SHOW_NUMBER_ROW_KEY) showNumberRow: boolean = true;

  private kbTheme(): VirtualKeyboardTheme {
    return getVirtualKeyboardTheme(this.bgBase, this.keyBase, this.darkMode);
  }

  get bg(): string { return this.kbTheme().bgColor; }
  get keyN(): string { return this.kbTheme().keyBg; }
  get keyS(): string { return this.kbTheme().specialBg; }
  get keyAcc(): string { return this.kbTheme().pressedBg; }
  get txt(): string { return this.kbTheme().textColor; }
  get mutedTxt(): string { return this.kbTheme().mutedTextColor; }

  // Cấu hình hiện tại (thay đổi theo hướng)
  private get c(): KBCfg | KBCfgLandscape {
    return this.isLandscape ? CFG_L : CFG_P;
  }

  private getKeyScale(): number {
    if (this.keySizeLabel === 'Nhỏ') {
      return 0.88;
    }
    if (this.keySizeLabel === 'Lớn') {
      return 1.14;
    }
    return 1.0;
  }

  private scaleKeyNumber(value: number): number {
    return Math.round(value * this.getKeyScale() * 10) / 10;
  }

  private getKeyHeight(landscape: boolean): string {
    if (this.keySizeLabel === 'Nhỏ') {
      return landscape ? '75.6%' : '77.4%';
    }
    if (this.keySizeLabel === 'Lớn') {
      return landscape ? '88.2%' : '89.1%';
    }
    return landscape ? CFG_L.kH : CFG_P.kH;
  }

  private getKeyMarginH(landscape: boolean): number {
    return this.scaleKeyNumber(landscape ? CFG_L.mH : CFG_P.mH);
  }

  private getKeyMarginV(landscape: boolean): number {
    return this.scaleKeyNumber(landscape ? CFG_L.mV : CFG_P.mV);
  }

  private getKeyRadius(landscape: boolean): number {
    return this.scaleKeyNumber(landscape ? CFG_L.rKey : CFG_P.rKey);
  }

  private getSpaceRadius(landscape: boolean): number {
    return this.scaleKeyNumber(landscape ? CFG_L.rSpace : CFG_P.rSpace);
  }

  private getNormalKeyFontSize(landscape: boolean): number {
    return Math.round((landscape ? CFG_L.fs : CFG_P.fs) * this.getKeyScale());
  }

  private getSpecialKeyFontSize(landscape: boolean): number {
    return Math.round((landscape ? CFG_L.fsS : CFG_P.fsS) * this.getKeyScale());
  }

  private getEnterKeyFontSize(landscape: boolean): number {
    return Math.round((landscape ? 18 : 20) * this.getKeyScale());
  }

  aboutToAppear(): void {
    try {
      const d = display.getDefaultDisplaySync();
      this.isLandscape = d.width > d.height;
    } catch (_) {
      this.isLandscape = false;
    }

    this.refreshThemeSettings();
  }

  onPageShow(): void {
    this.refreshThemeSettings();
  }

  private async refreshThemeSettings(): Promise<void> {
    try {
      await PreferencesManager.init(getContext(this), true);

      const bgOpacity = await PreferencesManager.get(GTV_BG_OPACITY_KEY, DEFAULT_KEYBOARD_OPACITY) as number;
      const keyOpacity = await PreferencesManager.get(GTV_KEY_OPACITY_KEY, DEFAULT_KEYBOARD_KEY_OPACITY) as number;
      const bgColor = await PreferencesManager.get(GTV_BG_COLOR_KEY, DEFAULT_KEYBOARD_BG_COLOR) as string;
      const keyColor = await PreferencesManager.get(GTV_KEY_COLOR_KEY, DEFAULT_KEYBOARD_KEY_COLOR) as string;
      const darkMode = await PreferencesManager.get(GTV_DARK_MODE_KEY, DEFAULT_KEYBOARD_DARK_MODE) as boolean;
      const showNumberRow = await PreferencesManager.get(GTV_SHOW_NUMBER_ROW_KEY, true) as boolean;

      AppStorage.setOrCreate(GTV_BG_OPACITY_KEY, bgOpacity);
      AppStorage.setOrCreate(GTV_KEY_OPACITY_KEY, keyOpacity);
      AppStorage.setOrCreate(GTV_BG_COLOR_KEY, bgColor);
      AppStorage.setOrCreate(GTV_KEY_COLOR_KEY, keyColor);
      AppStorage.setOrCreate(GTV_DARK_MODE_KEY, darkMode);
      AppStorage.setOrCreate(GTV_SHOW_NUMBER_ROW_KEY, showNumberRow);
    } catch (err) {
      console.error('[KeyboardPage] refreshThemeSettings failed:', err);
    }
  }

  private saveThemeSetting(key: string, value: preferences.ValueType): void {
    AppStorage.setOrCreate(key, value);
    PreferencesManager.set(key, value).catch((err: Error) => {
      console.error('[GoTiengViet] save theme setting failed:', err.message);
    });
  }

  // ── Helpers ──
  isSpecial(k: string): boolean {
    return ['SHIFT','BACKSPACE','SPACE','ENTER','NUMBERS','SYMBOLS','LETTERS',
            '#+=','123','ABC','⌫','⇧','⬆'].includes(k);
  }

  lbl(k: string): string {
    switch (k) {
      case 'SHIFT':     return this.isShifted ? '⬆' : '⇧';
      case 'BACKSPACE': return '⌫';
      default:
        return (this.layout === KeyLayout.LETTERS && this.isShifted) ? k.toUpperCase() : k;
    }
  }

  handleShiftTap(): void {
    const now = Date.now();
    if (now - this.lastShiftTapAt <= 350) {
      KeyboardBridge.sendCapsLock();
      this.lastShiftTapAt = 0;
      this.shiftLongHandled = false;
      return;
    }
    this.lastShiftTapAt = now;
    KeyboardBridge.sendShift();
  }

  handleShiftLongPress(): void {
    this.shiftLongHandled = true;
    this.lastShiftTapAt = 0;
    KeyboardBridge.sendCapsLock();
  }

  bgK(k: string, keyBase: string): string {
    return getVirtualKeyboardKeyBg(k, getVirtualKeyboardTheme(this.bgBase, keyBase, this.darkMode),
      this.pressedKey, this.isShifted, this.isSpecial(k));
  }

  tap(k: string): void {
    this.closeAccentPopup();
    this.pressedKey = k;
    this.handleKey(k);
    setTimeout(() => { this.pressedKey = ''; }, 100);
  }

  onKeyTouch(k: string, event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      if (this.consumeAccentOutsideKeyDown(k)) {
        return;
      }
      this.startAccentHold(k);
      return;
    }
    if (event.type === TouchType.Up) {
      if (this.accentOutsideKeyPending === k) {
        this.accentOutsideKeyPending = '';
        return;
      }
      this.finishAccentTouch(k, false);
      return;
    }
    if (event.type === TouchType.Cancel) {
      if (this.accentOutsideKeyPending === k) {
        this.accentOutsideKeyPending = '';
        return;
      }
      this.finishAccentTouch(k, true);
    }
  }

  private getAccentChars(k: string): string[] {
    if (this.layout !== KeyLayout.LETTERS) {
      return [];
    }

    switch (k.toLowerCase()) {
      case 'a': return ['á', 'à', 'ả', 'ã', 'ạ', 'â', 'ấ', 'ầ', 'ẩ', 'ẫ', 'ậ', 'ă', 'ắ', 'ằ', 'ẳ', 'ẵ', 'ặ'];
      case 'e': return ['é', 'è', 'ẻ', 'ẽ', 'ẹ', 'ê', 'ế', 'ề', 'ể', 'ễ', 'ệ'];
      case 'i': return ['í', 'ì', 'ỉ', 'ĩ', 'ị'];
      case 'o': return ['ó', 'ò', 'ỏ', 'õ', 'ọ', 'ô', 'ố', 'ồ', 'ổ', 'ỗ', 'ộ', 'ơ', 'ớ', 'ờ', 'ở', 'ỡ', 'ợ'];
      case 'u': return ['ú', 'ù', 'ủ', 'ũ', 'ụ', 'ư', 'ứ', 'ừ', 'ử', 'ữ', 'ự'];
      case 'y': return ['ý', 'ỳ', 'ỷ', 'ỹ', 'ỵ'];
      case 'd': return ['đ'];

      // case 'A': return ['Á', 'À', 'Ả', 'Ã', 'Ạ', 'Â', 'Ấ', 'Ầ', 'Ẩ', 'Ẫ', 'Ậ', 'Ă', 'Ắ', 'Ằ', 'Ẳ', 'Ẵ', 'Ặ'];
      // case 'E': return ['É', 'È', 'Ẻ', 'Ẽ', 'Ẹ', 'Ê', 'Ế', 'Ề', 'Ể', 'Ễ', 'Ệ'];
      // case 'I': return ['Í', 'Ì', 'Ỉ', 'Ĩ', 'Ị'];
      // case 'O': return ['Ó', 'Ò', 'Ỏ', 'Õ', 'Ọ', 'Ô', 'Ố', 'Ồ', 'Ổ', 'Ỗ', 'Ộ', 'Ơ', 'Ớ', 'Ờ', 'Ở', 'Ỡ', 'Ợ'];
      // case 'U': return ['Ú', 'Ù', 'Ủ', 'Ũ', 'Ụ', 'Ư', 'Ứ', 'Ừ', 'Ử', 'Ữ', 'Ự'];
      // case 'Y': return ['Ý', 'Ỳ', 'Ỷ', 'Ỹ', 'Ỵ'];
      // case 'D': return ['Đ'];
      case 'c': return ['ç'];
      case 'n': return ['ñ'];
      case 's': return ['ş', 'ß'];
      case 'z': return ['ž', 'ź', 'ż'];

      // Dấu câu
      case '.': return ['…', '·', '•'];
      case ',': return ['،', '、'];
      case '?': return ['¿', '‽'];
      case '!': return ['¡'];
      case "'": return ['\u2018', '\u2019', '\u201A', '`', '\u00B4'];
      case '"': return ['\u201C', '\u201D', '\u201E', '«', '»'];
      case '-': return ['–', '—', '·', '•'];
      case '/': return ['\\', '|'];
      case '@': return ['©', '®', '™'];
      case '&': return ['§', '¶', '†'];
      case '%': return ['‰', '°'];
      case '=': return ['≠', '≈', '≡', '±', '×', '÷'];
      case '<': return ['«', '≤', '‹'];
      case '>': return ['»', '≥', '›'];
      case '0': return ['°', 'Ø', 'ø'];
      case '1': return ['¹', '½', '¼'];
      case '2': return ['²', '½'];
      case '3': return ['³', '¾'];
      default: return [];
    }
  }

  private matchKeyCase(ch: string): string {
    return this.isShifted ? ch.toUpperCase() : ch;
  }

  private clearAccentHold(): void {
    if (this.accentHoldTimeoutId >= 0) {
      clearTimeout(this.accentHoldTimeoutId);
      this.accentHoldTimeoutId = -1;
    }
  }

  private closeAccentPopup(): void {
    this.clearAccentHold();
    this.accentPopupVisible = false;
    this.accentPopupKey = '';
    this.accentPopupChars = [];
    this.accentLongHandled = false;
  }

  private consumeAccentOutsideKeyDown(k: string): boolean {
    if (!this.accentPopupVisible) {
      return false;
    }

    this.closeAccentPopup();
    this.accentOutsideKeyPending = k;
    return true;
  }

  private consumeAccentOutsideActionDown(): boolean {
    if (!this.accentPopupVisible) {
      return false;
    }

    this.closeAccentPopup();
    this.accentOutsideActionPending = true;
    return true;
  }

  private consumeAccentOutsideAction(): boolean {
    if (this.accentPopupVisible) {
      this.closeAccentPopup();
      return true;
    }

    if (this.accentOutsideActionPending) {
      this.accentOutsideActionPending = false;
      return true;
    }

    return false;
  }

  private runKeyboardAction(action: () => void): void {
    if (this.consumeAccentOutsideAction()) {
      return;
    }
    action();
  }

  private startAccentHold(k: string): void {
    this.closeAccentPopup();

    const chars = this.getAccentChars(k);
    if (chars.length === 0) {
      return;
    }

    this.accentHoldTimeoutId = setTimeout(() => {
      this.accentLongHandled = true;
      this.accentPopupKey = k;
      this.accentPopupChars = chars.map((ch: string) => this.matchKeyCase(ch));
      this.accentPopupVisible = true;
    }, 350) as number;
  }

  private finishAccentTouch(k: string, canceled: boolean): void {
    this.clearAccentHold();
    if (canceled) {
      this.accentLongHandled = false;
      return;
    }
    if (this.accentLongHandled) {
      this.accentLongHandled = false;
      return;
    }
    this.tap(k);
  }

  private insertAccentChar(ch: string): void {
    this.closeAccentPopup();
    KeyboardBridge.sendPasteText(ch);
  }

  private getAccentPopupRows(chars: string[]): string[][] {
    const rows: string[][] = [];
    const rowCount = Math.min(4, Math.max(1, Math.ceil(chars.length / 5)));
    const itemsPerRow = Math.ceil(chars.length / rowCount);

    for (let i = 0; i < rowCount; i++) {
      const start = i * itemsPerRow;
      const row = chars.slice(start, start + itemsPerRow);
      if (row.length > 0) {
        rows.push(row);
      }
    }

    return rows;
  }

  onShiftTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.shiftTouchDownAt = Date.now();
      this.shiftLongHandled = false;
      return;
    }
    if (event.type === TouchType.Up) {
      const heldMs = Date.now() - this.shiftTouchDownAt;
      if (!this.shiftLongHandled && heldMs >= 450) {
        this.handleShiftLongPress();
      }
      return;
    }
  }

  clearBackspaceRepeat(): void {
    if (this.backspaceHoldTimeoutId >= 0) {
      clearTimeout(this.backspaceHoldTimeoutId);
      this.backspaceHoldTimeoutId = -1;
    }
    if (this.backspaceWordTimeoutId >= 0) {
      clearTimeout(this.backspaceWordTimeoutId);
      this.backspaceWordTimeoutId = -1;
    }
    if (this.backspaceRepeatIntervalId >= 0) {
      clearInterval(this.backspaceRepeatIntervalId);
      this.backspaceRepeatIntervalId = -1;
    }
    this.backspaceRepeating = false;
  }

  sendBackspace(): void {
    KeyboardBridge.sendKey('Delete');
  }

  sendBackspaceWord(): void {
    KeyboardBridge.sendKey('DeleteWord');
  }

  startBackspaceRepeat(): void {
    this.clearBackspaceRepeat();
    this.backspaceHoldTimeoutId = setTimeout(() => {
      this.backspaceRepeating = true;
      this.sendBackspace();
      this.backspaceRepeatIntervalId = setInterval(() => {
        this.sendBackspace();
      }, this.backspaceRepeatMs) as number;
    }, this.backspaceRepeatDelayMs) as number;
    this.backspaceWordTimeoutId = setTimeout(() => {
      this.backspaceRepeating = true;
      if (this.backspaceRepeatIntervalId >= 0) {
        clearInterval(this.backspaceRepeatIntervalId);
        this.backspaceRepeatIntervalId = -1;
      }
      this.sendBackspaceWord();
      this.backspaceRepeatIntervalId = setInterval(() => {
        this.sendBackspaceWord();
      }, this.backspaceWordRepeatMs) as number;
    }, this.backspaceWordDelayMs) as number;
  }

  onBackspaceTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.startBackspaceRepeat();
      return;
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.clearBackspaceRepeat();
      return;
    }
  }

  handleKey(k: string): void {
    switch (k) {
      case 'SHIFT':
        this.handleShiftTap();
        break;
      case 'BACKSPACE':
        KeyboardBridge.sendKey('Delete');
        break;
      case 'SPACE':
        KeyboardBridge.sendKey(' ');
        break;
      case 'ENTER':
        KeyboardBridge.sendEnter();
        break;
      case 'NUMBERS':
        this.layout = KeyLayout.NUMBERS;
        KeyboardBridge.sendClearShift();
        break;
      case '123':
        this.layout = KeyLayout.NUMBERS;
        KeyboardBridge.sendClearShift();
        break;
      case 'SYMBOLS':
      case '#+=':
        this.layout = KeyLayout.SYMBOLS;
        KeyboardBridge.sendClearShift();
        break;
      case 'LETTERS':
      case 'ABC':
        this.layout = KeyLayout.LETTERS;
        KeyboardBridge.sendClearShift();
        break;
      case 'EMOJI':
        this.showEmoji = !this.showEmoji;
        this.showClipboard = false;
        this.activePanel = TaskPanel.NONE;
        break;
      default:
        KeyboardBridge.sendKey(k.toLowerCase());
    }
  }

  // ═══════════════════════════════════════════
  //  BUILD CHÍNH
  // ═══════════════════════════════════════════
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        if (this.showEmoji) {
          this.buildEmojiPanel()
        } else if (this.activePanel === TaskPanel.MODE) {
          this.buildModePanel()
        } else if (this.activePanel === TaskPanel.LANGUAGE) {
          this.buildLanguagePanel()
        } else if (this.activePanel === TaskPanel.TRANSLATE) {
          this.buildTranslatePanel()
        } else if (this.activePanel === TaskPanel.CLIPBOARD || this.showClipboard) {
          this.buildClipboard()
        } else if (this.activePanel === TaskPanel.STICKER) {
          this.buildStickerPanel()
        } else if (this.activePanel === TaskPanel.SETTINGS) {
          this.buildSettingsPanel()
        } else if (this.activePanel === TaskPanel.THEME) {
          this.buildThemePanel()
        } else if (this.isLandscape) {
          this.buildKeyboard(true)
        } else {
          this.buildKeyboard(false)
        }
      }
      .width(this.keySizeLabel ? '100%' : '100%')
      .height(this.panelVp)
      .backgroundColor(this.bgBase)
      .opacity(normalizeKeyboardOpacity(this.bgOpacity))

      if (this.accentPopupVisible) {
        Column() {}
          .width('100%')
          .height(this.panelVp)
          .backgroundColor('#00000000')
          .onClick(() => {
            this.closeAccentPopup();
          })
      }

      if (this.showDevelopingPopup) {
        this.buildDevelopingPopup()
      }
    }
    .width('100%')
    .height(this.panelVp)
    .backgroundColor(this.bgBase)
  }

  // ═══════════════════════════════════════════
  //  BÀN PHÍM CHÍNH (dọc VÀ ngang dùng chung hàm, chỉ khác data rows)
  // ═══════════════════════════════════════════
  @Builder
  buildKeyboard(landscape: boolean) {
    Column() {
      // ── Thanh gợi ý ──
      this.buildBar(landscape)

      // ── Row 0 ──
      if (landscape ? this.getLR0().length > 0 : this.getPR0().length > 0) {
        Row() {
          ForEach(landscape ? this.getLR0() : this.getPR0(), (k: string) => {
            this.buildKey(k, landscape)
          })
        }
        .width('100%').layoutWeight(1)
        .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
        .padding({ top: this.getKeyMarginV(landscape), bottom: this.getKeyMarginV(landscape) })
      }

      // ── Row 1 ──
      Row() {
        ForEach(landscape ? this.getLR1() : this.getPR1(), (k: string) => {
          this.buildKey(k, landscape)
        })
      }
      .width('100%').layoutWeight(1)
      .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
      .padding({ top: this.getKeyMarginV(landscape), bottom: this.getKeyMarginV(landscape) })

      // ── Row 2 ──
      Row() {
        ForEach(landscape ? this.getLR2() : this.getPR2(), (k: string) => {
          this.buildKey(k, landscape)
        })
      }
      .width(this.getRow2Width()).layoutWeight(1)
      .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
      .padding({ top: this.getKeyMarginV(landscape), bottom: this.getKeyMarginV(landscape) })

      // ── Row 3: [LEFT_SPECIAL] ... inner ... [BACKSPACE] ──
      Row() {
        // Nút trái: SHIFT / #+= / 123
        this.buildRow3LeftKey(landscape)
        // Phím giữa
        ForEach(landscape ? this.getLR3Inner() : this.getPR3Inner(), (k: string) => {
          this.buildKey(k, landscape)
        })
        // BACKSPACE (luôn ở đây)
        this.buildWKey('BACKSPACE', landscape ? CFG_L.wBS : CFG_P.wBS, landscape)
      }
      .width('100%').layoutWeight(1)
      .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
      .padding({ top: this.getKeyMarginV(landscape), bottom: this.getKeyMarginV(landscape) })

      // ── Row 4: Hàng action (123/ABC, 😊, ,, SPACE, ., ENTER) ──
      this.buildActionRow(landscape)
    }
    .width('100%').layoutWeight(1)
    .padding({ left: this.getKeyMarginH(landscape),
               right: this.getKeyMarginH(landscape),
               top: 2, bottom: 2 })
  }

  // ── Dữ liệu hàng theo layout + hướng ──
  getCurrentLayoutSpec(landscape: boolean): LayoutSpec {
    const spec = (landscape ? L_LAYOUTS : P_LAYOUTS).get(this.layout);
    return spec ? spec : (landscape ? L_LAYOUTS.get(KeyLayout.LETTERS)! : P_LAYOUTS.get(KeyLayout.LETTERS)!);
  }

  getPR0(): string[] {
    if (this.layout === KeyLayout.LETTERS && !this.showNumberRow) return [];
    return this.getCurrentLayoutSpec(false).row0;
  }
  getPR1(): string[] { return this.getCurrentLayoutSpec(false).row1; }
  getPR2(): string[] { return this.getCurrentLayoutSpec(false).row2; }
  getPR3Inner(): string[] { return this.getCurrentLayoutSpec(false).row3Inner; }
  getLR0(): string[] {
    if (this.layout === KeyLayout.LETTERS && !this.showNumberRow) return [];
    return this.getCurrentLayoutSpec(true).row0;
  }
  getLR1(): string[] { return this.getCurrentLayoutSpec(true).row1; }
  getLR2(): string[] { return this.getCurrentLayoutSpec(true).row2; }
  getLR3Inner(): string[] { return this.getCurrentLayoutSpec(true).row3Inner; }

  getRow2Width(): string {
    return this.layout === KeyLayout.LETTERS ? '90%' : '100%';
  }

  getR3LeftKey(): string {
    switch (this.layout) {
      case KeyLayout.NUMBERS:
        return '#+=';
      case KeyLayout.SYMBOLS:
        return '123';
      case KeyLayout.LETTERS:
      default:
        return 'SHIFT';
    }
  }

  getR3LeftLabel(): string {
    switch (this.layout) {
      case KeyLayout.NUMBERS:
        return '#+=';
      case KeyLayout.SYMBOLS:
        return '123';
      case KeyLayout.LETTERS:
      default:
        return this.isShifted ? '⬆' : '⇧';
    }
  }

  getActionLeftLabel(): string {
    switch (this.layout) {
      case KeyLayout.LETTERS:
        return '123';
      case KeyLayout.NUMBERS:
      case KeyLayout.SYMBOLS:
      default:
        return 'ABC';
    }
  }

  switchActionLeft(): void {
    const spec = this.getCurrentLayoutSpec(this.isLandscape);
    if (spec.row5LeftTarget !== null) {
      this.layout = spec.row5LeftTarget;
    }
    KeyboardBridge.sendClearShift();
  }

  switchRow3Left(): void {
    const spec = this.getCurrentLayoutSpec(this.isLandscape);
    if (spec.row3Left === 'SHIFT') {
      this.handleShiftTap();
      return;
    }
    if (spec.row3LeftTarget !== null) {
      this.layout = spec.row3LeftTarget;
      KeyboardBridge.sendClearShift();
    }
  }

  getEmojiBackLabel(): string {
    switch (this.layoutBeforeEmoji) {
      case KeyLayout.LETTERS:
        return 'ABC';
      case KeyLayout.NUMBERS:
        return '123';
      case KeyLayout.SYMBOLS:
        return '#+=';
      default:
        return 'ABC';
    }
  }

  closeEmojiToPreviousLayout(): void {
    this.showEmoji = false;
    this.layout = this.layoutBeforeEmoji;
    KeyboardBridge.sendClearShift();
  }

  getEmojiRowIndexes(): number[] {
    const count = Math.ceil(EMOJI_CATS[this.emojiCat].items.length / 8);
    const indexes: number[] = [];
    for (let i = 0; i < count; i++) {
      indexes.push(i);
    }
    return indexes;
  }

  getInputModeLabel(): string {
    switch (this.inputMode) {
      case InputMode.TELEX:
        return 'TLX';
      case InputMode.TELEX_SIMPLE:
        return 'TLXs';
      case InputMode.VNI:
        return 'VNI';
      case InputMode.VNI_SIMPLE:
        return 'VNIs';
      case InputMode.ENGLISH:
        return 'EN';
      default:
        return 'TLX';
    }
  }

  getInputModeFullLabel(): string {
    switch (this.inputMode) {
      case InputMode.TELEX:
        return 'Telex';
      case InputMode.TELEX_SIMPLE:
        return 'Telex gọn';
      case InputMode.VNI:
        return 'VNI';
      case InputMode.VNI_SIMPLE:
        return 'VNI gọn';
      case InputMode.ENGLISH:
        return 'Tiếng Anh';
      default:
        return 'Telex';
    }
  }

  openPanel(panel: TaskPanel): void {
    if (panel === TaskPanel.STICKER ||
        panel === TaskPanel.TRANSLATE ||
        panel === TaskPanel.SETTINGS ||
        panel === TaskPanel.THEME ||
        panel === TaskPanel.LANGUAGE) {
      this.showDeveloping('Chức năng này');
      return;
    }

    if (this.activePanel === panel) {
      this.closePanel();
      return;
    }
    this.showEmoji = false;
    this.showClipboard = false;
    this.activePanel = this.activePanel === panel ? TaskPanel.NONE : panel;
  }

  openClipboardPanel(): void {
    this.openPanel(TaskPanel.CLIPBOARD);
    this.refreshClipboardPanel();
  }

  closePanel(): void {
    this.activePanel = TaskPanel.NONE;
    this.showClipboard = false;
    this.showEmoji = false;
  }

  showDeveloping(feature: string): void {
    this.devNotice = feature + ' đang phát triển.';
    this.developingFeature = feature;
    this.closePanel();
    this.showDevelopingPopup = true;
    console.info('[GoTiengViet] ' + this.devNotice);
  }

  closeDevelopingPopup(): void {
    this.showDevelopingPopup = false;
  }

  selectMode(mode: InputMode): void {
    KeyboardBridge.sendModeSelect(mode);
    this.closePanel();
  }

  getCurrentInputLanguage(): InputLanguageOption {
    const item = INSTALLED_INPUT_LANGUAGES[this.inputLanguageIndex];
    return item ? item : INSTALLED_INPUT_LANGUAGES[0];
  }

  selectInputLanguage(index: number): void {
    const item = INSTALLED_INPUT_LANGUAGES[index];
    if (!item || !item.installed) {
      this.showDeveloping('Tải ngôn ngữ');
      return;
    }

    this.inputLanguageIndex = index;
    if (item.defaultMode === InputMode.ENGLISH) {
      KeyboardBridge.sendModeSelect(InputMode.ENGLISH);
    } else if (this.inputMode === InputMode.ENGLISH) {
      KeyboardBridge.sendModeSelect(item.defaultMode);
    }
    this.closePanel();
  }

  cycleTranslateSourceLang(): void {
    this.translateSourceLangIndex = (this.translateSourceLangIndex + 1) % TRANSLATE_LANGS.length;
    this.updateTranslatePreview();
  }

  cycleTranslateTargetLang(): void {
    this.translateTargetLangIndex = (this.translateTargetLangIndex + 1) % TRANSLATE_LANGS.length;
    this.updateTranslatePreview();
  }

  updateTranslatePreview(): void {
    if (this.translateInput.length === 0) {
      this.translateOutput = 'Đang phát triển: dịch tự động sẽ hiển thị tại đây.';
      return;
    }
    this.translateOutput = 'Đang phát triển: ' + this.translateInput;
  }

  pasteClipboardText(text: string): void {
    KeyboardBridge.sendPasteText(text);
    this.closePanel();
  }

  pasteFromSystemClipboard(): void {
    KeyboardBridge.sendPasteSystemClipboard();
    this.closePanel();
  }

  readClipboardWithPasteButton(result: PasteButtonOnClickResult): void {
    if (result === PasteButtonOnClickResult.SUCCESS) {
      KeyboardBridge.sendClipboard();
      return;
    }
    this.clipboardItems = [];
    this.clipboardStatus = 'Hệ thống từ chối cấp quyền đọc clipboard tạm thời.';
  }

  clearClipboardHistory(): void {
    this.clipboardItems = [];
    KeyboardBridge.sendClearClipboardHistory();
  }

  refreshClipboardPanel(): void {
    KeyboardBridge.sendClipboard();
  }

  insertSticker(value: string): void {
    this.showDeveloping('Sticker');
    KeyboardBridge.sendPasteText(value);
    this.closePanel();
  }

  handleSetting(action: string): void {
    switch (action) {
      case 'size':
        this.keySizeLabel = this.keySizeLabel === 'Vừa' ? 'Lớn' : (this.keySizeLabel === 'Lớn' ? 'Nhỏ' : 'Vừa');
        this.closePanel();
        break;
      case 'theme':
        this.openPanel(TaskPanel.THEME);
        break;
      case 'number_row':
        this.showNumberRow = !this.showNumberRow;
        break;
      case 'language':
        this.openPanel(TaskPanel.LANGUAGE);
        break;
      case 'mode':
        this.openPanel(TaskPanel.MODE);
        break;
      case 'vibration':
        this.vibrationEnabled = !this.vibrationEnabled;
        break;
      case 'sound':
        this.keySoundEnabled = !this.keySoundEnabled;
        break;
      case 'app':
        KeyboardBridge.sendOpenApp();
        this.closePanel();
        break;
      default:
        this.showDeveloping('Chức năng');
    }
  }

  getSettingsItems(): SettingsItem[] {
    return [
      new SettingsItem('↕', 'Size phím', this.keySizeLabel, 'size'),
      new SettingsItem('🎨', 'Giao diện', this.darkMode ? 'Tối' : 'Sáng', 'theme'),
      new SettingsItem('🔢', 'Hàng số', this.showNumberRow ? 'Bật' : 'Tắt', 'number_row'),
      new SettingsItem('文', 'Ngôn ngữ', this.getCurrentInputLanguage().title, 'language'),
      new SettingsItem('⌨', 'Kiểu gõ', this.getInputModeFullLabel(), 'mode'),
      new SettingsItem('≋', 'Rung', this.vibrationEnabled ? 'Bật' : 'Tắt', 'vibration'),
      new SettingsItem('♪', 'Âm phím', this.keySoundEnabled ? 'Bật' : 'Tắt', 'sound'),
      new SettingsItem('↗', 'Vào app', 'Mở', 'app')
    ];
  }

  // ── Dữ liệu hàng theo layout + hướng ──
  // ── Thanh gợi ý ──
  @Builder
  buildBar(landscape: boolean) {
    Row() {
      if (this.composingText.length > 0) {
        Text(this.composingText)
          .fontSize(landscape ? 12 : 14).fontColor(this.kbTheme().accentColor)
          .padding({ left: 8, right: 6 }).maxLines(1)
        ForEach(this.candidates.slice(0, 5), (c: string) => {
          Text(c)
            .fontSize(landscape ? 12 : 14).fontColor(this.txt)
            .padding({ left: 10, right: 10 }).maxLines(1)
            .onClick(() => {
              this.runKeyboardAction(() => {
                KeyboardBridge.sendCandidate(c);
              });
            })
        })
      }
      Blank()
      this.buildTaskButton(this.getInputModeLabel() + '⌄', () => { this.openPanel(TaskPanel.MODE); }, landscape)
      this.buildTaskButton('Ẩn', () => { KeyboardBridge.sendHide(); }, landscape)
      this.buildTaskButton('📋', () => { this.openClipboardPanel(); }, landscape)
      this.buildTaskButton('☆', () => { this.openPanel(TaskPanel.STICKER); }, landscape)
      this.buildTaskButton('⇄', () => { this.openPanel(TaskPanel.TRANSLATE); }, landscape)
      this.buildTaskButton('⚙', () => { this.openPanel(TaskPanel.SETTINGS); }, landscape)
    }
    .width('100%')
    .height(landscape ? CFG_L.barH : CFG_P.barH)
    .backgroundColor(this.kbTheme().barBg)
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 2 })
  }

  @Builder
  buildTaskButton(label: string, action: () => void, landscape: boolean) {
    Button() {
      Text(label)
        .fontSize(landscape ? 10 : 11)
        .fontColor(this.txt)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .width(label.length > 3 ? (landscape ? 52 : 58) : (landscape ? 30 : 34))
    .height(landscape ? 20 : 22)
    .borderRadius(6)
    .backgroundColor(this.kbTheme().taskButtonBg)
    .margin({ right: 4 })
    .padding({ left: 2, right: 2 })
    .onClick(() => {
      this.runKeyboardAction(action);
    })
  }

  // ── Hàng Action (Row 4) ──
  @Builder
  buildActionRow(landscape: boolean) {
    Row() {
      // Nút chuyển layout (123 ↔ ABC)
      this.buildActKey(
        this.getActionLeftLabel(),
        () => { this.switchActionLeft(); },
        landscape ? CFG_L.wMode : CFG_P.wMode, landscape
      )
      // Emoji
      this.buildActKey('😊', () => {
        if (!this.showEmoji) {
          this.layoutBeforeEmoji = this.layout;
        }
        this.showEmoji = !this.showEmoji;
        this.showClipboard = false;
      }, landscape ? CFG_L.wEmoji : CFG_P.wEmoji, landscape)
      // Dấu phẩy
      this.buildActKey(',', () => { KeyboardBridge.sendKey(','); },
        landscape ? CFG_L.wComma : CFG_P.wComma, landscape)
      // Phím cách
      this.buildSpaceKey(landscape ? CFG_L.wSpace : CFG_P.wSpace, landscape)
      // Dấu chấm
      this.buildActKey('.', () => { KeyboardBridge.sendKey('.'); },
        landscape ? CFG_L.wDot : CFG_P.wDot, landscape)
      // Enter (luôn ở đây)
      this.buildActKey('↵', () => { KeyboardBridge.sendEnter(); },
        landscape ? CFG_L.wEnter : CFG_P.wEnter, landscape)
    }
    .width('100%').layoutWeight(1)
    .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
    .padding({ top: this.getKeyMarginV(landscape), bottom: this.getKeyMarginV(landscape) })
  }

  // ──────────────────────────────────────────
  //  BUILDERS PHÍM
  // ──────────────────────────────────────────

  @Builder
  buildAccentPopup(chars: string[]) {
    Column() {
      ForEach(this.getAccentPopupRows(chars), (row: string[]) => {
        Row() {
          ForEach(row, (ch: string) => {
            Text(ch)
              .fontSize(this.isLandscape ? 18 : 21)
              .fontColor(this.txt)
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Center)
              .width(this.isLandscape ? 32 : 38)
              .height(this.isLandscape ? 32 : 38)
              .borderRadius(7)
              .backgroundColor(this.keyBase)
              .margin({ left: 2, right: 2, top: 2, bottom: 2 })
              .onClick(() => {
                this.insertAccentChar(ch);
              })
          })
        }
        .justifyContent(FlexAlign.Center)
      })
    }
    .padding({ left: 6, right: 6, top: 5, bottom: 5 })
    .backgroundColor(this.kbTheme().barBg)
    .borderRadius(10)
  }

  /** Phím thường – layoutWeight(1) */
  @Builder
  buildKey(k: string, landscape: boolean) {
    Button({ type: ButtonType.Normal }) {
      Text(this.lbl(k))
        .fontSize(this.isSpecial(k) ? this.getSpecialKeyFontSize(landscape) : this.getNormalKeyFontSize(landscape))
        .fontColor(this.txt)
        .fontWeight(this.isSpecial(k) ? FontWeight.Medium : FontWeight.Regular)
        .textAlign(TextAlign.Center).maxLines(1)
    }
    .layoutWeight(1)
    .height(this.getKeyHeight(landscape))
    .margin({ left: this.getKeyMarginH(landscape), right: this.getKeyMarginH(landscape) })
    .backgroundColor(this.bgK(k, this.keyBase))
    .borderRadius(this.getKeyRadius(landscape))
    .opacity(normalizeKeyboardOpacity(this.keyOpacity))
    .onTouch((event: TouchEvent) => {
      this.onKeyTouch(k, event);
    })
    .bindPopup(this.accentPopupVisible && this.accentPopupKey === k, {
      builder: this.buildAccentPopup(this.accentPopupChars),
      placement: Placement.Top,
      mask: false
    })
  }

  /** Nút trái hàng 4: SHIFT / #+= / 123 */
  @Builder
  buildRow3LeftKey(landscape: boolean) {
    Button({ type: ButtonType.Normal }) {
      Text(this.getR3LeftLabel())
        .fontSize(this.getSpecialKeyFontSize(landscape))
        .fontColor(this.txt).fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center).maxLines(1)
    }
    .layoutWeight(landscape ? CFG_L.wShift : CFG_P.wShift)
    .height(this.getKeyHeight(landscape))
    .margin({ left: this.getKeyMarginH(landscape), right: this.getKeyMarginH(landscape) })
    .backgroundColor(this.bgK(this.getR3LeftKey(), this.keyBase))
    .borderRadius(this.getKeyRadius(landscape))
    .opacity(normalizeKeyboardOpacity(this.keyOpacity))
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        if (this.consumeAccentOutsideActionDown()) {
          return;
        }
      }
      if (this.accentOutsideActionPending) {
        return;
      }
      if (this.getR3LeftKey() === 'SHIFT') {
        this.onShiftTouch(event);
      }
    })
    .onClick(() => {
      if (this.consumeAccentOutsideAction()) {
        return;
      }
      if (this.getR3LeftKey() === 'SHIFT' && this.shiftLongHandled) {
        this.shiftLongHandled = false;
        return;
      }
      this.switchRow3Left();
    })
  }

  /** Phím có trọng số riêng (SHIFT, BACKSPACE) */
  @Builder
  buildWKey(k: string, w: number, landscape: boolean) {
    Button({ type: ButtonType.Normal }) {
      Text(k === this.getR3LeftKey() ? this.getR3LeftLabel() : this.lbl(k))
        .fontSize(this.getSpecialKeyFontSize(landscape))
        .fontColor(this.txt).fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center).maxLines(1)
    }
    .layoutWeight(w)
    .height(this.getKeyHeight(landscape))
    .margin({ left: this.getKeyMarginH(landscape), right: this.getKeyMarginH(landscape) })
    .backgroundColor(this.bgK(k, this.keyBase))
    .borderRadius(this.getKeyRadius(landscape))
    .opacity(normalizeKeyboardOpacity(this.keyOpacity))
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        if (this.consumeAccentOutsideActionDown()) {
          return;
        }
      }
      if (this.accentOutsideActionPending) {
        return;
      }
      if (k === 'SHIFT') {
        this.onShiftTouch(event);
      }
      if (k === 'BACKSPACE') {
        this.onBackspaceTouch(event);
      }
    })
    .onClick(() => {
      if (this.consumeAccentOutsideAction()) {
        return;
      }
      if (k === 'SHIFT' && this.shiftLongHandled) {
        this.shiftLongHandled = false;
        return;
      }
      if (k === 'BACKSPACE' && this.backspaceRepeating) {
        this.clearBackspaceRepeat();
        return;
      }
      if (k === this.getR3LeftKey()) {
        this.switchRow3Left();
        return;
      }
      this.tap(k);
    })
  }

  /** Phím action hàng cuối */
  @Builder
  buildActKey(lbl: string, action: () => void, w: number, landscape: boolean) {
    Button({ type: ButtonType.Normal }) {
      Text(lbl)
        .fontSize(lbl === '↵' ? this.getEnterKeyFontSize(landscape) : this.getSpecialKeyFontSize(landscape))
        .fontColor(this.txt).fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center).maxLines(1)
    }
    .layoutWeight(w)
    .height(this.getKeyHeight(landscape))
    .margin({ left: this.getKeyMarginH(landscape), right: this.getKeyMarginH(landscape) })
    .backgroundColor(this.keyS)
    .borderRadius(this.getKeyRadius(landscape))
    .opacity(normalizeKeyboardOpacity(this.keyOpacity))
    .onClick(() => {
      this.runKeyboardAction(action);
    })
  }

  /** Phím cách */
  @Builder
  buildSpaceKey(w: number, landscape: boolean) {
    Button({ type: ButtonType.Normal }) {
      Text('Hoàng Sa - Trường Sa\nlà của Việt Nam')
        .fontSize(landscape ? 9 : 9)
        .fontColor(this.txt)
        .opacity(0.3)
        .fontWeight(FontWeight.Regular)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .lineHeight(landscape ? 11 : 14)
    }
    .layoutWeight(w)
    .height(this.getKeyHeight(landscape))
    .margin({ left: this.getKeyMarginH(landscape), right: this.getKeyMarginH(landscape) })
    .backgroundColor(this.keyBase)
    .borderRadius(this.getSpaceRadius(landscape))
    .opacity(normalizeKeyboardOpacity(this.keyOpacity))
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        if (this.accentPopupVisible) {
          this.closeAccentPopup();
          return;
        }
        KeyboardBridge.sendKey(' ');
      }
    })
  }

  // ═══════════════════════════════════════════
  //  EMOJI PANEL
  //  Có: ABC (trái hàng cuối), [category tabs] (giữa),
  //      ⌫ (phải cùng hàng BS), ↵ (phải hàng action)
  // ═══════════════════════════════════════════
  @Builder
  buildEmojiPanel() {
    Column() {
      // ── Tabs category ──
      Row() {
        ForEach(EMOJI_CATS, (cat: EmojiCategory, idx: number) => {
          Text(cat.icon).fontSize(20)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor(this.emojiCat === idx ? this.keyAcc : 'transparent')
            .borderRadius(8)
            .onClick(() => { this.emojiCat = idx; })
        })
        Blank()
      }
      .width('100%').height(this.isLandscape ? 36 : 42)
      .backgroundColor('#181818').alignItems(VerticalAlign.Center)
      .padding({ left: 4 })

      // ── Grid emoji ──
      Scroll() {
        Column() {
          ForEach(this.getEmojiRowIndexes(), (rowIdx: number) => {
            Row() {
              ForEach(
                EMOJI_CATS[this.emojiCat].items.slice(rowIdx*8, rowIdx*8+8),
                (emoji: string) => {
                  Text(emoji)
                    .fontSize(this.isLandscape ? 20 : 24)
                    .width('11%').textAlign(TextAlign.Center)
                    .padding({ top: 4, bottom: 4 })
                    .onClick(() => KeyboardBridge.sendPasteText(emoji))
                }
              )
            }
            .width('100%').justifyContent(FlexAlign.SpaceAround)
            .padding({ top: 2, bottom: 2 })
          })
        }
        .width('100%').padding({ left: 4, right: 4 })
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)


      // ── Hàng action Emoji: [ABC/123/#+=, trống, trống] SPACE . ↵ ── (vị trí Row4)
      Row() {
        this.buildActKey(
          this.getEmojiBackLabel(),
          () => { this.closeEmojiToPreviousLayout(); },
          this.isLandscape ? CFG_L.wMode : CFG_P.wMode,
          this.isLandscape
        )

        Blank().layoutWeight(this.isLandscape ? CFG_L.wEmoji : CFG_P.wEmoji)
        Blank().layoutWeight(this.isLandscape ? CFG_L.wComma : CFG_P.wComma)

        // Phím cách
        this.buildSpaceKey(this.isLandscape ? CFG_L.wSpace : CFG_P.wSpace, this.isLandscape)

        // Dấu chấm
        this.buildActKey('.', () => { KeyboardBridge.sendKey('.'); },
          this.isLandscape ? CFG_L.wDot : CFG_P.wDot, this.isLandscape)

        // Enter – đúng vị trí
        this.buildActKey('↵', () => { KeyboardBridge.sendEnter(); },
          this.isLandscape ? CFG_L.wEnter : CFG_P.wEnter, this.isLandscape)
      }
      .width('100%').height(this.isLandscape ? 44 : 50)
      .alignItems(VerticalAlign.Center)
      .padding({ left: this.getKeyMarginH(this.isLandscape),
                 right: this.getKeyMarginH(this.isLandscape),
                 top: this.getKeyMarginV(this.isLandscape),
                 bottom: this.getKeyMarginV(this.isLandscape) })
    }
    .width('100%').height(this.panelVp).backgroundColor(this.bgBase)
  }

  @Builder
  buildPanelHeader(title: string, rightLabel: string, rightAction: () => void) {
    Row() {
      Text(title)
        .fontSize(13)
        .fontColor('#E5E7EB')
        .fontWeight(FontWeight.Bold)
        .padding({ left: 12 })
      Blank()
      if (rightLabel.length > 0) {
        Button() {
          Text(rightLabel).fontSize(12).fontColor('#9CA3AF').maxLines(1)
        }
        .height(28)
        .padding({ left: 10, right: 10 })
        .backgroundColor('#1F2937')
        .borderRadius(8)
        .margin({ right: 8 })
        .onClick(rightAction)
      }
      Button() {
        Text('✕').fontSize(13).fontColor('#9CA3AF')
      }
      .width(28).height(28)
      .backgroundColor('transparent')
      .onClick(() => { this.closePanel(); })
      .margin({ right: 8 })
    }
    .width('100%')
    .height(36)
    .backgroundColor('#0F172A')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildDevNotice() {
    if (this.devNotice.length > 0) {
      Text(this.devNotice)
        .fontSize(12)
        .fontColor('#FBBF24')
        .width('100%')
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('#1F1A08')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
  }

  @Builder
  buildDevelopingPopup() {
    Column() {
      Column() {
        Text('Đang phát triển')
          .fontSize(16)
          .fontColor('#F9FAFB')
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .margin({ bottom: 8 })
        Text(this.developingFeature.length > 0 ? this.developingFeature : 'Chức năng')
          .fontSize(12)
          .fontColor('#D1D5DB')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 14 })
        Button('Đóng')
          .height(32)
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('#2563EB')
          .borderRadius(16)
          .padding({ left: 18, right: 18 })
          .onClick(() => { this.closeDevelopingPopup(); })
      }
      .width(this.isLandscape ? '42%' : '72%')
      .backgroundColor('#111827')
      .borderRadius(12)
      .padding({ left: 16, right: 16, top: 16, bottom: 14 })
    }
    .width('100%')
    .height(this.panelVp)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#00000088')
    .onClick(() => { this.closeDevelopingPopup(); })
  }

  @Builder
  buildModePanel() {
    Column() {
      this.buildPanelHeader('Chọn kiểu gõ', '', () => {})
      this.buildDevNotice()
      Column() {
        ForEach(MODE_OPTIONS, (item: ModeOption) => {
          Row() {
            Text(item.label)
              .fontSize(15)
              .fontColor(this.inputMode === item.value ? '#60A5FA' : '#E5E7EB')
              .fontWeight(this.inputMode === item.value ? FontWeight.Bold : FontWeight.Regular)
              .layoutWeight(1)
            Text(this.inputMode === item.value ? '✓' : '')
              .fontSize(15)
              .fontColor('#60A5FA')
              .width(24)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .height(38)
          .padding({ left: 14, right: 14 })
          .backgroundColor(this.inputMode === item.value ? '#10243D' : '#111827')
          .borderRadius(8)
          .margin({ top: 4, bottom: 4 })
          .onClick(() => { this.selectMode(item.value); })
        })
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 6 })
    }
    .width('100%')
    .height(this.panelVp)
    .backgroundColor(this.bgBase)
  }

  @Builder
  buildLanguagePanel() {
    Column() {
      this.buildPanelHeader('Ngôn ngữ nhập', '', () => {})
      Column() {
        ForEach(INSTALLED_INPUT_LANGUAGES, (item: InputLanguageOption, index: number) => {
          Row() {
            Column() {
              Text(item.title)
                .fontSize(15)
                .fontColor(this.inputLanguageIndex === index ? '#60A5FA' : '#E5E7EB')
                .fontWeight(this.inputLanguageIndex === index ? FontWeight.Bold : FontWeight.Regular)
              Text(item.subtitle)
                .fontSize(11)
                .fontColor('#9CA3AF')
                .margin({ top: 3 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Text(this.inputLanguageIndex === index ? '✓' : '')
              .fontSize(15)
              .fontColor('#60A5FA')
              .width(24)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .height(48)
          .padding({ left: 14, right: 14 })
          .backgroundColor(this.inputLanguageIndex === index ? '#10243D' : '#111827')
          .borderRadius(8)
          .margin({ top: 4, bottom: 4 })
          .onClick(() => { this.selectInputLanguage(index); })
        })
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 6 })
    }
    .width('100%')
    .height(this.panelVp)
    .backgroundColor(this.bgBase)
  }

  @Builder
  buildTranslatePanel() {
    Column() {
      this.buildPanelHeader('Dịch chữ', 'Đảo chiều', () => {
        const oldSource = this.translateSourceLangIndex;
        this.translateSourceLangIndex = this.translateTargetLangIndex;
        this.translateTargetLangIndex = oldSource;
        this.updateTranslatePreview();
      })
      this.buildDevNotice()
      Row() {
        Column() {
          Row() {
            Text('Nhập').fontSize(12).fontColor('#9CA3AF').layoutWeight(1)
            Button() {
              Text(TRANSLATE_LANGS[this.translateSourceLangIndex] + ' ▾').fontSize(11).fontColor('#D1D5DB')
            }
            .height(26).backgroundColor('#1F2937').borderRadius(7)
            .padding({ left: 8, right: 8 })
            .onClick(() => { this.cycleTranslateSourceLang(); })
          }
          .width('100%').alignItems(VerticalAlign.Center)
          TextArea({ placeholder: 'Nhập nội dung cần dịch', text: this.translateInput })
            .width('100%')
            .height(this.isLandscape ? 74 : 96)
            .fontSize(13)
            .fontColor('#E5E7EB')
            .backgroundColor('#111827')
            .borderRadius(8)
            .padding(8)
            .onChange((value: string) => {
              this.translateInput = value;
              this.updateTranslatePreview();
            })
        }
        .layoutWeight(1)
        .margin({ right: 5 })

        Column() {
          Row() {
            Text('Kết quả').fontSize(12).fontColor('#9CA3AF').layoutWeight(1)
            Button() {
              Text(TRANSLATE_LANGS[this.translateTargetLangIndex] + ' ▾').fontSize(11).fontColor('#D1D5DB')
            }
            .height(26).backgroundColor('#1F2937').borderRadius(7)
            .padding({ left: 8, right: 8 })
            .onClick(() => { this.cycleTranslateTargetLang(); })
          }
          .width('100%').alignItems(VerticalAlign.Center)
          Text(this.translateOutput)
            .width('100%')
            .height(this.isLandscape ? 74 : 96)
            .fontSize(13)
            .fontColor('#E5E7EB')
            .backgroundColor('#111827')
            .borderRadius(8)
            .padding(8)
            .maxLines(5)
            .onClick(() => {
              this.showDeveloping('Dịch');
              if (this.translateInput.length > 0) {
                KeyboardBridge.sendPasteText(this.translateOutput);
              }
            })
        }
        .layoutWeight(1)
        .margin({ left: 5 })
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 8 })
    }
    .width('100%')
    .height(this.panelVp)
    .backgroundColor(this.bgBase)
  }

  @Builder
  buildStickerPanel() {
    Column() {
      this.buildPanelHeader('Sticker', this.stickerGrid ? 'Danh sách' : 'Lưới', () => {
        this.stickerGrid = !this.stickerGrid;
      })
      this.buildDevNotice()
      if (this.stickerGrid) {
        Grid() {
          ForEach(STICKER_ITEMS, (item: StickerItem) => {
            GridItem() {
              Column() {
                Text(item.value).fontSize(28).height(36).textAlign(TextAlign.Center)
                Text(item.title).fontSize(11).fontColor('#D1D5DB').maxLines(1)
              }
              .width('100%')
              .height(64)
              .justifyContent(FlexAlign.Center)
              .backgroundColor('#111827')
              .borderRadius(8)
              .onClick(() => { this.insertSticker(item.value); })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
        .padding(10)
        .layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            ForEach(STICKER_ITEMS, (item: StickerItem) => {
              Row() {
                Text(item.value).fontSize(24).width(42).textAlign(TextAlign.Center)
                Text(item.title).fontSize(14).fontColor('#E5E7EB').layoutWeight(1)
                Text('Chèn').fontSize(12).fontColor('#60A5FA')
              }
              .height(42)
              .padding({ left: 10, right: 12 })
              .backgroundColor('#111827')
              .borderRadius(8)
              .margin({ left: 10, right: 10, top: 4, bottom: 4 })
              .onClick(() => { this.insertSticker(item.value); })
            })
          }
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height(this.panelVp)
    .backgroundColor(this.bgBase)
  }

  @Builder
  buildSettingsPanel() {
    Column() {
      this.buildPanelHeader('Cài đặt nhanh', '', () => {})
      this.buildDevNotice()
      Grid() {
        ForEach(this.getSettingsItems(), (item: SettingsItem) => {
          GridItem() {
            Column() {
              Text(item.icon)
                .fontSize(18)
                .fontColor('#E5E7EB')
                .height(24)
                .textAlign(TextAlign.Center)
              Text(item.title)
                .fontSize(11)
                .fontColor('#D1D5DB')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(item.value)
                .fontSize(10)
                .fontColor('#9CA3AF')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .height(66)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#111827')
            .borderRadius(8)
            .padding({ left: 4, right: 4 })
            .onClick(() => { this.handleSetting(item.action); })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .padding(10)
      .layoutWeight(1)
    }
    .width('100%')
    .height(this.panelVp)
    .backgroundColor(this.bgBase)
  }

  @Builder
  buildThemePanel() {
    Column() {
      this.buildPanelHeader('Giao diện', '', () => {})
      Scroll() {
        Column() {
          Row() {
            Text('Chế độ Tối / Sáng').fontSize(16).fontColor(this.txt).layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.darkMode })
              .onChange((isOn: boolean) => {
                this.darkMode = isOn;
                this.saveThemeSetting(GTV_DARK_MODE_KEY, isOn);
              })
          }.width('100%').padding(16).alignItems(VerticalAlign.Center)

          Text('Màu nền').fontSize(14).fontColor(this.mutedTxt).width('100%').padding({ left: 16, bottom: 8 })
          Scroll() {
            Row() {
              ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
                Circle({ width: 36, height: 36 })
                  .fill(color)
                  .margin(6)
                  .border({ width: this.bgBase === color ? 3 : 0, color: this.kbTheme().selectedBorder })
                  .onClick(() => {
                    this.bgBase = color;
                    this.saveThemeSetting(GTV_BG_COLOR_KEY, color);
                  })
              })
            }.width('100%').padding({ left: 10, right: 10 })
          }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)

          Text('Màu phím').fontSize(14).fontColor(this.mutedTxt).width('100%').padding({ left: 16, top: 8, bottom: 8 })
          Scroll() {
            Row() {
              ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
                Circle({ width: 36, height: 36 })
                  .fill(color)
                  .margin(6)
                  .border({ width: this.keyBase === color ? 3 : 0, color: this.kbTheme().selectedBorder })
                  .onClick(() => {
                    this.keyBase = color;
                    this.saveThemeSetting(GTV_KEY_COLOR_KEY, color);
                  })
              })
            }.width('100%').padding({ left: 10, right: 10 })
          }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)

          Text('Độ trong suốt nền').fontSize(14).fontColor(this.mutedTxt).width('100%').padding({ left: 16, top: 16, bottom: 8 })
          Row() {
            ForEach(KEYBOARD_OPACITY_OPTIONS, (op: number) => {
              Text(op === 100 ? 'Đậm' : (op === 75 ? 'Vừa' : 'Trong'))
                .fontSize(14)
                .fontColor(this.bgOpacity === op ? '#FFFFFF' : this.txt)
                .backgroundColor(this.bgOpacity === op ? this.kbTheme().selectedFill : this.keyS)
                .borderRadius(8)
                .padding({ top: 8, bottom: 8, left: 16, right: 16 })
                .margin(6)
                .onClick(() => {
                  this.bgOpacity = op;
                  this.saveThemeSetting(GTV_BG_OPACITY_KEY, op);
                })
            })
          }.width('100%').padding({ left: 10, right: 10 }).justifyContent(FlexAlign.SpaceEvenly)

          Text('Độ trong suốt phím').fontSize(14).fontColor(this.mutedTxt).width('100%').padding({ left: 16, top: 16, bottom: 8 })
          Row() {
            ForEach(KEYBOARD_OPACITY_OPTIONS, (op: number) => {
              Text(op === 100 ? 'Đậm' : (op === 75 ? 'Vừa' : 'Trong'))
                .fontSize(14)
                .fontColor(this.keyOpacity === op ? '#FFFFFF' : this.txt)
                .backgroundColor(this.keyOpacity === op ? this.kbTheme().selectedFill : this.keyS)
                .borderRadius(8)
                .padding({ top: 8, bottom: 8, left: 16, right: 16 })
                .margin(6)
                .onClick(() => {
                  this.keyOpacity = op;
                  this.saveThemeSetting(GTV_KEY_OPACITY_KEY, op);
                })
            })
          }.width('100%').padding({ left: 10, right: 10 }).justifyContent(FlexAlign.SpaceEvenly)
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height(this.panelVp)
    .backgroundColor(this.bgBase)
  }

  // ═══════════════════════════════════════════
  //  CLIPBOARD
  // ═══════════════════════════════════════════
  @Builder
  buildClipboard() {
    Column() {
      this.buildPanelHeader('Clipboard', '', () => {})
      this.buildDevNotice()
      Row() {
        Button() {
          Text('Xóa danh sách').fontSize(12).fontColor('#FCA5A5').maxLines(1)
        }
        .height(30)
        .layoutWeight(1)
        .backgroundColor('#2A1518')
        .borderRadius(8)
        .onClick(() => {
          this.clearClipboardHistory();
        })
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 8, bottom: 6 })

      if (this.clipboardStatus.length > 0) {
        Text(this.clipboardStatus)
          .fontSize(12)
          .fontColor('#FBBF24')
          .width('100%')
          .padding({ left: 12, right: 12, top: 4, bottom: 8 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      if (this.clipboardItems.length === 0) {
        Text('Chưa có nội dung clipboard')
          .fontSize(13)
          .fontColor(this.mutedTxt)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 16, bottom: 16 })
      } else {
        Grid() {
          ForEach(this.clipboardItems, (item: ClipboardItem) => {
            GridItem() {
              Row() {
                Text(item.text)
                  .fontSize(13)
                  .fontColor('#CCCCEE')
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
                  .margin({ right: 8 })
                Text('Dán').fontSize(12).fontColor('#4FC3F7')
              }
              .onClick(() => { this.pasteClipboardTextItem(item); })
            }
          })
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
        .padding({ left: 10, right: 10, top: 4, bottom: 10 })
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height(this.panelVp)
    .backgroundColor(this.bgBase)
  }

  pasteClipboardTextItem(item: ClipboardItem): void {
    this.pasteClipboardText(item.text);
  }
}
