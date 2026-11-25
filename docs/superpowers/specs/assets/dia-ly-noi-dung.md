# Đảo Khám phá — Địa lý: bảng duyệt chữ

Chủ dự án đọc từng dòng, sửa trực tiếp nếu cần (báo lại để AI cập nhật `lib/explore/geography_level.dart`), rồi đánh `x` vào cột **Duyệt**. Chỉ bật công tắc `EXPLORE_ISLAND` khi cả 47 dòng đã duyệt.

- **Câu kể**: Chíp đọc sau khi bé chọn đúng (≤ 15 từ, không số năm, không chiến tranh/chính trị/tôn giáo).
- **Gợi ý**: câu đố cho dạng "nghe kể rồi chọn" (cấp 4–9). Cả hai câu không được nhắc tên đáp án.
- **Cách đọc**: chữ giọng máy đọc (tên nước ngoài phiên âm). Khi thử trên máy thật, ghi lại tên nào đọc sai.

Bảng này sinh từ code; nếu sửa code thì sinh lại cho khớp.

| Cấp | id | Tên | Cách đọc | Câu kể | Gợi ý | Duyệt |
|---|---|---|---|---|---|---|
| 1. Cảnh vật quanh em | `nui` | Núi | Núi | Cao thật cao, đỉnh chạm tới những đám mây. | Nơi này cao thật cao, leo mãi mới tới đỉnh. |  |
| 1. Cảnh vật quanh em | `song` | Sông | Sông | Nước chảy dài, có thuyền đi lại trên mặt nước. | Dòng nước dài chảy mãi, có thuyền đi trên đó. |  |
| 1. Cảnh vật quanh em | `bien` | Biển | Biển | Nước mặn mênh mông, có sóng vỗ và bãi cát vàng. | Nước mặn mênh mông, có sóng vỗ rì rào. |  |
| 1. Cảnh vật quanh em | `rung` | Rừng | Rừng | Thật nhiều cây xanh, là nhà của chim và thú. | Nơi có thật nhiều cây, chim và thú sống ở đây. |  |
| 1. Cảnh vật quanh em | `dong-lua` | Đồng lúa | Đồng lúa | Bác nông dân trồng lúa ở đây để có gạo nấu cơm. | Cánh đồng xanh mướt, có hạt gạo để nấu cơm. |  |
| 1. Cảnh vật quanh em | `hang-dong` | Hang động | Hang động | Bên trong núi tối và mát, có đá lấp lánh. | Đi vào bên trong núi, tối và mát rượi. |  |
| 2. Thời tiết | `nang` | Nắng | Nắng | Ông mặt trời chiếu sáng, trời ấm áp và rực rỡ. | Ông mặt trời chiếu sáng, trời thật ấm áp. |  |
| 2. Thời tiết | `mua` | Mưa | Mưa | Những giọt nước rơi tí tách, nhớ mang ô khi ra ngoài nhé. | Những giọt nước rơi tí tách từ trên trời. |  |
| 2. Thời tiết | `gio` | Gió | Gió | Thổi vù vù làm lá cây rung rinh và diều bay cao. | Thổi vù vù, làm diều bay thật cao. |  |
| 2. Thời tiết | `may` | Mây | Mây | Trắng bồng bềnh như bông, trôi chầm chậm trên trời. | Trắng bồng bềnh như bông, trôi trên bầu trời. |  |
| 2. Thời tiết | `cau-vong` | Cầu vồng | Cầu vồng | Hiện ra sau cơn mưa với thật nhiều màu sắc. | Sau cơn mưa, trên trời hiện ra thật nhiều màu. |  |
| 2. Thời tiết | `sam-set` | Sấm sét | Sấm sét | Trời lóe sáng rồi đùng đoàng, bé ở trong nhà nhé. | Trời lóe sáng rồi kêu đùng đoàng. |  |
| 3. Đất nước em | `co-viet-nam` | Lá cờ Việt Nam | Lá cờ Việt Nam | Nền đỏ, ở giữa có ngôi sao vàng năm cánh. | Nền đỏ, ở giữa có ngôi sao vàng. |  |
| 3. Đất nước em | `ban-do-chu-s` | Bản đồ Việt Nam | Bản đồ Việt Nam | Đất nước mình cong cong hình chữ S bên bờ biển. | Đất nước mình cong cong như chữ S. |  |
| 3. Đất nước em | `non-la` | Nón lá | Nón lá | Làm bằng lá, đội lên đầu để che nắng che mưa. | Đội lên đầu để che nắng, làm bằng lá. |  |
| 3. Đất nước em | `ao-dai` | Áo dài | Áo dài | Chiếc áo thướt tha, mẹ và cô hay mặc ngày Tết. | Chiếc áo thướt tha, mẹ hay mặc ngày Tết. |  |
| 3. Đất nước em | `hoa-sen` | Hoa sen | Hoa sen | Bông hoa hồng thơm ngát, mọc lên từ trong ao. | Bông hoa thơm ngát mọc lên giữa ao. |  |
| 4. Miền Bắc | `ho-guom` | Hồ Gươm | Hồ Gươm | Hồ nước ở Hà Nội, giữa hồ có Tháp Rùa. | Hồ nước ở Hà Nội, giữa hồ có một ngọn tháp nhỏ. |  |
| 4. Miền Bắc | `vinh-ha-long` | Vịnh Hạ Long | Vịnh Hạ Long | Thật nhiều đảo đá nhô lên giữa biển xanh. | Nơi này có thật nhiều đảo đá giữa biển xanh. |  |
| 4. Miền Bắc | `van-mieu` | Văn Miếu | Văn Miếu | Trường học rất xưa ở Hà Nội, có giếng nước vuông. | Trường học rất xưa ở Hà Nội, có cổng cao. |  |
| 4. Miền Bắc | `chua-mot-cot` | Chùa Một Cột | Chùa Một Cột | Ngôi chùa nhỏ đứng trên một cây cột giữa ao sen. | Ngôi chùa nhỏ đứng trên chỉ một cây cột. |  |
| 4. Miền Bắc | `ruong-bac-thang` | Ruộng bậc thang | Ruộng bậc thang | Ruộng lúa xếp từng bậc như cầu thang trên núi. | Ruộng lúa xếp từng bậc trên sườn núi. |  |
| 5. Miền Trung | `co-do-hue` | Cố đô Huế | Cố đô Huế | Cung điện xưa có cổng lớn, nằm bên sông Hương. | Cung điện xưa có cổng lớn, bên dòng sông Hương. |  |
| 5. Miền Trung | `chua-cau` | Chùa Cầu Hội An | Chùa Cầu Hội An | Cây cầu nhỏ có mái che ở phố cổ đèn lồng. | Cây cầu nhỏ có mái, ở phố cổ treo đèn lồng. |  |
| 5. Miền Trung | `cau-rong` | Cầu Rồng | Cầu Rồng | Cây cầu ở Đà Nẵng uốn lượn như một con rồng. | Cây cầu ở Đà Nẵng uốn lượn như con rồng. |  |
| 5. Miền Trung | `dong-phong-nha` | Động Phong Nha | Động Phong Nha | Hang động rất đẹp, đi thuyền vào bên trong núi. | Đi thuyền vào trong lòng núi, thấy đá lấp lánh. |  |
| 5. Miền Trung | `cau-vang` | Cầu Vàng | Cầu Vàng | Cây cầu màu vàng được hai bàn tay đá nâng lên. | Cây cầu được hai bàn tay khổng lồ nâng lên. |  |
| 6. Miền Nam | `cho-ben-thanh` | Chợ Bến Thành | Chợ Bến Thành | Khu chợ lớn ở Sài Gòn, có tháp đồng hồ. | Khu chợ lớn ở Sài Gòn, cổng có đồng hồ. |  |
| 6. Miền Nam | `cho-noi-cai-rang` | Chợ nổi Cái Răng | Chợ nổi Cái Răng | Chợ họp ngay trên sông, thuyền nào cũng đầy trái cây. | Mọi người mua bán trái cây ngay trên thuyền. |  |
| 6. Miền Nam | `nha-tho-duc-ba` | Nhà thờ Đức Bà | Nhà thờ Đức Bà | Tòa nhà gạch đỏ có hai tháp cao ở Sài Gòn. | Tòa nhà gạch đỏ ở Sài Gòn, có hai tháp cao. |  |
| 6. Miền Nam | `buu-dien-sai-gon` | Bưu điện Sài Gòn | Bưu điện Sài Gòn | Nơi gửi thư và bưu thiếp, mái vòm thật đẹp. | Nơi mọi người đến gửi thư và bưu thiếp. |  |
| 6. Miền Nam | `mui-ca-mau` | Mũi Cà Mau | Mũi Cà Mau | Mảnh đất ở tận cùng phía nam của đất nước. | Mảnh đất xa nhất ở phía nam, có rừng đước. |  |
| 7. Châu Á | `van-ly-truong-thanh` | Vạn Lý Trường Thành | Vạn Lý Trường Thành | Bức tường đá rất dài uốn quanh núi ở Trung Quốc. | Bức tường đá rất dài uốn lượn trên núi. |  |
| 7. Châu Á | `nui-phu-si` | Núi Phú Sĩ | Núi Phú Sĩ | Ngọn núi đỉnh phủ tuyết trắng ở Nhật Bản. | Ngọn núi ở Nhật Bản, đỉnh phủ tuyết trắng. |  |
| 7. Châu Á | `taj-mahal` | Đền Taj Mahal | Đền Tát Ma-han | Tòa nhà trắng tinh có mái tròn ở Ấn Độ. | Tòa nhà trắng tinh ở Ấn Độ, mái tròn như củ hành. |  |
| 7. Châu Á | `angkor-wat` | Angkor Wat | Ăng-co Vát | Đền đá cổ rất lớn ở Cam-pu-chia. | Ngôi đền đá cổ rất lớn ở Cam-pu-chia. |  |
| 7. Châu Á | `thap-petronas` | Tháp đôi Petronas | Tháp đôi Pê-tơ-rô-nát | Hai tòa tháp cao vút giống nhau ở Ma-lai-xi-a. | Hai tòa tháp cao vút đứng cạnh nhau như anh em. |  |
| 8. Châu Âu & châu Phi | `thap-eiffel` | Tháp Eiffel | Tháp Ép-phen | Ngọn tháp sắt cao vút ở nước Pháp. | Ngọn tháp bằng sắt cao vút ở nước Pháp. |  |
| 8. Châu Âu & châu Phi | `kim-tu-thap` | Kim tự tháp | Kim tự tháp | Khối đá hình tam giác khổng lồ giữa sa mạc Ai Cập. | Khối đá hình tam giác khổng lồ giữa sa mạc. |  |
| 8. Châu Âu & châu Phi | `thap-pisa` | Tháp nghiêng Pisa | Tháp nghiêng Pi-da | Ngọn tháp nghiêng nghiêng mà không đổ, ở nước Ý. | Ngọn tháp đứng nghiêng nghiêng mà không bị đổ. |  |
| 8. Châu Âu & châu Phi | `big-ben` | Tháp Big Ben | Tháp Bích Ben | Tháp đồng hồ lớn kêu boong boong ở nước Anh. | Tháp đồng hồ lớn ở nước Anh, kêu boong boong. |  |
| 8. Châu Âu & châu Phi | `dau-truong-la-ma` | Đấu trường La Mã | Đấu trường La Mã | Sân đá tròn rất cổ, có nhiều vòm cửa, ở nước Ý. | Sân đá tròn rất cổ, có thật nhiều vòm cửa. |  |
| 9. Châu Mỹ & châu Úc | `tuong-nu-than-tu-do` | Tượng Nữ thần Tự do | Tượng Nữ thần Tự do | Bức tượng xanh giơ cao ngọn đuốc ở nước Mỹ. | Bức tượng màu xanh giơ cao ngọn đuốc. |  |
| 9. Châu Mỹ & châu Úc | `nha-hat-opera-sydney` | Nhà hát Opera Sydney | Nhà hát Ô-pê-ra Xít-ni | Mái nhà trắng như những cánh buồm, ở nước Úc. | Mái nhà trắng như những cánh buồm bên bờ biển. |  |
| 9. Châu Mỹ & châu Úc | `machu-picchu` | Machu Picchu | Ma-chu Pích-chu | Thành phố đá cổ trên đỉnh núi cao ở Pê-ru. | Thành phố đá cổ nằm trên đỉnh núi cao. |  |
| 9. Châu Mỹ & châu Úc | `tuong-chua-cuu-the` | Tượng Chúa Cứu Thế | Tượng Chúa Cứu Thế | Bức tượng dang rộng hai tay trên núi ở Bra-xin. | Bức tượng dang rộng hai tay trên đỉnh núi. |  |
| 9. Châu Mỹ & châu Úc | `thac-niagara` | Thác Niagara | Thác Nai-a-ga-ra | Thác nước rất lớn đổ ầm ầm, bọt tung trắng xóa. | Thác nước rất lớn đổ ầm ầm, bọt trắng xóa. |  |
