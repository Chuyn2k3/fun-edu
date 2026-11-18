import 'dart:math';

import 'package:flutter/material.dart';

import '../ui/theme/tokens.dart';
import 'english_level.dart';
import 'english_question.dart';

/// Generates [count] distinct English questions for [level] using [random].
List<EnglishQuestion> generateEnglishQuestions(
  EnglishLevel level,
  Random random, {
  int count = 5,
}) {
  return switch (level.kind) {
    EnglishKind.lettersAM => _pick(_lettersAM, random, count, _letterQuestion),
    EnglishKind.lettersNZ => _pick(_lettersNZ, random, count, _letterQuestion),
    EnglishKind.numbers => _pick(_numbers, random, count, _numberQuestion),
    EnglishKind.colors => _pick(_colors, random, count, _colorQuestion),
    EnglishKind.animals => _pick(_animals, random, count, _vocabQuestion),
    EnglishKind.foodFruit => _pick(_foodFruit, random, count, _vocabQuestion),
    EnglishKind.phonics => _pick(_phonics, random, count, _phonicsQuestion),
    EnglishKind.familyBody => _pick(_familyBody, random, count, _vocabQuestion),
    EnglishKind.greetings => _pick(_greetings, random, count, _phraseQuestion),
  };
}

List<EnglishQuestion> _pick<T>(
  List<T> pool,
  Random random,
  int count,
  EnglishQuestion Function(T item, Random r) build,
) {
  final copy = List<T>.of(pool)..shuffle(random);
  return [for (var i = 0; i < count; i++) build(copy[i % copy.length], random)];
}

(List<String>, int) _shuffledChoices(
  String correct,
  List<String> distractors,
  Random r,
) {
  final picks = <String>[correct];
  final pool = List<String>.of(distractors)..shuffle(r);
  for (final d in pool) {
    if (picks.length >= 3) break;
    if (d != correct && !picks.contains(d)) picks.add(d);
  }
  assert(picks.length == 3, 'Need 2 unique distractors for "$correct"');
  picks.shuffle(r);
  return (picks, picks.indexOf(correct));
}

// --- Levels 1 & 2: Alphabet A–M, N–Z ----------------------------------------

class _Letter {
  const _Letter(this.pair, this.spoken, this.confusables);
  final String pair;
  final String spoken;
  final List<String> confusables;
}

const _lettersAM = <_Letter>[
  _Letter('Aa', 'A', ['Ee', 'Hh', 'Kk']),
  _Letter('Bb', 'B', ['Dd', 'Pp', 'Gg']),
  _Letter('Cc', 'C', ['Gg', 'Ss', 'Ee']),
  _Letter('Dd', 'D', ['Bb', 'Tt', 'Pp']),
  _Letter('Ee', 'E', ['Ff', 'Ii', 'Aa']),
  _Letter('Ff', 'F', ['Ee', 'Ll', 'Hh']),
  _Letter('Gg', 'G', ['Jj', 'Cc', 'Dd']),
  _Letter('Hh', 'H', ['Aa', 'Kk', 'Nn']),
  _Letter('Ii', 'I', ['Ll', 'Ee', 'Jj']),
  _Letter('Jj', 'J', ['Gg', 'Ii', 'Kk']),
  _Letter('Kk', 'K', ['Cc', 'Hh', 'Jj']),
  _Letter('Ll', 'L', ['Ii', 'Ff', 'Mm']),
  _Letter('Mm', 'M', ['Nn', 'Ww', 'Ll']),
];

const _lettersNZ = <_Letter>[
  _Letter('Nn', 'N', ['Mm', 'Hh', 'Uu']),
  _Letter('Oo', 'O', ['Qq', 'Cc', 'Uu']),
  _Letter('Pp', 'P', ['Bb', 'Qq', 'Rr']),
  _Letter('Qq', 'Q', ['Oo', 'Pp', 'Gg']),
  _Letter('Rr', 'R', ['Pp', 'Bb', 'Nn']),
  _Letter('Ss', 'S', ['Cc', 'Xx', 'Zz']),
  _Letter('Tt', 'T', ['Dd', 'Pp', 'Vv']),
  _Letter('Uu', 'U', ['Vv', 'Ww', 'Oo']),
  _Letter('Vv', 'V', ['Uu', 'Ww', 'Yy']),
  _Letter('Ww', 'W', ['Vv', 'Mm', 'Uu']),
  _Letter('Xx', 'X', ['Ss', 'Zz', 'Kk']),
  _Letter('Yy', 'Y', ['Vv', 'Ii', 'Zz']),
  _Letter('Zz', 'Z', ['Ss', 'Xx', 'Cc']),
];

