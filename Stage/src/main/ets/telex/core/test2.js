function getTelexEscapeText(baseVowel, escapeKey) {
    if (escapeKey === 'w') {
      if (baseVowel === 'ă') return 'aw';
      if (baseVowel === 'ơ') return 'ow';
      if (baseVowel === 'ư') return 'uw';
    }
    return '';
}

const FINAL_CONSONANTS = ['ng', 'nh', 'ch', 'n', 'm', 't', 'c', 'p', 'g', 'k'];
function getFinalConsonantStart(word) {
  const lower = word.toLowerCase();
  for (const finalConsonant of FINAL_CONSONANTS) {
    if (lower.endsWith(finalConsonant) && lower.length > finalConsonant.length) {
      return lower.length - finalConsonant.length;
    }
  }
  return word.length;
}

const VOWEL_TABLE = new Map([
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
function getBaseVowel(ch) {
  for (const base of VOWEL_TABLE.keys()) {
    const forms = VOWEL_TABLE.get(base);
    if (forms.includes(ch.toLowerCase())) return base;
  }
  return ch.toLowerCase();
}
function isBaseVowel(ch) {
  return ['a', 'â', 'ă', 'e', 'ê', 'i', 'o', 'ô', 'ơ', 'u', 'ư', 'y'].includes(ch.toLowerCase());
}
function getCurrentTone(ch) {
  const lower = ch.toLowerCase();
  for (const base of VOWEL_TABLE.keys()) {
    const forms = VOWEL_TABLE.get(base);
    const idx = forms.indexOf(lower);
    if (idx > 0) return idx;
  }
  return 0;
}
function applyVowelBase(vowel, newBase) {
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
function matchCaseForEscape(source, text) {
  const isUpper = source === source.toUpperCase() && source !== source.toLowerCase();
  return isUpper ? text.toUpperCase() : text;
}

let buffer = '';

function findModifierTargetIndex(targets) {
    const finalStart = getFinalConsonantStart(buffer);

    let i = finalStart - 1;
    while (i >= 0) {
      const base = getBaseVowel(buffer[i]);
      if (targets.includes(base)) return i;
      for (const target of targets) {
        if (getTelexEscapeText(buffer[i].toLowerCase(), target).length > 0) return i;
      }
      if (!isBaseVowel(base)) break;
      i--;
    }
    return -1;
}

function applySeparatedWModifier() {
    const targetIndex = findModifierTargetIndex(['a', 'o', 'u', 'ă', 'ơ', 'ư']);
    if (targetIndex < 0) return false;

    const target = buffer[targetIndex];
    const escapeText = getTelexEscapeText(target.toLowerCase(), 'w');
    if (escapeText.length > 0) {
      buffer = buffer.substring(0, targetIndex) +
        matchCaseForEscape(target, escapeText.substring(0, 1)) +
        buffer.substring(targetIndex + 1) +
        escapeText.substring(1);
      return true;
    }

    const VOWEL_MAP = new Map([
      ['aw', 'ă'], ['ow', 'ơ'], ['uw', 'ư']
    ]);
    const baseTarget = getBaseVowel(target);
    const mapped = VOWEL_MAP.get(baseTarget + 'w');
    if (mapped) {
      buffer = buffer.substring(0, targetIndex) +
        applyVowelBase(target, mapped) +
        buffer.substring(targetIndex + 1);
      return true;
    }

    return false;
}

buffer = 'oi';
console.log('oi ->', applySeparatedWModifier(), buffer); // true ơi
buffer = 'ơi';
console.log('ơi + w ->', applySeparatedWModifier(), buffer); // true oiw

buffer = 'oio';
console.log('oio ->', applySeparatedWModifier(), buffer); // true oiơ

