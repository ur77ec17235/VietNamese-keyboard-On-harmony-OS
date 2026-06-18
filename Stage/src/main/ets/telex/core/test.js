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

let buffer = '';
function applySeparatedUowModifier() {
    const finalStart = getFinalConsonantStart(buffer);
    if (finalStart < 2) return false;

    let i = finalStart - 1;
    while (i > 0) {
      if (!isBaseVowel(getBaseVowel(buffer[i]))) break;

      const secondIndex = i;
      const firstIndex = i - 1;
      const firstBase = getBaseVowel(buffer[firstIndex]);
      const secondBase = getBaseVowel(buffer[secondIndex]);
      const canApplyUow = (firstBase === 'u' || firstBase === 'ư') && (secondBase === 'o' || secondBase === 'ơ');
      
      if (canApplyUow) {
        const first = buffer[firstIndex];
        const second = buffer[secondIndex];
        
        if (firstBase === 'ư' && secondBase === 'ơ') {
          buffer = buffer.substring(0, firstIndex) +
            matchCaseForEscape(first, 'u') +
            matchCaseForEscape(second, 'o') +
            buffer.substring(secondIndex + 1) +
            'w';
          return true;
        }

        buffer = buffer.substring(0, firstIndex) +
          applyVowelBase(first, 'ư') +
          applyVowelBase(second, 'ơ') +
          buffer.substring(secondIndex + 1);
        return true;
      }
      i--;
    }
    return false;
}

buffer = 'tuoi';
console.log('tuoi ->', applySeparatedUowModifier(), buffer); // true tươi
buffer = 'tươi';
console.log('tươi + w ->', applySeparatedUowModifier(), buffer); // true tuoiw
buffer = 'nguoi';
console.log('nguoi ->', applySeparatedUowModifier(), buffer); // true người
