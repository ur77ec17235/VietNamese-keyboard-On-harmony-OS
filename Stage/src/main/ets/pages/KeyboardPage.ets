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
import { KeyboardBridge } from '../telex/service/KeyboardBridge';
import { KEY_INPUT_MODE, KEY_COMPOSING, KEY_CANDIDATES,
  KEY_IS_SHIFTED, KEY_SHOW_CLIPBOARD, KEY_CLIPBOARD_ITEMS } from '../telex/service/GoTiengVietService';
import { ClipboardItem } from '../telex/service/ClipboardManager';
import display from '@ohos.display';

// ─────────────────────────────────────────────────────────
//  TRUNG TÂM CẤU HÌNH  ← SỬA ĐÂY ĐỂ THAY ĐỔI KÍCH THƯỚC
// ─────────────────────────────────────────────────────────
class KBCfg {
  // --- Chiều cao thanh gợi ý (vp) ---
  barH: number = 32;
  // --- Khoảng cách ngang giữa các phím (vp, mỗi bên) ---
  mH: number = 2;
  // --- Khoảng cách dọc trên/dưới mỗi hàng (vp) ---
  mV: number = 2;
  // --- Bo góc phím thường ---
  rKey: number = 9;
  // --- Bo góc nút cách ---
  rSpace: number = 10;
  // --- Chiều cao phím = x% chiều cao hàng (layoutWeight) ---
  kH: string = '85%';
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
  mV: number = 1;
  rKey: number = 7;
  rSpace: number = 8;
  kH: string = '84%';
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
@Entry
@Component
struct KeyboardPage {
  @StorageLink(KEY_INPUT_MODE)      inputMode: InputMode       = InputMode.TELEX;
  @StorageLink(KEY_COMPOSING)       composingText: string      = '';
  @StorageLink(KEY_CANDIDATES)      candidates: string[]       = [];
  @StorageLink(KEY_IS_SHIFTED)      isShifted: boolean         = false;
  @StorageLink(KEY_SHOW_CLIPBOARD)  showClipboard: boolean     = false;
  @StorageLink(KEY_CLIPBOARD_ITEMS) clipboardItems: ClipboardItem[] = [];
  @StorageLink(KEY_IS_LANDSCAPE)    isLandscape: boolean       = false;
  @StorageLink(KEY_PANEL_HEIGHT_VP) panelVp: number            = 280;

  @State layout: KeyLayout = KeyLayout.LETTERS;
  @State pressedKey: string = '';
  @State showEmoji: boolean = false;
  @State emojiCat: number = 0;
  @State layoutBeforeEmoji: KeyLayout = KeyLayout.LETTERS;

  private lastShiftTapAt: number = 0;
  private shiftTouchDownAt: number = 0;
  private shiftLongHandled: boolean = false;
  private backspaceHoldTimeoutId: number = -1;
  private backspaceRepeatIntervalId: number = -1;
  private backspaceRepeating: boolean = false;

  // ── Theme ──
  private readonly bg      = '#111111';
  private readonly keyN    = '#1E1E1E';
  private readonly keyS    = '#2D2D2D';
  private readonly keyAcc  = '#3D3D3D';
  private readonly txt     = '#F3F4F6';

  // Cấu hình hiện tại (thay đổi theo hướng)
  private get c(): KBCfg | KBCfgLandscape {
    return this.isLandscape ? CFG_L : CFG_P;
  }

