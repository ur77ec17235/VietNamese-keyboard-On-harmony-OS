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

function stripTones(word) {
    let strippedWord = '';
    let currentTone = 0;
    for (let i = 0; i < word.length; i++) {
      const ch = word[i];
      const base = getBaseVowel(ch);
      if (isBaseVowel(base)) {
        // Find existing tone to know if we are escaping it
        const lower = ch.toLowerCase();
        for (const [k, forms] of VOWEL_TABLE.entries()) {
           const idx = forms.indexOf(lower);
           if (idx > 0) currentTone = idx;
        }

        const isUpper = ch === ch.toUpperCase() && ch !== ch.toLowerCase();
        strippedWord += isUpper ? base.toUpperCase() : base;
      } else {
        strippedWord += ch;
      }
    }
    return { strippedWord, currentTone };
}

console.log(stripTones('ỉêp')); // expected iêp
console.log(stripTones('Việt')); // expected Viêt
console.log(stripTones('QUỐC')); // expected QUÔC