EnglishQuestion _letterQuestion(_Letter e, Random r) {
  final (choices, idx) = _shuffledChoices(e.pair, e.confusables, r);
  return EnglishQuestion(
    id: 'en-letter-${e.spoken}',
    displayKind: EnglishDisplayKind.listenPick,
    prompt: 'Nghe tiếng Anh và chọn đúng chữ cái nhé!',
    englishSpeech: e.spoken,
    vietnameseMeaning: 'Chữ ${e.spoken}',
    choices: choices,
    correctIndex: idx,
  );
}

// --- Level 3: Numbers 1–10 --------------------------------------------------

class _NumEntry {
  const _NumEntry(this.value, this.word, this.vn, this.confusables);
  final int value;
  final String word;
  final String vn;
  final List<String> confusables;
}

const _numbers = <_NumEntry>[
  _NumEntry(1, 'one', 'số 1', ['two', 'ten', 'six']),
  _NumEntry(2, 'two', 'số 2', ['one', 'three', 'ten']),
  _NumEntry(3, 'three', 'số 3', ['two', 'four', 'five']),
  _NumEntry(4, 'four', 'số 4', ['five', 'three', 'nine']),
  _NumEntry(5, 'five', 'số 5', ['four', 'six', 'nine']),
  _NumEntry(6, 'six', 'số 6', ['seven', 'five', 'ten']),
  _NumEntry(7, 'seven', 'số 7', ['six', 'eight', 'nine']),
  _NumEntry(8, 'eight', 'số 8', ['seven', 'nine', 'five']),
  _NumEntry(9, 'nine', 'số 9', ['ten', 'eight', 'five']),
  _NumEntry(10, 'ten', 'số 10', ['two', 'nine', 'seven']),
];

EnglishQuestion _numberQuestion(_NumEntry e, Random r) {
  final (choices, idx) = _shuffledChoices(e.word, e.confusables, r);
  return EnglishQuestion(
    id: 'en-num-${e.value}',
    displayKind: EnglishDisplayKind.countPick,
    prompt: 'Đếm số chấm và chọn từ tiếng Anh đúng nhé!',
    englishSpeech: e.word,
    vietnameseMeaning: e.vn,
    choices: choices,
    correctIndex: idx,
    countValue: e.value,
  );
}

// --- Level 4: Colors --------------------------------------------------------

class _ColorEntry {
  const _ColorEntry(this.word, this.vn, this.color, this.confusables);
  final String word;
  final String vn;
  final Color color;
  final List<String> confusables;
}

const _colors = <_ColorEntry>[
  _ColorEntry('red', 'màu đỏ', EnglishSwatchColors.red, ['blue', 'pink', 'orange']),
  _ColorEntry('blue', 'màu xanh dương', EnglishSwatchColors.blue, ['green', 'purple', 'red']),
  _ColorEntry('yellow', 'màu vàng', EnglishSwatchColors.yellow, ['orange', 'green', 'white']),
  _ColorEntry('green', 'màu xanh lá', EnglishSwatchColors.green, ['blue', 'yellow', 'brown']),
  _ColorEntry('orange', 'màu cam', EnglishSwatchColors.orange, ['red', 'yellow', 'brown']),
  _ColorEntry('purple', 'màu tím', EnglishSwatchColors.purple, ['pink', 'blue', 'red']),
  _ColorEntry('pink', 'màu hồng', EnglishSwatchColors.pink, ['red', 'purple', 'white']),
  _ColorEntry('black', 'màu đen', EnglishSwatchColors.black, ['white', 'brown', 'blue']),
  _ColorEntry('white', 'màu trắng', EnglishSwatchColors.white, ['black', 'yellow', 'pink']),
  _ColorEntry('brown', 'màu nâu', EnglishSwatchColors.brown, ['black', 'orange', 'red']),
];

