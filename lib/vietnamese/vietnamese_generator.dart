import 'dart:math';

import 'vietnamese_level.dart';
import 'vietnamese_question.dart';

/// Generates [count] distinct Vietnamese questions for [level] using [random].
List<VietnameseQuestion> generateVietnameseQuestions(
  VietnameseLevel level,
  Random random, {
  int count = 5,
}) {
  return switch (level.kind) {
    VietnameseKind.vowel => _pickFrom(_vowels, random, count, _letterQuestion),
    VietnameseKind.consonant =>
      _pickFrom(_consonants, random, count, _letterQuestion),
    VietnameseKind.tone => _pickFrom(_tones, random, count, _toneQuestion),
    VietnameseKind.syllableBuild =>
      _pickFrom(_syllableBuilds, random, count, _buildRightQuestion),
    VietnameseKind.digraph =>
      _pickFrom(_digraphs, random, count, _buildLeftQuestion),
    VietnameseKind.openRhyme =>
      _pickFrom(_openRhymes, random, count, _buildRightQuestion),
    VietnameseKind.closedRhyme =>
      _pickFrom(_closedRhymes, random, count, _buildRightQuestion),
    VietnameseKind.wordRead => _pickFrom(_words, random, count, _wordQuestion),
    VietnameseKind.phraseFill =>
      _pickFrom(_phrases, random, count, _phraseQuestion),
  };
}

List<VietnameseQuestion> _pickFrom<T>(
  List<T> pool,
  Random random,
  int count,
  VietnameseQuestion Function(T item, Random random) build,
) {
  final copy = List<T>.of(pool)..shuffle(random);
  final out = <VietnameseQuestion>[];
  for (var i = 0; i < count; i++) {
    out.add(build(copy[i % copy.length], random));
  }
  return out;
}

(List<String>, int) _shuffledChoices(
  String correct,
  List<String> distractors,
  Random random,
) {
  final picks = <String>[correct];
  final shuffled = List<String>.of(distractors)..shuffle(random);
  for (final d in shuffled) {
    if (picks.length >= 3) break;
    if (d != correct && !picks.contains(d)) picks.add(d);
  }
  assert(picks.length == 3, 'Need 2 unique distractors for "$correct"');
  picks.shuffle(random);
  return (picks, picks.indexOf(correct));
}

// --- Level 1 & 2: Vowels & Single Consonants --------------------------------

class _LetterEntry {
  const _LetterEntry(this.letter, this.spoken, this.confusables);
  final String letter;
  final String spoken;
  final List<String> confusables;
}

const _vowels = <_LetterEntry>[
  _LetterEntry('a', 'chữ a', ['ă', 'â', 'o']),
  _LetterEntry('ă', 'chữ á', ['a', 'â', 'u']),
  _LetterEntry('â', 'chữ ớ', ['a', 'ă', 'ô']),
  _LetterEntry('e', 'chữ e', ['ê', 'c', 'o']),
  _LetterEntry('ê', 'chữ ê', ['e', 'â', 'ô']),
  _LetterEntry('i', 'chữ i', ['y', 'l', 't']),
  _LetterEntry('o', 'chữ o', ['ô', 'ơ', 'a']),
  _LetterEntry('ô', 'chữ ô', ['o', 'ơ', 'â']),
  _LetterEntry('ơ', 'chữ ơ', ['o', 'ô', 'ư']),
  _LetterEntry('u', 'chữ u', ['ư', 'n', 'v']),
  _LetterEntry('ư', 'chữ ư', ['u', 'ơ', 'v']),
  _LetterEntry('y', 'chữ i dài', ['i', 'u', 'v']),
];

const _consonants = <_LetterEntry>[
  _LetterEntry('b', 'chữ bờ', ['d', 'đ', 'p']),
  _LetterEntry('c', 'chữ cờ', ['o', 'e', 'k']),
  _LetterEntry('d', 'chữ dờ', ['đ', 'b', 'q']),
  _LetterEntry('đ', 'chữ đờ', ['d', 'b', 't']),
  _LetterEntry('g', 'chữ gờ', ['q', 'y', 'p']),
  _LetterEntry('h', 'chữ hờ', ['k', 'n', 'b']),
  _LetterEntry('k', 'chữ ca', ['h', 'l', 'c']),
  _LetterEntry('l', 'chữ lờ', ['i', 't', 'h']),
  _LetterEntry('m', 'chữ mờ', ['n', 'u', 'w']),
  _LetterEntry('n', 'chữ nờ', ['m', 'u', 'h']),
  _LetterEntry('p', 'chữ pờ', ['q', 'b', 'd']),
  _LetterEntry('q', 'chữ cu', ['p', 'g', 'd']),
  _LetterEntry('r', 'chữ rờ', ['n', 's', 'v']),
  _LetterEntry('s', 'chữ sờ', ['x', 'r', 'c']),
  _LetterEntry('t', 'chữ tờ', ['đ', 'l', 'i']),
  _LetterEntry('v', 'chữ vờ', ['u', 'y', 'r']),
  _LetterEntry('x', 'chữ xờ', ['s', 'k', 'v']),
];