  aboutToAppear(): void {
    try {
      const d = display.getDefaultDisplaySync();
      this.isLandscape = d.width > d.height;
      if (this.panelVp < 50) {
        const dens = d.densityPixels > 0 ? d.densityPixels : 3.0;
        const px = this.isLandscape
          ? Math.round(d.height * 5 / 7)
          : Math.round(d.height * 2 / 5);
        this.panelVp = Math.round(px / dens);
      }
    } catch (_) { this.isLandscape = false; }
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

  bgK(k: string): string {
    if (k === this.pressedKey) return this.keyAcc;
    if (k === 'SHIFT' && this.isShifted) return '#4A90D9';
    if (this.isSpecial(k)) return this.keyS;
    return this.keyN;
  }

  tap(k: string): void {
    this.pressedKey = k;
    this.handleKey(k);
    setTimeout(() => { this.pressedKey = ''; }, 100);
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
    if (this.backspaceRepeatIntervalId >= 0) {
      clearInterval(this.backspaceRepeatIntervalId);
      this.backspaceRepeatIntervalId = -1;
    }
    this.backspaceRepeating = false;
  }

  sendBackspace(): void {
    KeyboardBridge.sendKey('Delete');
  }

  startBackspaceRepeat(): void {
    this.clearBackspaceRepeat();
    this.backspaceHoldTimeoutId = setTimeout(() => {
      this.backspaceRepeating = true;
      this.sendBackspace();
      this.backspaceRepeatIntervalId = setInterval(() => {
        this.sendBackspace();
      }, 65) as number;
    }, 350) as number;
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
        this.isShifted = false;
        break;
      case '123':
        this.layout = KeyLayout.NUMBERS;
        this.isShifted = false;
        break;
      case 'SYMBOLS':
      case '#+=':
        this.layout = KeyLayout.SYMBOLS;
        this.isShifted = false;
        break;
      case 'LETTERS':
      case 'ABC':
        this.layout = KeyLayout.LETTERS;
        this.isShifted = false;
        break;
      case 'EMOJI':
        this.showEmoji = !this.showEmoji;
        this.showClipboard = false;
        break;
      default:
        const ch = (this.layout === KeyLayout.LETTERS && this.isShifted) ? k.toUpperCase() : k;
        KeyboardBridge.sendKey(ch);
    }
  }

  // ═══════════════════════════════════════════
  //  BUILD CHÍNH
  // ═══════════════════════════════════════════
  build() {
    Column() {
      if (this.isLandscape) {
        this.buildKeyboard(true)
      } else {
        this.buildKeyboard(false)
      }
    }
    .width('100%')
    .height(this.panelVp)
    .backgroundColor(this.bg)
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
      Row() {
        ForEach(landscape ? this.getLR0() : this.getPR0(), (k: string) => {
          this.buildKey(k, landscape)
        })
      }
      .width('100%').layoutWeight(1)
      .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
      .padding({ top: landscape ? CFG_L.mV : CFG_P.mV, bottom: landscape ? CFG_L.mV : CFG_P.mV })

      // ── Row 1 ──
      Row() {
        ForEach(landscape ? this.getLR1() : this.getPR1(), (k: string) => {
          this.buildKey(k, landscape)
        })
      }
      .width('100%').layoutWeight(1)
      .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
      .padding({ top: landscape ? CFG_L.mV : CFG_P.mV, bottom: landscape ? CFG_L.mV : CFG_P.mV })

      // ── Row 2 ──
      Row() {
        ForEach(landscape ? this.getLR2() : this.getPR2(), (k: string) => {
          this.buildKey(k, landscape)
        })
      }
      .width('100%').layoutWeight(1)
      .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
      .padding({ top: landscape ? CFG_L.mV : CFG_P.mV, bottom: landscape ? CFG_L.mV : CFG_P.mV })

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
      .padding({ top: landscape ? CFG_L.mV : CFG_P.mV, bottom: landscape ? CFG_L.mV : CFG_P.mV })

      // ── Row 4: Hàng action (123/ABC, 😊, ,, SPACE, ., ENTER) ──
      this.buildActionRow(landscape)
    }
    .width('100%').layoutWeight(1)
    .padding({ left: landscape ? CFG_L.mH : CFG_P.mH,
               right: landscape ? CFG_L.mH : CFG_P.mH,
               top: 2, bottom: 2 })
  }

  // ── Dữ liệu hàng theo layout + hướng ──
  getCurrentLayoutSpec(landscape: boolean): LayoutSpec {
    const spec = (landscape ? L_LAYOUTS : P_LAYOUTS).get(this.layout);
    return spec ? spec : (landscape ? L_LAYOUTS.get(KeyLayout.LETTERS)! : P_LAYOUTS.get(KeyLayout.LETTERS)!);
  }