EnglishQuestion _colorQuestion(_ColorEntry e, Random r) {
  final (choices, idx) = _shuffledChoices(e.word, e.confusables, r);
  return EnglishQuestion(
    id: 'en-color-${e.word}',
    displayKind: EnglishDisplayKind.colorPick,
    prompt: 'Nhìn màu, nghe Chíp đọc và chọn từ đúng nhé!',
    englishSpeech: e.word,
    vietnameseMeaning: e.vn,
    choices: choices,
    correctIndex: idx,
    swatchColor: e.color,
  );
}

// --- Levels 5, 6, 8: Animals, Food & Fruit, Family & Body -------------------

class _Vocab {
  const _Vocab(this.word, this.vn, this.confusables);
  final String word;
  final String vn;
  final List<String> confusables;
}

const _animals = <_Vocab>[
  _Vocab('cat', 'con mèo', ['dog', 'bird', 'fish']),
  _Vocab('dog', 'con chó', ['cat', 'duck', 'pig']),
  _Vocab('bird', 'con chim', ['bear', 'duck', 'fish']),
  _Vocab('fish', 'con cá', ['frog', 'bird', 'duck']),
  _Vocab('duck', 'con vịt', ['dog', 'bird', 'cow']),
  _Vocab('pig', 'con lợn', ['dog', 'cow', 'frog']),
  _Vocab('cow', 'con bò', ['cat', 'pig', 'bear']),
  _Vocab('lion', 'sư tử', ['bear', 'dog', 'cat']),
  _Vocab('frog', 'con ếch', ['fish', 'duck', 'pig']),
  _Vocab('bear', 'con gấu', ['bird', 'lion', 'cow']),
];

const _foodFruit = <_Vocab>[
  _Vocab('apple', 'quả táo', ['mango', 'grape', 'orange']),
  _Vocab('banana', 'quả chuối', ['apple', 'mango', 'bread']),
  _Vocab('orange', 'quả cam', ['apple', 'grape', 'cake']),
  _Vocab('grape', 'quả nho', ['apple', 'mango', 'bread']),
  _Vocab('cake', 'bánh ngọt', ['milk', 'bread', 'egg']),
  _Vocab('milk', 'sữa', ['cake', 'rice', 'egg']),
  _Vocab('bread', 'bánh mì', ['cake', 'rice', 'milk']),
  _Vocab('egg', 'quả trứng', ['milk', 'cake', 'rice']),
  _Vocab('rice', 'cơm', ['milk', 'bread', 'egg']),
  _Vocab('mango', 'quả xoài', ['apple', 'banana', 'grape']),
];

const _familyBody = <_Vocab>[
  _Vocab('mom', 'mẹ', ['dad', 'baby', 'sister']),
  _Vocab('dad', 'bố', ['mom', 'baby', 'brother']),
  _Vocab('baby', 'em bé', ['mom', 'dad', 'sister']),
  _Vocab('sister', 'chị / em gái', ['brother', 'mom', 'baby']),
  _Vocab('brother', 'anh / em trai', ['sister', 'dad', 'baby']),
  _Vocab('eye', 'mắt', ['ear', 'nose', 'hand']),
  _Vocab('nose', 'mũi', ['eye', 'ear', 'foot']),
  _Vocab('ear', 'tai', ['eye', 'nose', 'hand']),
  _Vocab('hand', 'bàn tay', ['foot', 'eye', 'ear']),
  _Vocab('foot', 'bàn chân', ['hand', 'nose', 'ear']),
];

EnglishQuestion _vocabQuestion(_Vocab e, Random r) {
  final (choices, idx) = _shuffledChoices(e.word, e.confusables, r);
  return EnglishQuestion(
    id: 'en-vocab-${e.word}',
    displayKind: EnglishDisplayKind.listenPick,
    prompt: 'Nghe tiếng Anh và chọn đúng từ nhé!',
    englishSpeech: e.word,
    vietnameseMeaning: e.vn,
    choices: choices,
    correctIndex: idx,
  );
}

