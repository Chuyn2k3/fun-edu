import '../ui/assets.dart';
import '../ui/theme/tokens.dart';
import 'explore_island.dart';
import 'geography_level.dart';

// All copy below must be approved by the project owner before the island is
// marked ready (docs/superpowers/specs/assets/sinh-hoc-noi-dung.md).
// Lines never name the answer, never mention hunting, eating meat or death.

GeoItem _bio(String id, String name, String fact, String clue,
        {String? speech}) =>
    GeoItem(
      id: id,
      name: name,
      speech: speech ?? name,
      fact: fact,
      clue: clue,
      prefix: 'bio',
    );

// Pictures used by more than one level (one file each).
final _meo = _bio('meo', 'Mèo', 'Kêu meo meo, thích nằm sưởi nắng.',
    'Con vật hay rửa mặt bằng chân.');
final _khi = _bio('khi', 'Khỉ', 'Leo trèo thật giỏi, thích đu cành cây.',
    'Con vật leo cây giỏi nhất rừng.');
final _ong = _bio('ong', 'Ong', 'Bay vo ve, làm ra mật thật ngọt.',
    'Con vật bay vo ve, làm ra mật.');
final _buom = _bio('buom', 'Bướm', 'Có đôi cánh nhiều màu sặc sỡ.',
    'Con vật có đôi cánh nhiều màu.');
final _hoa = _bio('hoa', 'Hoa', 'Nở thật đẹp, có mùi thơm, ong bướm rất thích.',
    'Phần đẹp nhất của cây, có mùi thơm.');
final _hat = _bio('hat', 'Hạt', 'Gieo xuống đất, tưới nước là nảy mầm.',
    'Nhỏ xíu, gieo xuống đất sẽ mọc cây.');
final _caRot = _bio('ca-rot', 'Cà rốt', 'Củ màu cam, ăn giòn ngọt, tốt cho mắt.',
    'Củ màu cam, thỏ rất thích gặm.');
final _bo = _bio('bo', 'Bò', 'Kêu ò ò, cho chúng ta sữa thơm.',
    'Con vật cho chúng ta sữa.');