VietnameseQuestion _letterQuestion(_LetterEntry e, Random r) {
  final (choices, idx) = _shuffledChoices(e.letter, e.confusables, r);
  return VietnameseQuestion(
    id: 'letter-${e.letter}',
    displayKind: VietnameseDisplayKind.listenPick,
    prompt: 'Nghe và chọn đúng chữ cái nhé!',
    speech: 'Bé tìm giúp Chíp ${e.spoken} nhé!',
    celebrationSpeech: 'Đúng rồi! Đây là ${e.spoken}!',
    choices: choices,
    correctIndex: idx,
  );
}

// --- Level 3: Tones ---------------------------------------------------------

class _ToneEntry {
  const _ToneEntry(this.word, this.toneName, this.confusables);
  final String word;
  final String toneName;
  final List<String> confusables;
}

const _tones = <_ToneEntry>[
  _ToneEntry('bà', 'dấu huyền', ['ba', 'bá', 'bả']),
  _ToneEntry('cá', 'dấu sắc', ['ca', 'cà', 'cả']),
  _ToneEntry('cỏ', 'dấu hỏi', ['co', 'có', 'cò']),
  _ToneEntry('ngã', 'dấu ngã', ['nga', 'ngả', 'ngạ']),
  _ToneEntry('mẹ', 'dấu nặng', ['me', 'mé', 'mè']),
  _ToneEntry('bố', 'dấu sắc', ['bô', 'bồ', 'bổ']),
  _ToneEntry('cô', 'thanh ngang', ['cố', 'cồ', 'cổ']),
  _ToneEntry('mũ', 'dấu ngã', ['mu', 'mú', 'mù']),
  _ToneEntry('lá', 'dấu sắc', ['la', 'là', 'lả']),
  _ToneEntry('gà', 'dấu huyền', ['ga', 'gá', 'gả']),
  _ToneEntry('thỏ', 'dấu hỏi', ['tho', 'thó', 'thò']),
  _ToneEntry('cọ', 'dấu nặng', ['co', 'có', 'cỏ']),
];

VietnameseQuestion _toneQuestion(_ToneEntry e, Random r) {
  final (choices, idx) = _shuffledChoices(e.word, e.confusables, r);
  return VietnameseQuestion(
    id: 'tone-${e.word}',
    displayKind: VietnameseDisplayKind.listenPick,
    prompt: 'Nghe thật kỹ dấu thanh nhé!',
    speech: 'Bé chọn tiếng "${e.word}" có ${e.toneName} nhé!',
    celebrationSpeech: 'Đúng rồi! Tiếng ${e.word}!',
    choices: choices,
    correctIndex: idx,
  );
}

// --- Level 4, 5, 6, 7: Syllable / Digraph / Rhyme Building ------------------

class _BuildEntry {
  const _BuildEntry(
    this.left,
    this.right,
    this.result,
    this.spellingSpeech,
    this.confusables,
  );
  final String left;
  final String right;
  final String result;
  final String spellingSpeech;
  final List<String> confusables;
}

const _syllableBuilds = <_BuildEntry>[
  _BuildEntry('b', 'a', 'ba', 'bờ a ba', ['o', 'e', 'u']),
  _BuildEntry('m', 'e', 'me', 'mờ e me', ['a', 'i', 'o']),
  _BuildEntry('c', 'ô', 'cô', 'cờ ô cô', ['o', 'ơ', 'a']),
  _BuildEntry('n', 'ơ', 'nơ', 'nờ ơ nơ', ['o', 'ô', 'ư']),
  _BuildEntry('b', 'i', 'bi', 'bờ i bi', ['a', 'e', 'u']),
  _BuildEntry('c', 'á', 'cá', 'cờ a ca sắc cá', ['à', 'ả', 'ó']),
  _BuildEntry('l', 'á', 'lá', 'lờ a la sắc lá', ['é', 'ó', 'ú']),
  _BuildEntry('g', 'à', 'gà', 'gờ a ga huyền gà', ['ò', 'è', 'ù']),
  _BuildEntry('m', 'ũ', 'mũ', 'mờ u mu ngã mũ', ['ã', 'õ', 'ẽ']),
  _BuildEntry('b', 'ò', 'bò', 'bờ o bo huyền bò', ['à', 'ồ', 'ờ']),
];

