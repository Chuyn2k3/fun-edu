import '../ui/assets.dart';

/// One thing the kid learns to recognise on the geography island.
class GeoItem {
  const GeoItem({
    required this.id,
    required this.name,
    required this.speech,
    required this.fact,
    required this.clue,
  });

  final String id;

  /// Name shown on screen.
  final String name;

  /// How the `vi-VN` voice should say [name] (foreign names spelled out).
  final String speech;

  /// Short line Chíp reads after a right answer. Never repeats [name].
  final String fact;

  /// Riddle for "listen then pick" questions. Never repeats [name].
  final String clue;

  String get image => AppImages.geography[id]!;
}

/// One rung of the 9-level geography ladder.
class GeographyLevel {
  const GeographyLevel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.clues,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<GeoItem> items;

  /// Whether this level mixes in "listen to the clue" questions.
  final bool clues;
}

// All copy below must be approved by the project owner before the island is
// switched on (docs/superpowers/specs/assets/dia-ly-noi-dung.md).
const List<GeographyLevel> geographyLevels = [
  GeographyLevel(
    id: 'canh-vat',
    title: 'Cảnh vật quanh em',
    subtitle: 'Núi, sông, biển, rừng…',
    clues: false,
    items: [
      GeoItem(
        id: 'nui',
        name: 'Núi',
        speech: 'Núi',
        fact: 'Cao thật cao, đỉnh chạm tới những đám mây.',
        clue: 'Nơi này cao thật cao, leo mãi mới tới đỉnh.',
      ),
      GeoItem(
        id: 'song',
        name: 'Sông',
        speech: 'Sông',
        fact: 'Nước chảy dài, có thuyền đi lại trên mặt nước.',
        clue: 'Dòng nước dài chảy mãi, có thuyền đi trên đó.',
      ),
      GeoItem(
        id: 'bien',
        name: 'Biển',
        speech: 'Biển',
        fact: 'Nước mặn mênh mông, có sóng vỗ và bãi cát vàng.',
        clue: 'Nước mặn mênh mông, có sóng vỗ rì rào.',
      ),
      GeoItem(
        id: 'rung',
        name: 'Rừng',
        speech: 'Rừng',
        fact: 'Thật nhiều cây xanh, là nhà của chim và thú.',
        clue: 'Nơi có thật nhiều cây, chim và thú sống ở đây.',
      ),
      GeoItem(
        id: 'dong-lua',
        name: 'Đồng lúa',
        speech: 'Đồng lúa',
        fact: 'Bác nông dân trồng lúa ở đây để có gạo nấu cơm.',
        clue: 'Cánh đồng xanh mướt, có hạt gạo để nấu cơm.',
      ),
      GeoItem(
        id: 'hang-dong',
        name: 'Hang động',
        speech: 'Hang động',
        fact: 'Bên trong núi tối và mát, có đá lấp lánh.',
        clue: 'Đi vào bên trong núi, tối và mát rượi.',
      ),
    ],
  ),
  GeographyLevel(
    id: 'thoi-tiet',
    title: 'Thời tiết',
    subtitle: 'Nắng, mưa, gió, cầu vồng…',
    clues: false,
    items: [
      GeoItem(
        id: 'nang',
        name: 'Nắng',
        speech: 'Nắng',
        fact: 'Ông mặt trời chiếu sáng, trời ấm áp và rực rỡ.',
        clue: 'Ông mặt trời chiếu sáng, trời thật ấm áp.',
      ),
      GeoItem(
        id: 'mua',
        name: 'Mưa',
        speech: 'Mưa',
        fact: 'Những giọt nước rơi tí tách, nhớ mang ô khi ra ngoài nhé.',
        clue: 'Những giọt nước rơi tí tách từ trên trời.',
      ),
      GeoItem(
        id: 'gio',
        name: 'Gió',
        speech: 'Gió',
        fact: 'Thổi vù vù làm lá cây rung rinh và diều bay cao.',
        clue: 'Thổi vù vù, làm diều bay thật cao.',
      ),
      GeoItem(
        id: 'may',
        name: 'Mây',
        speech: 'Mây',
        fact: 'Trắng bồng bềnh như bông, trôi chầm chậm trên trời.',
        clue: 'Trắng bồng bềnh như bông, trôi trên bầu trời.',
      ),
      GeoItem(
        id: 'cau-vong',
        name: 'Cầu vồng',
        speech: 'Cầu vồng',
        fact: 'Hiện ra sau cơn mưa với thật nhiều màu sắc.',
        clue: 'Sau cơn mưa, trên trời hiện ra thật nhiều màu.',
      ),
      GeoItem(
        id: 'sam-set',
        name: 'Sấm sét',
        speech: 'Sấm sét',
        fact: 'Trời lóe sáng rồi đùng đoàng, bé ở trong nhà nhé.',
        clue: 'Trời lóe sáng rồi kêu đùng đoàng.',
      ),
    ],
  ),
  GeographyLevel(
    id: 'viet-nam',
    title: 'Đất nước em',
    subtitle: 'Lá cờ, nón lá, áo dài…',
    clues: false,
    items: [
      GeoItem(
        id: 'co-viet-nam',
        name: 'Lá cờ Việt Nam',
        speech: 'Lá cờ Việt Nam',
        fact: 'Nền đỏ, ở giữa có ngôi sao vàng năm cánh.',
        clue: 'Nền đỏ, ở giữa có ngôi sao vàng.',
      ),
      GeoItem(
        id: 'ban-do-chu-s',
        name: 'Bản đồ Việt Nam',
        speech: 'Bản đồ Việt Nam',
        fact: 'Đất nước mình cong cong hình chữ S bên bờ biển.',
        clue: 'Đất nước mình cong cong như chữ S.',
      ),
      GeoItem(
        id: 'non-la',
        name: 'Nón lá',
        speech: 'Nón lá',
        fact: 'Làm bằng lá, đội lên đầu để che nắng che mưa.',
        clue: 'Đội lên đầu để che nắng, làm bằng lá.',
      ),
      GeoItem(
        id: 'ao-dai',
        name: 'Áo dài',
        speech: 'Áo dài',
        fact: 'Chiếc áo thướt tha, mẹ và cô hay mặc ngày Tết.',
        clue: 'Chiếc áo thướt tha, mẹ hay mặc ngày Tết.',
      ),
      GeoItem(
        id: 'hoa-sen',
        name: 'Hoa sen',
        speech: 'Hoa sen',
        fact: 'Bông hoa hồng thơm ngát, mọc lên từ trong ao.',
        clue: 'Bông hoa thơm ngát mọc lên giữa ao.',
      ),
    ],
  ),
  GeographyLevel(
    id: 'mien-bac',
    title: 'Miền Bắc',
    subtitle: 'Hồ Gươm, Vịnh Hạ Long…',
    clues: true,
    items: [
      GeoItem(
        id: 'ho-guom',
        name: 'Hồ Gươm',
        speech: 'Hồ Gươm',
        fact: 'Hồ nước ở Hà Nội, giữa hồ có Tháp Rùa.',
        clue: 'Hồ nước ở Hà Nội, giữa hồ có một ngọn tháp nhỏ.',
      ),
      GeoItem(
        id: 'vinh-ha-long',
        name: 'Vịnh Hạ Long',
        speech: 'Vịnh Hạ Long',
        fact: 'Thật nhiều đảo đá nhô lên giữa biển xanh.',
        clue: 'Nơi này có thật nhiều đảo đá giữa biển xanh.',
      ),
      GeoItem(
        id: 'van-mieu',
        name: 'Văn Miếu',
        speech: 'Văn Miếu',
        fact: 'Trường học rất xưa ở Hà Nội, có giếng nước vuông.',
        clue: 'Trường học rất xưa ở Hà Nội, có cổng cao.',
      ),
      GeoItem(
        id: 'chua-mot-cot',
        name: 'Chùa Một Cột',
        speech: 'Chùa Một Cột',
        fact: 'Ngôi chùa nhỏ đứng trên một cây cột giữa ao sen.',
        clue: 'Ngôi chùa nhỏ đứng trên chỉ một cây cột.',
      ),
      GeoItem(
        id: 'ruong-bac-thang',
        name: 'Ruộng bậc thang',
        speech: 'Ruộng bậc thang',
        fact: 'Ruộng lúa xếp từng bậc như cầu thang trên núi.',
        clue: 'Ruộng lúa xếp từng bậc trên sườn núi.',
      ),
    ],
  ),
  GeographyLevel(
    id: 'mien-trung',
    title: 'Miền Trung',
    subtitle: 'Cố đô Huế, Hội An…',
    clues: true,
    items: [
      GeoItem(
        id: 'co-do-hue',
        name: 'Cố đô Huế',
        speech: 'Cố đô Huế',
        fact: 'Cung điện xưa có cổng lớn, nằm bên sông Hương.',
        clue: 'Cung điện xưa có cổng lớn, bên dòng sông Hương.',
      ),
      GeoItem(
        id: 'chua-cau',
        name: 'Chùa Cầu Hội An',
        speech: 'Chùa Cầu Hội An',
        fact: 'Cây cầu nhỏ có mái che ở phố cổ đèn lồng.',
        clue: 'Cây cầu nhỏ có mái, ở phố cổ treo đèn lồng.',
      ),
      GeoItem(
        id: 'cau-rong',
        name: 'Cầu Rồng',
        speech: 'Cầu Rồng',
        fact: 'Cây cầu ở Đà Nẵng uốn lượn như một con rồng.',
        clue: 'Cây cầu ở Đà Nẵng uốn lượn như con rồng.',
      ),
      GeoItem(
        id: 'dong-phong-nha',
        name: 'Động Phong Nha',
        speech: 'Động Phong Nha',
        fact: 'Hang động rất đẹp, đi thuyền vào bên trong núi.',
        clue: 'Đi thuyền vào trong lòng núi, thấy đá lấp lánh.',
      ),
      GeoItem(
        id: 'cau-vang',
        name: 'Cầu Vàng',
        speech: 'Cầu Vàng',
        fact: 'Cây cầu màu vàng được hai bàn tay đá nâng lên.',
        clue: 'Cây cầu được hai bàn tay khổng lồ nâng lên.',
      ),
    ],
  ),
  GeographyLevel(
    id: 'mien-nam',
    title: 'Miền Nam',
    subtitle: 'Chợ Bến Thành, chợ nổi…',
    clues: true,
    items: [
      GeoItem(
        id: 'cho-ben-thanh',
        name: 'Chợ Bến Thành',
        speech: 'Chợ Bến Thành',
        fact: 'Khu chợ lớn ở Sài Gòn, có tháp đồng hồ.',
        clue: 'Khu chợ lớn ở Sài Gòn, cổng có đồng hồ.',
      ),
      GeoItem(
        id: 'cho-noi-cai-rang',
        name: 'Chợ nổi Cái Răng',
        speech: 'Chợ nổi Cái Răng',
        fact: 'Chợ họp ngay trên sông, thuyền nào cũng đầy trái cây.',
        clue: 'Mọi người mua bán trái cây ngay trên thuyền.',
      ),
      GeoItem(
        id: 'nha-tho-duc-ba',
        name: 'Nhà thờ Đức Bà',
        speech: 'Nhà thờ Đức Bà',
        fact: 'Tòa nhà gạch đỏ có hai tháp cao ở Sài Gòn.',
        clue: 'Tòa nhà gạch đỏ ở Sài Gòn, có hai tháp cao.',
      ),
      GeoItem(
        id: 'buu-dien-sai-gon',
        name: 'Bưu điện Sài Gòn',
        speech: 'Bưu điện Sài Gòn',
        fact: 'Nơi gửi thư và bưu thiếp, mái vòm thật đẹp.',
        clue: 'Nơi mọi người đến gửi thư và bưu thiếp.',
      ),
      GeoItem(
        id: 'mui-ca-mau',
        name: 'Mũi Cà Mau',
        speech: 'Mũi Cà Mau',
        fact: 'Mảnh đất ở tận cùng phía nam của đất nước.',
        clue: 'Mảnh đất xa nhất ở phía nam, có rừng đước.',
      ),
    ],
  ),
  GeographyLevel(
    id: 'chau-a',
    title: 'Châu Á',
    subtitle: 'Vạn Lý Trường Thành, Phú Sĩ…',
    clues: true,
    items: [
      GeoItem(
        id: 'van-ly-truong-thanh',
        name: 'Vạn Lý Trường Thành',
        speech: 'Vạn Lý Trường Thành',
        fact: 'Bức tường đá rất dài uốn quanh núi ở Trung Quốc.',
        clue: 'Bức tường đá rất dài uốn lượn trên núi.',
      ),
      GeoItem(
        id: 'nui-phu-si',
        name: 'Núi Phú Sĩ',
        speech: 'Núi Phú Sĩ',
        fact: 'Ngọn núi đỉnh phủ tuyết trắng ở Nhật Bản.',
        clue: 'Ngọn núi ở Nhật Bản, đỉnh phủ tuyết trắng.',
      ),
      GeoItem(
        id: 'taj-mahal',
        name: 'Đền Taj Mahal',
        speech: 'Đền Tát Ma-han',
        fact: 'Tòa nhà trắng tinh có mái tròn ở Ấn Độ.',
        clue: 'Tòa nhà trắng tinh ở Ấn Độ, mái tròn như củ hành.',
      ),
      GeoItem(
        id: 'angkor-wat',
        name: 'Angkor Wat',
        speech: 'Ăng-co Vát',
        fact: 'Đền đá cổ rất lớn ở Cam-pu-chia.',
        clue: 'Ngôi đền đá cổ rất lớn ở Cam-pu-chia.',
      ),
      GeoItem(
        id: 'thap-petronas',
        name: 'Tháp đôi Petronas',
        speech: 'Tháp đôi Pê-tơ-rô-nát',
        fact: 'Hai tòa tháp cao vút giống nhau ở Ma-lai-xi-a.',
        clue: 'Hai tòa tháp cao vút đứng cạnh nhau như anh em.',
      ),
    ],
  ),
  GeographyLevel(
    id: 'chau-au-phi',
    title: 'Châu Âu & châu Phi',
    subtitle: 'Tháp Eiffel, Kim tự tháp…',
    clues: true,
    items: [
      GeoItem(
        id: 'thap-eiffel',
        name: 'Tháp Eiffel',
        speech: 'Tháp Ép-phen',
        fact: 'Ngọn tháp sắt cao vút ở nước Pháp.',
        clue: 'Ngọn tháp bằng sắt cao vút ở nước Pháp.',
      ),
      GeoItem(
        id: 'kim-tu-thap',
        name: 'Kim tự tháp',
        speech: 'Kim tự tháp',
        fact: 'Khối đá hình tam giác khổng lồ giữa sa mạc Ai Cập.',
        clue: 'Khối đá hình tam giác khổng lồ giữa sa mạc.',
      ),
      GeoItem(
        id: 'thap-pisa',
        name: 'Tháp nghiêng Pisa',
        speech: 'Tháp nghiêng Pi-da',
        fact: 'Ngọn tháp nghiêng nghiêng mà không đổ, ở nước Ý.',
        clue: 'Ngọn tháp đứng nghiêng nghiêng mà không bị đổ.',
      ),
      GeoItem(
        id: 'big-ben',
        name: 'Tháp Big Ben',
        speech: 'Tháp Bích Ben',
        fact: 'Tháp đồng hồ lớn kêu boong boong ở nước Anh.',
        clue: 'Tháp đồng hồ lớn ở nước Anh, kêu boong boong.',
      ),
      GeoItem(
        id: 'dau-truong-la-ma',
        name: 'Đấu trường La Mã',
        speech: 'Đấu trường La Mã',
        fact: 'Sân đá tròn rất cổ, có nhiều vòm cửa, ở nước Ý.',
        clue: 'Sân đá tròn rất cổ, có thật nhiều vòm cửa.',
      ),
    ],
  ),
  GeographyLevel(
    id: 'chau-my-uc',
    title: 'Châu Mỹ & châu Úc',
    subtitle: 'Tượng Nữ thần Tự do, Sydney…',
    clues: true,
    items: [
      GeoItem(
        id: 'tuong-nu-than-tu-do',
        name: 'Tượng Nữ thần Tự do',
        speech: 'Tượng Nữ thần Tự do',
        fact: 'Bức tượng xanh giơ cao ngọn đuốc ở nước Mỹ.',
        clue: 'Bức tượng màu xanh giơ cao ngọn đuốc.',
      ),
      GeoItem(
        id: 'nha-hat-opera-sydney',
        name: 'Nhà hát Opera Sydney',
        speech: 'Nhà hát Ô-pê-ra Xít-ni',
        fact: 'Mái nhà trắng như những cánh buồm, ở nước Úc.',
        clue: 'Mái nhà trắng như những cánh buồm bên bờ biển.',
      ),
      GeoItem(
        id: 'machu-picchu',
        name: 'Machu Picchu',
        speech: 'Ma-chu Pích-chu',
        fact: 'Thành phố đá cổ trên đỉnh núi cao ở Pê-ru.',
        clue: 'Thành phố đá cổ nằm trên đỉnh núi cao.',
      ),
      GeoItem(
        id: 'tuong-chua-cuu-the',
        name: 'Tượng Chúa Cứu Thế',
        speech: 'Tượng Chúa Cứu Thế',
        fact: 'Bức tượng dang rộng hai tay trên núi ở Bra-xin.',
        clue: 'Bức tượng dang rộng hai tay trên đỉnh núi.',
      ),
      GeoItem(
        id: 'thac-niagara',
        name: 'Thác Niagara',
        speech: 'Thác Nai-a-ga-ra',
        fact: 'Thác nước rất lớn đổ ầm ầm, bọt tung trắng xóa.',
        clue: 'Thác nước rất lớn đổ ầm ầm, bọt trắng xóa.',
      ),
    ],
  ),
];