  getPR0(): string[] { return this.getCurrentLayoutSpec(false).row0; }
  getPR1(): string[] { return this.getCurrentLayoutSpec(false).row1; }
  getPR2(): string[] { return this.getCurrentLayoutSpec(false).row2; }
  getPR3Inner(): string[] { return this.getCurrentLayoutSpec(false).row3Inner; }
  getLR0(): string[] { return this.getCurrentLayoutSpec(true).row0; }
  getLR1(): string[] { return this.getCurrentLayoutSpec(true).row1; }
  getLR2(): string[] { return this.getCurrentLayoutSpec(true).row2; }
  getLR3Inner(): string[] { return this.getCurrentLayoutSpec(true).row3Inner; }

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
    this.isShifted = false;
  }

  switchRow3Left(): void {
    const spec = this.getCurrentLayoutSpec(this.isLandscape);
    if (spec.row3Left === 'SHIFT') {
      this.handleShiftTap();
      return;
    }
    if (spec.row3LeftTarget !== null) {
      this.layout = spec.row3LeftTarget;
      this.isShifted = false;
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
    this.isShifted = false;
  }

  getEmojiRowIndexes(): number[] {
    const count = Math.ceil(EMOJI_CATS[this.emojiCat].items.length / 8);
    const indexes: number[] = [];
    for (let i = 0; i < count; i++) {
      indexes.push(i);
    }
    return indexes;
  }

  // ── Dữ liệu hàng theo layout + hướng ──
  // ── Thanh gợi ý ──
  @Builder
  buildBar(landscape: boolean) {
    Row() {
      if (this.composingText.length > 0) {
        Text(this.composingText)
          .fontSize(landscape ? 12 : 14).fontColor('#60A5FA')
          .padding({ left: 8, right: 6 }).maxLines(1)
        ForEach(this.candidates.slice(0, 5), (c: string) => {
          Text(c)
            .fontSize(landscape ? 12 : 14).fontColor(this.txt)
            .padding({ left: 10, right: 10 }).maxLines(1)
            .onClick(() => KeyboardBridge.sendPasteText(c))
        })
      }
      Blank()
    }
    .width('100%')
    .height(landscape ? CFG_L.barH : CFG_P.barH)
    .backgroundColor('#181818')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 2 })
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
    .padding({ top: landscape ? CFG_L.mV : CFG_P.mV, bottom: landscape ? CFG_L.mV : CFG_P.mV })
  }

  // ──────────────────────────────────────────
  //  BUILDERS PHÍM
  // ──────────────────────────────────────────

  /** Phím thường – layoutWeight(1) */
  @Builder
  buildKey(k: string, landscape: boolean) {
    Button() {
      Text(this.lbl(k))
        .fontSize(this.isSpecial(k) ? (landscape ? CFG_L.fsS : CFG_P.fsS) : (landscape ? CFG_L.fs : CFG_P.fs))
        .fontColor(this.txt)
        .fontWeight(this.isSpecial(k) ? FontWeight.Medium : FontWeight.Regular)
        .textAlign(TextAlign.Center).maxLines(1)
    }
    .layoutWeight(1)
    .height(landscape ? CFG_L.kH : CFG_P.kH)
    .margin({ left: landscape ? CFG_L.mH : CFG_P.mH, right: landscape ? CFG_L.mH : CFG_P.mH })
    .backgroundColor(this.bgK(k))
    .borderRadius(landscape ? CFG_L.rKey : CFG_P.rKey)
    .onClick(() => this.tap(k))
  }

  /** Nút trái hàng 4: SHIFT / #+= / 123 */
  @Builder
  buildRow3LeftKey(landscape: boolean) {
    Button() {
      Text(this.getR3LeftLabel())
        .fontSize(landscape ? CFG_L.fsS : CFG_P.fsS)
        .fontColor(this.txt).fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center).maxLines(1)
    }
    .layoutWeight(landscape ? CFG_L.wShift : CFG_P.wShift)
    .height(landscape ? CFG_L.kH : CFG_P.kH)
    .margin({ left: landscape ? CFG_L.mH : CFG_P.mH, right: landscape ? CFG_L.mH : CFG_P.mH })
    .backgroundColor(this.bgK(this.getR3LeftKey()))
    .borderRadius(landscape ? CFG_L.rKey : CFG_P.rKey)
    .onTouch((event: TouchEvent) => {
      if (this.getR3LeftKey() === 'SHIFT') {
        this.onShiftTouch(event);
      }
    })
    .onClick(() => {
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
    Button() {
      Text(k === this.getR3LeftKey() ? this.getR3LeftLabel() : this.lbl(k))
        .fontSize(landscape ? CFG_L.fsS : CFG_P.fsS)
        .fontColor(this.txt).fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center).maxLines(1)
    }
    .layoutWeight(w)
    .height(landscape ? CFG_L.kH : CFG_P.kH)
    .margin({ left: landscape ? CFG_L.mH : CFG_P.mH, right: landscape ? CFG_L.mH : CFG_P.mH })
    .backgroundColor(this.bgK(k))
    .borderRadius(landscape ? CFG_L.rKey : CFG_P.rKey)
    .onTouch((event: TouchEvent) => {
      if (k === 'SHIFT') {
        this.onShiftTouch(event);
      }
      if (k === 'BACKSPACE') {
        this.onBackspaceTouch(event);
      }
    })
    .onClick(() => {
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
    Button() {
      Text(lbl)
        .fontSize(lbl === '↵' ? (landscape ? 18 : 20) : (landscape ? CFG_L.fsS : CFG_P.fsS))
        .fontColor(this.txt).fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center).maxLines(1)
    }
    .layoutWeight(w)
    .height(landscape ? CFG_L.kH : CFG_P.kH)
    .margin({ left: landscape ? CFG_L.mH : CFG_P.mH, right: landscape ? CFG_L.mH : CFG_P.mH })
    .backgroundColor(this.keyS)
    .borderRadius(landscape ? CFG_L.rKey : CFG_P.rKey)
    .onClick(action)
  }

  /** Phím cách */
  @Builder
  buildSpaceKey(w: number, landscape: boolean) {
    Button() { Text('').fontSize(0) }
    .layoutWeight(w)
    .height(landscape ? CFG_L.kH : CFG_P.kH)
    .margin({ left: landscape ? CFG_L.mH : CFG_P.mH, right: landscape ? CFG_L.mH : CFG_P.mH })
    .backgroundColor(this.keyN)
    .borderRadius(landscape ? CFG_L.rSpace : CFG_P.rSpace)
    .onClick(() => KeyboardBridge.sendKey(' '))
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
      .padding({ left: this.isLandscape ? CFG_L.mH : CFG_P.mH,
                 right: this.isLandscape ? CFG_L.mH : CFG_P.mH,
                 top: this.isLandscape ? CFG_L.mV : CFG_P.mV,
                 bottom: this.isLandscape ? CFG_L.mV : CFG_P.mV })
    }
    .width('100%').height(this.panelVp).backgroundColor(this.bg)
  }

  // ═══════════════════════════════════════════
  //  CLIPBOARD
  // ═══════════════════════════════════════════
  @Builder
  buildClipboard() {
    Column() {
      Row() {
        Text('📋  Clipboard').fontSize(13).fontColor('#AAAACC').fontWeight(FontWeight.Bold).padding({ left: 12 })
        Blank()
        Button('✕').width(28).height(28).fontSize(13).fontColor('#666688').backgroundColor('transparent')
          .onClick(() => { this.showClipboard = false; }).margin({ right: 8 })
      }
      .width('100%').height(36).backgroundColor('#0D0D22').alignItems(VerticalAlign.Center)

      if (this.clipboardItems.length === 0) {
        Text('Chưa có nội dung clipboard').fontSize(13).fontColor('#444466')
          .width('100%').textAlign(TextAlign.Center).padding({ top: 16, bottom: 16 })
      } else {
        Scroll() {
          Column() {
            ForEach(this.clipboardItems, (item: ClipboardItem) => {
              if (item.type !== 'image') {
                Row() {
                  Text(item.text || '').fontSize(13).fontColor('#CCCCEE')
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1).margin({ right: 8 })
                  Button('Dán').fontSize(12).fontColor('#4FC3F7').height(26)
                    .padding({ left: 10, right: 10 }).backgroundColor('#101030').borderRadius(6)
                    .onClick(() => KeyboardBridge.sendPasteText(item.text || ''))
                }
                .width('100%').padding({ left: 12, right: 10, top: 7, bottom: 7 })
                .border({ width: { bottom: 1 }, color: '#181830' })
                .alignItems(VerticalAlign.Center)
              }
            })
          }
        }
        .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).constraintSize({ maxHeight: 140 })
      }
    }
    .width('100%').backgroundColor('#232831')
  }
}
  .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).constraintSize({ maxHeight: 140 })
      }
    }
    .width('100%').backgroundColor('#232831')
  }
}