const _digraphs = <_BuildEntry>[
  _BuildEntry('ch', 'ó', 'chó', 'chờ o cho sắc chó', ['tr', 'nh', 'th']),
  _BuildEntry('gh', 'ế', 'ghế', 'gờ ghép ê ghê sắc ghế', ['ng', 'kh', 'ph']),
  _BuildEntry('kh', 'ỉ', 'khỉ', 'khờ i khi hỏi khỉ', ['ch', 'th', 'nh']),
  _BuildEntry('nh', 'à', 'nhà', 'nhờ a nha huyền nhà', ['ng', 'ch', 'ph']),
  _BuildEntry('ph', 'ở', 'phở', 'phờ ơ phơ hỏi phở', ['th', 'kh', 'tr']),
  _BuildEntry('th', 'ỏ', 'thỏ', 'thờ o tho hỏi thỏ', ['tr', 'ph', 'ch']),
  _BuildEntry('tr', 'e', 'tre', 'trờ e tre', ['ch', 'th', 'nh']),
  _BuildEntry('ng', 'à', 'ngà', 'ngờ a nga huyền ngà', ['nh', 'gh', 'kh']),
  _BuildEntry('qu', 'ả', 'quả', 'quờ a qua hỏi quả', ['gh', 'ng', 'ph']),
  _BuildEntry('gi', 'ỏ', 'giỏ', 'di o gio hỏi giỏ', ['ch', 'tr', 'nh']),
];

const _openRhymes = <_BuildEntry>[
  _BuildEntry('m', 'ai', 'mai', 'mờ ai mai', ['ao', 'au', 'oi']),
  _BuildEntry('s', 'ao', 'sao', 'sờ ao sao', ['ai', 'au', 'oi']),
  _BuildEntry('t', 'àu', 'tàu', 'tờ au tau huyền tàu', ['ào', 'ài', 'òi']),
  _BuildEntry('c', 'ây', 'cây', 'cờ ây cây', ['ay', 'âu', 'ơi']),
  _BuildEntry('v', 'oi', 'voi', 'vờ oi voi', ['ôi', 'ơi', 'ai']),
  _BuildEntry('n', 'úi', 'núi', 'nờ ui nui sắc núi', ['ói', 'ái', 'ối']),
  _BuildEntry('m', 'ây', 'mây', 'mờ ây mây', ['ay', 'ai', 'âu']),
  _BuildEntry('đ', 'ồi', 'đồi', 'đờ ôi đôi huyền đồi', ['òi', 'ời', 'ùi']),
  _BuildEntry('tr', 'ời', 'trời', 'trờ ơi trơi huyền trời', ['òi', 'ồi', 'ài']),
  _BuildEntry('t', 'ay', 'tay', 'tờ ay tay', ['ây', 'ai', 'ao']),
];

const _closedRhymes = <_BuildEntry>[
  _BuildEntry('b', 'àn', 'bàn', 'bờ an ban huyền bàn', ['ầm', 'òn', 'èn']),
  _BuildEntry('đ', 'èn', 'đèn', 'đờ en đen huyền đèn', ['àn', 'òn', 'ền']),
  _BuildEntry('ch', 'im', 'chim', 'chờ im chim', ['in', 'om', 'am']),
  _BuildEntry('b', 'óng', 'bóng', 'bờ ong bong sắc bóng', ['áng', 'ứng', 'ống']),
  _BuildEntry('tr', 'ăng', 'trăng', 'trờ ăng trăng', ['ang', 'ong', 'ung']),
  _BuildEntry('c', 'am', 'cam', 'cờ am cam', ['an', 'om', 'em']),
  _BuildEntry('s', 'ơn', 'sơn', 'sờ ơn sơn', ['on', 'ôn', 'ân']),
  _BuildEntry('c', 'on', 'con', 'cờ on con', ['ôn', 'ơn', 'an']),
  _BuildEntry('t', 'ôm', 'tôm', 'tờ ôm tôm', ['om', 'ơm', 'am']),
  _BuildEntry('kh', 'ăn', 'khăn', 'khờ ăn khăn', ['an', 'ân', 'en']),
];

VietnameseQuestion _buildRightQuestion(_BuildEntry e, Random r) {
  final (choices, idx) = _shuffledChoices(e.right, e.confusables, r);
  return VietnameseQuestion(
    id: 'build-r-${e.result}',
    displayKind: VietnameseDisplayKind.equationBuild,
    prompt: 'Ghép vần đúng để tạo thành tiếng "${e.result}" nhé!',
    speech: 'Bé ghép để tạo tiếng ${e.result} nhé! ${e.spellingSpeech}.',
    celebrationSpeech: 'Đúng rồi! ${e.spellingSpeech}!',
    choices: choices,
    correctIndex: idx,
    equationLeft: e.left,
    equationRight: null,
    equationResult: e.result,
  );
}

