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
    const finalLength = lower.length - vowelPositions[vowelPositions.length - 1] - 1;

    // Gi- rules (giữ, giá, giêng)
    if (vowelPositions.length >= 2 && vowelPositions[0] > 0 && lower[vowelPositions[0] - 1] === 'g' && getBaseVowel(lower[vowelPositions[0]]) === 'i') {
      if (cluster === 'ie' || cluster === 'iê') {
         return vowelPositions[1]; // giêng -> ê
      }
      return vowelPositions[1]; // giá -> á, giỗ -> ỗ
    }

    // Qu- rules
    if (vowelPositions.length >= 2 && vowelPositions[0] > 0 && lower[vowelPositions[0] - 1] === 'q' && getBaseVowel(lower[vowelPositions[0]]) === 'u') {
      if (vowelPositions.length === 2) return vowelPositions[1]; // quá, quy
      if (vowelPositions.length === 3) return vowelPositions[1]; // quay
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

console.log('liê', findTonePosition('liê')); // expected 2 (ê)
console.log('hoa', findTonePosition('hoa')); // expected 2 (a)
console.log('khoe', findTonePosition('khoe')); // expected 3 (e)
console.log('thuy', findTonePosition('thuy')); // expected 3 (y)
console.log('qua', findTonePosition('qua')); // expected 2 (a)
console.log('quoc', findTonePosition('quoc')); // expected 2 (o)
console.log('gia', findTonePosition('gia')); // expected 2 (a)
console.log('gieng', findTonePosition('gieng')); // expected 2 (e)
console.log('mua', findTonePosition('mua')); // expected 1 (u)
console.log('nui', findTonePosition('nui')); // expected 1 (u)
console.log('tai', findTonePosition('tai')); // expected 1 (a)
console.log('ngay', findTonePosition('ngay')); // expected 2 (a)
