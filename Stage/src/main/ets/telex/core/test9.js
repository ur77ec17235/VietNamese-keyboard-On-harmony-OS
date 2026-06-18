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
const TONE_INDEX = new Map([
  ['s', 1],
  ['f', 2],
  ['r', 3],
  ['x', 4],
  ['j', 5],
]);
function getToneKey(toneIdx) {
    for (const key of TONE_INDEX.keys()) {
      if (TONE_INDEX.get(key) === toneIdx) {
        return key;
      }
    }
    return '';
}
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
function applyTone(vowel, toneIdx) {
  const base = getBaseVowel(vowel);
  const forms = VOWEL_TABLE.get(base);
  if (!forms) return vowel;
  const isUpper = vowel === vowel.toUpperCase() && vowel !== vowel.toLowerCase();
  const newVowel = forms[toneIdx] || base;
  return isUpper ? newVowel.toUpperCase() : newVowel;
}

function getVowelCluster(word, positions) {
    let cluster = '';
    for (let i = 0; i < positions.length; i++) {
      cluster += getBaseVowel(word[positions[i]]);
    }
    return cluster;
}

function findTonePosition(word) {
    const lower = word.toLowerCase();
    const runs = [];
    let currentRun = [];
    for (let i = 0; i < lower.length; i++) {
      if (isBaseVowel(getBaseVowel(lower[i]))) {
        currentRun.push(i);
      } else if (currentRun.length > 0) {
        runs.push(currentRun);
        currentRun = [];
      }
    }
    if (currentRun.length > 0) {
      runs.push(currentRun);
    }

    if (runs.length === 0) return -1;

    const vowelPositions = runs[runs.length - 1];
    if (vowelPositions.length === 1) return vowelPositions[0];

    const cluster = getVowelCluster(lower, vowelPositions);
    
    if (vowelPositions.length >= 2 && vowelPositions[0] > 0 && lower[vowelPositions[0] - 1] === 'g' && getBaseVowel(lower[vowelPositions[0]]) === 'i') {
      return vowelPositions[1]; 
    }

    if (vowelPositions.length >= 2 && vowelPositions[0] > 0 && lower[vowelPositions[0] - 1] === 'q' && getBaseVowel(lower[vowelPositions[0]]) === 'u') {
      if (vowelPositions.length === 2) return vowelPositions[1]; 
      if (vowelPositions.length === 3) {
        if (cluster === 'uye' || cluster === 'uyê') return vowelPositions[2];
        return vowelPositions[1]; 
      }
      if (vowelPositions.length === 4) {
        return vowelPositions[2]; 
      }
    }

    if (cluster === 'ie' || cluster === 'iê' || cluster === 'ye' || cluster === 'yê' ||
      cluster === 'uo' || cluster === 'uô' || cluster === 'ươ') {
      return vowelPositions[1];
    }

    if (cluster === 'uyê' || cluster === 'uye') {
      return vowelPositions[vowelPositions.length - 1];
    }

    if (vowelPositions.length >= 3) {
      return vowelPositions[1];
    }

    if (cluster === 'oa' || cluster === 'oe' || cluster === 'uy') {
      return vowelPositions[1];
    }

    return vowelPositions[0];
}

function applyToneToWord(word, toneIdx, appendToneKeyOnEscape) {
    const positions = findTonePosition(word);
    if (positions < 0) return null;

    let strippedWord = '';
    let existingTone = 0;
    
    for (let i = 0; i < word.length; i++) {
      const ch = word[i];
      const base = getBaseVowel(ch);
      if (isBaseVowel(base)) {
        const tone = getCurrentTone(ch);
        if (tone > 0) existingTone = tone;
        
        const isUpper = ch === ch.toUpperCase() && ch !== ch.toLowerCase();
        strippedWord += isUpper ? base.toUpperCase() : base;
      } else {
        strippedWord += ch;
      }
    }

    let result = strippedWord;

    if (existingTone === toneIdx) {
      // Escape
      if (appendToneKeyOnEscape) {
        result += getToneKey(toneIdx);
      }
    } else {
      // Apply new tone
      const ch = result[positions];
      result = result.substring(0, positions) + applyTone(ch, toneIdx) + result.substring(positions + 1);
    }
    return result;
}

console.log('ỉêp + s ->', applyToneToWord('ỉêp', 1, true)); // iếp
console.log('hòa + s ->', applyToneToWord('hòa', 1, true)); // hoá
console.log('iếp + s ->', applyToneToWord('iếp', 1, true)); // iêps