VietnameseQuestion _buildLeftQuestion(_BuildEntry e, Random r) {
  final (choices, idx) = _shuffledChoices(e.left, e.confusables, r);
  return VietnameseQuestion(
    id: 'build-l-${e.result}',
    displayKind: VietnameseDisplayKind.equationBuild,
    prompt: 'Chọn âm đầu đúng cho tiếng "${e.result}" nhé!',
    speech: 'Bé chọn âm đầu để ghép tiếng ${e.result} nhé! ${e.spellingSpeech}.',
    celebrationSpeech: 'Đúng rồi! ${e.spellingSpeech}!',
    choices: choices,
    correctIndex: idx,
    equationLeft: null,
    equationRight: e.right,
    equationResult: e.result,
  );
}

// --- Level 8: Reading Familiar 2-Syllable Words -----------------------------

class _WordEntry {
  const _WordEntry(this.word, this.confusables);
  final String word;
  final List<String> confusables;
}

const _words = <_WordEntry>[
  _WordEntry('con mèo', ['con chó', 'con cá', 'con gà']),
  _WordEntry('quả cam', ['quả na', 'quả lê', 'quả me']),
  _WordEntry('cái bàn', ['cái ghế', 'cái đèn', 'cái mũ']),
  _WordEntry('bông hoa', ['lá cây', 'đám mây', 'ngôi sao']),
  _WordEntry('ngôi sao', ['mặt trời', 'mặt trăng', 'đám mây']),
  _WordEntry('xe đạp', ['ô tô', 'tàu hỏa', 'máy bay']),
  _WordEntry('mặt trời', ['ngôi sao', 'mặt trăng', 'bầu trời']),
  _WordEntry('cá vàng', ['con mèo', 'gà con', 'vịt con']),
  _WordEntry('quyển vở', ['cây bút', 'cái thước', 'cặp sách']),
  _WordEntry('nhà gỗ', ['nhà lá', 'cửa sổ', 'cầu gỗ']),
];

VietnameseQuestion _wordQuestion(_WordEntry e, Random r) {
  final (choices, idx) = _shuffledChoices(e.word, e.confusables, r);
  return VietnameseQuestion(
    id: 'word-${e.word}',
    displayKind: VietnameseDisplayKind.listenPick,
    prompt: 'Nghe Chíp đọc và chọn đúng từ nhé!',
    speech: 'Bé chọn từ "${e.word}" giúp Chíp nhé!',
    celebrationSpeech: 'Giỏi quá! ${e.word}!',
    choices: choices,
    correctIndex: idx,
  );
}

// --- Level 9: Completing Short Familiar Phrases -----------------------------

class _PhraseEntry {
  const _PhraseEntry(
    this.before,
    this.missing,
    this.after,
    this.confusables,
  );
  final String before;
  final String missing;
  final String after;
  final List<String> confusables;

  String get full => [
        if (before.isNotEmpty) before,
        missing,
        if (after.isNotEmpty) after,
      ].join(' ');
}

const _phrases = <_PhraseEntry>[
  _PhraseEntry('bé đi', 'học', '', ['ngủ', 'bay', 'bơi']),
  _PhraseEntry('gà gáy', 'sáng', '', ['tối', 'xanh', 'tròn']),
  _PhraseEntry('chim hót', 'hay', '', ['bàn', 'ghế', 'xe']),
  _PhraseEntry('mèo bắt', 'chuột', '', ['cây', 'hoa', 'sao']),
  _PhraseEntry('cá bơi dưới', 'nước', '', ['mây', 'trời', 'bàn']),
  _PhraseEntry('hoa nở mùa', 'xuân', '', ['sách', 'bút', 'đèn']),
  _PhraseEntry('bé yêu', 'mẹ', 'nhất', ['bàn', 'đá', 'xe']),
  _PhraseEntry('trời có nhiều', 'sao', '', ['ghế', 'bút', 'mũ']),
  _PhraseEntry('ong đi tìm', 'mật', '', ['đá', 'ghế', 'bàn']),
  _PhraseEntry('trăng sáng đêm', 'rằm', '', ['ghế', 'bàn', 'xe']),
];

VietnameseQuestion _phraseQuestion(_PhraseEntry e, Random r) {
  final (choices, idx) = _shuffledChoices(e.missing, e.confusables, r);
  return VietnameseQuestion(
    id: 'phrase-${e.full}',
    displayKind: VietnameseDisplayKind.phraseFill,
    prompt: 'Chọn tiếng đúng điền vào chỗ trống nhé!',
    speech: 'Bé nghe câu này nhé: "${e.full}". Điền tiếng nào vào chỗ trống nhỉ?',
    celebrationSpeech: 'Tuyệt vời! ${e.full}!',
    choices: choices,
    correctIndex: idx,
    phraseBefore: e.before,
    phraseAfter: e.after,
  );
}
