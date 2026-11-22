/// Glyph ids in the order children learn to write them.
const List<String> writingLadder = [
  'net-ngang',
  'net-thang-dung',
  'net-xien',
  'net-cong',
  'net-moc',
  'so-0',
  'so-1',
  'so-2',
  'so-3',
  'so-4',
  'so-5',
  'so-6',
  'so-7',
  'so-8',
  'so-9',
  // Lowercase letters, easiest shapes first (see the 2A design).
  'chu-i', 'chu-t', 'chu-u', 'chu-uw', 'chu-n', 'chu-m', 'chu-v', 'chu-r',
  'chu-s', 'chu-o', 'chu-oo', 'chu-ow', 'chu-c', 'chu-x', 'chu-e', 'chu-ee',
  'chu-a', 'chu-aw', 'chu-aa', 'chu-d', 'chu-dd', 'chu-q', 'chu-l', 'chu-b',
  'chu-h', 'chu-k', 'chu-g', 'chu-y', 'chu-p',
  // Tone marks, written beside an "a" for context.
  'dau-huyen', 'dau-sac', 'dau-nang', 'dau-hoi', 'dau-nga',
  // Capitals (2G): round and straight shapes first, diacritic variants
  // right after their base letter (tools/glyphs/capitals.py ORDER).
  'hoa-o', 'hoa-oo', 'hoa-ow', 'hoa-c', 'hoa-i', 'hoa-l', 'hoa-t', 'hoa-h',
  'hoa-u', 'hoa-uw', 'hoa-v', 'hoa-x', 'hoa-n', 'hoa-m', 'hoa-a', 'hoa-aw',
  'hoa-aa', 'hoa-e', 'hoa-ee', 'hoa-s', 'hoa-p', 'hoa-r', 'hoa-b', 'hoa-d',
  'hoa-dd', 'hoa-k', 'hoa-q', 'hoa-g', 'hoa-y',
];