final List<GeographyLevel> biologyLevels = [
  GeographyLevel(
    id: 'vat-nuoi',
    title: 'Con vật trong nhà',
    subtitle: 'Chó, mèo, gà, vịt…',
    clues: false,
    items: [
      _bio('cho', 'Chó', 'Biết giữ nhà, vẫy đuôi mừng khi em về.',
          'Con vật biết giữ nhà.'),
      _meo,
      _bio('ga', 'Gà', 'Gáy ò ó o mỗi sáng gọi mọi người dậy.',
          'Con vật gáy mỗi sáng.'),
      _bio('vit', 'Vịt', 'Bơi giỏi dưới ao, kêu cạp cạp.',
          'Con vật bơi dưới ao, kêu cạp cạp.'),
      _bio('lon', 'Lợn', 'Kêu ụt ịt, thích ăn no rồi ngủ.',
          'Con vật kêu ụt ịt.'),
      _bio('trau', 'Trâu', 'Giúp bác nông dân cày ruộng.',
          'Con vật có sừng cong, giúp cày ruộng.'),
    ],
  ),
  GeographyLevel(
    id: 'trong-rung',
    title: 'Con vật trong rừng',
    subtitle: 'Voi, hổ, khỉ, gấu…',
    clues: false,
    items: [
      _bio('voi', 'Voi', 'Có cái vòi thật dài và đôi tai to.',
          'Con vật to lớn có vòi dài.'),
      _bio('ho', 'Hổ', 'Lông vàng có sọc đen, là chúa sơn lâm.',
          'Con vật lông vàng sọc đen.'),
      _khi,
      _bio('gau', 'Gấu', 'Lông dày, rất thích mật ong.',
          'Con vật lông dày, thích mật ong.'),
      _bio('huou-cao-co', 'Hươu cao cổ', 'Cổ thật dài, ăn lá trên ngọn cây.',
          'Con vật cổ dài nhất rừng.'),
    ],
  ),
  GeographyLevel(
    id: 'duoi-nuoc',
    title: 'Dưới nước',
    subtitle: 'Cá, cua, tôm, cá heo…',
    clues: false,
    items: [
      _bio('ca', 'Cá', 'Bơi bằng vây và đuôi, thở dưới nước.',
          'Con vật bơi bằng vây.'),
      _bio('cua', 'Cua', 'Có hai cái càng, bò ngang trên cát.',
          'Con vật bò ngang, có hai càng.'),
      _bio('tom', 'Tôm', 'Có râu dài, bơi lùi rất nhanh.',
          'Con vật có râu dài, bơi lùi.'),
      _bio('ca-heo', 'Cá heo', 'Rất thông minh, thích nhảy lên khỏi mặt nước.',
          'Con vật thông minh, thích nhảy khỏi mặt nước.'),
      _bio('rua-bien', 'Rùa biển', 'Mang mai cứng, bơi chậm rãi khắp đại dương.',
          'Con vật mang mai, bơi ngoài khơi.'),
    ],
  ),
  GeographyLevel(
    id: 'bau-troi',
    title: 'Trên bầu trời',
    subtitle: 'Chim sẻ, bướm, ong…',
    clues: true,
    items: [
      _bio('chim-se', 'Chim sẻ', 'Nhỏ xíu, nhảy lách chách trên cành cây.',
          'Con chim nhỏ hay nhảy trên cành.'),
      _buom,
      _ong,
      _bio('chuon-chuon', 'Chuồn chuồn', 'Có bốn cánh mỏng, bay thấp là trời mưa.',
          'Con vật có bốn cánh mỏng trong suốt.'),
      _bio('co', 'Cò', 'Chân dài, đứng trên đồng lúa tìm mồi.',
          'Con chim chân dài, lông trắng muốt.'),
    ],
  ),
  GeographyLevel(
    id: 'an-gi',
    title: 'Con gì ăn gì?',
    subtitle: 'Thỏ, khỉ, mèo, bò, ong',
    clues: false,
    items: const [],
    pairs: [
      PairItem(
        id: 'tho',
        ask: _bio('tho', 'Thỏ', 'Tai dài, nhảy thật nhanh.',
            'Con vật tai dài.'),
        answer: _caRot,
        question: 'Thỏ thích ăn gì?',
        fact: 'Thỏ gặm thật giòn bằng hai chiếc răng cửa.',
        // Rabbits eat grass too.
        alsoRight: const ['bo-co'],
      ),
      PairItem(
        id: 'khi',
        ask: _khi,
        answer: _bio('chuoi', 'Chuối', 'Quả dài, vỏ vàng.', 'Quả dài vỏ vàng.'),
        question: 'Khỉ thích ăn gì?',
        fact: 'Khỉ bóc lớp vỏ vàng rồi mới ăn.',
      ),
      PairItem(
        id: 'meo',
        ask: _meo,
        answer: _bio('dia-ca', 'Đĩa cá', 'Cá nấu chín trong đĩa.',
            'Món cá nấu chín.'),
        question: 'Mèo thích ăn gì?',
        fact: 'Mèo rất thích món này, ăn xong lại rửa mặt.',
      ),
      PairItem(
        id: 'bo',
        ask: _bo,
        answer: _bio('bo-co', 'Bó cỏ', 'Cỏ xanh buộc thành bó.',
            'Cỏ xanh buộc lại.'),
        question: 'Bò thích ăn gì?',
        fact: 'Bò nhai thật lâu, nhai cả ngày trên cánh đồng.',
        // Cows eat carrots too.
        alsoRight: const ['ca-rot'],
      ),
      PairItem(
        id: 'ong',
        ask: _ong,
        answer: _hoa,
        question: 'Ong bay đến đâu để lấy mật?',
        fact: 'Ong hút mật ngọt rồi bay về tổ.',
      ),
    ],
  ),
  GeographyLevel(
    id: 'lon-len',
    title: 'Lớn lên thế nào?',
    subtitle: 'Trứng, nòng nọc, sâu, hạt…',
    clues: false,
    items: const [],
    pairs: [
      PairItem(
        id: 'trung',
        ask: _bio('trung', 'Quả trứng', 'Tròn tròn, vỏ mỏng.', 'Tròn, vỏ mỏng.'),
        answer: _bio('ga-con', 'Gà con', 'Lông vàng, kêu chiếp chiếp.',
            'Lông vàng, kêu chiếp chiếp.'),
        question: 'Quả trứng nở ra con gì?',
        fact: 'Mẹ gà ấp trứng, ít hôm sau con non chui ra.',
      ),
      PairItem(
        id: 'nong-noc',
        ask: _bio('nong-noc', 'Nòng nọc', 'Có đuôi, bơi dưới ao.',
            'Có đuôi, bơi dưới ao.'),
        answer: _bio('ech', 'Ếch', 'Nhảy giỏi, kêu ộp ộp.', 'Kêu ộp ộp.'),
        question: 'Nòng nọc lớn lên thành con gì?',
        fact: 'Mọc chân, rụng đuôi, rồi nhảy lên bờ.',
      ),
      PairItem(
        id: 'sau',
        ask: _bio('sau', 'Sâu', 'Bò chậm trên lá.', 'Bò chậm trên lá.'),
        answer: _buom,
        question: 'Sâu lớn lên thành con gì?',
        fact: 'Sâu ngủ trong kén, tỉnh dậy có đôi cánh đẹp.',
      ),
      PairItem(
        id: 'hat',
        ask: _hat,
        answer: _bio('cay-mam', 'Cây mầm', 'Hai chiếc lá non nhỏ xíu.',
            'Hai lá non nhỏ xíu.'),
        question: 'Hạt mọc lên thành gì?',
        fact: 'Tưới nước mỗi ngày, hạt nhú lên hai lá non.',
      ),
      PairItem(
        id: 'be-con',
        ask: _bio('be-con', 'Bê con', 'Con non của bò.', 'Con non của bò.'),
        answer: _bo,
        question: 'Bê con lớn lên thành con gì?',
        fact: 'Bê con uống sữa mẹ, lớn dần thật khỏe.',
      ),
    ],
  ),
  GeographyLevel(
    id: 'cay-hoa',
    title: 'Cây và hoa',
    subtitle: 'Rễ, lá, hoa, quả, hạt',
    clues: true,
    items: [
      _bio('re-cay', 'Rễ cây', 'Nằm dưới đất, hút nước nuôi cả cái cây.',
          'Phần của cây nằm dưới đất.'),
      _bio('la-cay', 'Lá cây', 'Màu xanh, đón nắng giúp cây khỏe mạnh.',
          'Phần màu xanh, đón ánh nắng.'),
      _hoa,
      _bio('qua', 'Quả', 'Lớn lên từ bông hoa, bên trong có hạt.',
          'Phần ăn được, mọc ra sau khi hoa tàn.'),
      _hat,
    ],
  ),
  GeographyLevel(
    id: 'rau-qua',
    title: 'Rau củ quả',
    subtitle: 'Cà rốt, bắp cải, xoài…',
    clues: true,
    items: [
      _caRot,
      _bio('bap-cai', 'Bắp cải', 'Nhiều lá cuộn tròn, nấu canh rất ngon.',
          'Rau có nhiều lá cuộn tròn.'),
      _bio('ca-chua', 'Cà chua', 'Đỏ mọng, nấu canh chua thật ngon.',
          'Quả đỏ mọng, dùng nấu canh.'),
      _bio('xoai', 'Xoài', 'Chín vàng, thơm và ngọt lịm.',
          'Quả chín vàng, thơm ngọt.'),
      _bio('dua-hau', 'Dưa hấu', 'Vỏ xanh, ruột đỏ, ăn mát lạnh ngày hè.',
          'Quả vỏ xanh, ruột đỏ.'),
      _bio('bi-ngo', 'Bí ngô', 'To tròn màu cam, nấu canh rất bổ.',
          'Quả to tròn màu cam.'),
    ],
  ),
  GeographyLevel(
    id: 'co-the',
    title: 'Cơ thể em làm gì?',
    subtitle: 'Mắt, tai, mũi, miệng…',
    clues: true,
    items: [
      _bio('mat', 'Mắt', 'Giúp em nhìn thấy mọi thứ xung quanh.',
          'Bộ phận giúp em nhìn.'),
      _bio('tai', 'Tai', 'Giúp em nghe tiếng chim hót, tiếng mẹ gọi.',
          'Bộ phận giúp em nghe tiếng chim hót.'),
      _bio('mui', 'Mũi', 'Giúp em ngửi thấy mùi hoa thơm.',
          'Bộ phận giúp em ngửi mùi thơm.'),
      _bio('mieng', 'Miệng', 'Giúp em ăn cơm và nói chuyện.',
          'Bộ phận giúp em ăn và nói.'),
      _bio('tay', 'Bàn tay', 'Giúp em cầm bút, vẽ tranh, vỗ tay.',
          'Bộ phận giúp em cầm bút.'),
      _bio('chan', 'Bàn chân', 'Giúp em đi, chạy và nhảy thật xa.',
          'Bộ phận giúp em đi và chạy.'),
    ],
  ),
];

/// Not open to kids until its copy is approved and its real pictures are
/// in: then set [ExploreIsland.ready] to true.
final biologyIsland = ExploreIsland(
  id: 'sinh-hoc',
  prefix: 'bio',
  name: 'Sinh học',
  mapTitle: 'Khám phá sự sống',
  subject: Subject.sinhHoc,
  islandImage: AppImages.islandSinhHoc,
  levels: biologyLevels,
  ready: false,
);