// --- Level 7: Initial Phonics -----------------------------------------------

class _PhonicsEntry {
  const _PhonicsEntry(this.initial, this.tail, this.vn, this.confusables);
  final String initial;
  final String tail;
  final String vn;
  final List<String> confusables;

  String get word => '$initial$tail';
}

const _phonics = <_PhonicsEntry>[
  _PhonicsEntry('a', 'pple', 'quả táo', ['e', 'o', 'u']),
  _PhonicsEntry('b', 'all', 'quả bóng', ['d', 'p', 't']),
  _PhonicsEntry('c', 'at', 'con mèo', ['b', 's', 'h']),
  _PhonicsEntry('d', 'og', 'con chó', ['b', 'f', 'p']),
  _PhonicsEntry('f', 'ish', 'con cá', ['d', 's', 'h']),
  _PhonicsEntry('h', 'at', 'cái mũ', ['c', 'm', 'b']),
  _PhonicsEntry('m', 'oon', 'mặt trăng', ['n', 's', 'b']),
  _PhonicsEntry('p', 'ig', 'con lợn', ['b', 'd', 't']),
  _PhonicsEntry('s', 'un', 'mặt trời', ['c', 'm', 't']),
  _PhonicsEntry('t', 'ree', 'cái cây', ['d', 'p', 'f']),
];

EnglishQuestion _phonicsQuestion(_PhonicsEntry e, Random r) {
  final (choices, idx) = _shuffledChoices(e.initial, e.confusables, r);
  return EnglishQuestion(
    id: 'en-phonics-${e.word}',
    displayKind: EnglishDisplayKind.phonicsBuild,
    prompt: 'Nghe và chọn chữ cái đầu tiên nhé!',
    englishSpeech: e.word,
    vietnameseMeaning: e.vn,
    choices: choices,
    correctIndex: idx,
    phonicsTail: e.tail,
  );
}

// --- Level 9: Short Greetings & Phrases -------------------------------------

class _EnPhrase {
  const _EnPhrase(
    this.before,
    this.missing,
    this.after,
    this.vn,
    this.confusables,
  );
  final String before;
  final String missing;
  final String after;
  final String vn;
  final List<String> confusables;

  String get full => [
        if (before.isNotEmpty) before,
        missing,
        if (after.isNotEmpty) after,
      ].join(' ');
}

const _greetings = <_EnPhrase>[
  _EnPhrase('Good', 'morning', '!', 'Chào buổi sáng!', ['cat', 'red', 'milk']),
  _EnPhrase('Thank', 'you', '!', 'Cảm ơn!', ['dog', 'sun', 'one']),
  _EnPhrase('See', 'you', '!', 'Hẹn gặp lại!', ['pig', 'blue', 'egg']),
  _EnPhrase('I love', 'mom', '!', 'Con yêu mẹ!', ['red', 'ten', 'hat']),
  _EnPhrase('It is a', 'cat', '.', 'Đây là con mèo.', ['red', 'good', 'see']),
  _EnPhrase('Good', 'night', '!', 'Chúc ngủ ngon!', ['fish', 'cake', 'two']),
  _EnPhrase('Hello,', 'friend', '!', 'Xin chào bạn!', ['apple', 'blue', 'six']),
  _EnPhrase('I like', 'milk', '.', 'Con thích sữa.', ['good', 'hello', 'you']),
];

EnglishQuestion _phraseQuestion(_EnPhrase e, Random r) {
  final (choices, idx) = _shuffledChoices(e.missing, e.confusables, r);
  return EnglishQuestion(
    id: 'en-phrase-${e.full}',
    displayKind: EnglishDisplayKind.phraseFill,
    prompt: 'Nghe câu tiếng Anh và chọn từ điền vào chỗ trống nhé!',
    englishSpeech: e.full,
    vietnameseMeaning: e.vn,
    choices: choices,
    correctIndex: idx,
    phraseBefore: e.before,
    phraseAfter: e.after,
  );
}
