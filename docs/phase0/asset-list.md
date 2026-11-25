# Danh sách hình cần làm cho giai đoạn 1

Tài liệu này dành cho chủ dự án. Mỗi hình tạo **riêng một lần** trên Gemini (không dùng bảng lưới nhiều hình trong một ảnh), rồi cắt nền bằng script `tools/assets/cut_sheet.py`.

## Cách làm

**Đoạn mô tả phong cách cố định** (dán vào mọi câu lệnh, giữ nguyên):

> soft 3D render, cute rounded toy-like shapes, smooth glossy plastic and soft clay materials, soft warm studio lighting, gentle shadows, vibrant soft pastel colors, plain pure white background, no text

Lưu ý:
- Làm trong cùng một cuộc chat Gemini và **luôn gửi kèm ảnh mẫu gốc** của Chíp Chíp để nhân vật giữ nguyên dáng vẻ.
- **Bật chế độ tạo ảnh**; đừng để Gemini trả về code SVG.
- Gemini hay vẽ thêm dấu ✦ ở góc ảnh: cắt bỏ (chọn khung cắt không chứa dấu này).
- Không ghi tên hãng hay nhân vật có thật trong câu lệnh.
- Đọc điều khoản dùng ảnh thương mại của Google tại thời điểm dùng.

## Cắt nền bằng script

```
pip install -r tools/assets/requirements.txt
python3 tools/assets/cut_sheet.py <ảnh> <cấu hình.json> <thư mục ra>
```

Cấu hình mẫu:

```json
{"items": [{"name": "chip-joy", "box": [0, 40, 341, 415]}], "export_widths": [120, 240, 360]}
```

`box` là khung cắt `[trái, trên, phải, dưới]` tính bằng pixel. Ra ba file đúng quy ước mật độ ảnh của Flutter: `chip-joy.png` (rộng 120), `2.0x/chip-joy.png` (240), `3.0x/chip-joy.png` (360).

## Danh sách hình

### Chíp Chíp (7 hình)
Mỗi hình tạo riêng, cạnh dài ít nhất 800 px.
1. Chíp Chíp chính (đứng thẳng, nhìn thẳng).
2. Vui (joy).
3. Giơ ngón cái (thumb).
4. Ngạc nhiên (surprise).
5. Động viên (encourage).
6. Ngủ (sleep).
7. Đang viết (write): **làm lại**. Cầm bút tự nhiên, có nét vẽ trên đất, ít nhất 800 px.

### Biểu tượng 4 môn (4 hình)
Viết, Tiếng Việt, Toán, Tiếng Anh. Mỗi biểu tượng một hình riêng.

### Biểu tượng thưởng (3 hình)
- Sao.
- Lửa (chuỗi ngày học).
- Vương miện: **bỏ dấu ✦ trên vành**.

### Cảnh đầu trang (1 hình)
Tỷ lệ dọc, rộng ít nhất 1170 px. Không cần tách nền.

### Sticker (khoảng 30 hình)
Mỗi sticker một hình riêng, nền trắng, nhìn cùng phong cách với Chíp Chíp. Chốt danh sách cụ thể cùng chủ dự án trước khi làm.


## Phần thưởng đua với bạn (2B-2, cần vẽ)

Đang dùng **ảnh 3D có sẵn làm tạm** (đúng nghĩa nhưng chưa phải huy chương). Khi vẽ xong: ảnh nền xanh lá, tách bằng `tools/assets/chroma_key.py`, xuất 1x/2x/3x vào `assets/images/game/`, đổi đường dẫn trong `lib/game/data/badges.dart` (`image:`) và `AppImages.stickers`.

| Huy hiệu | Ảnh thực tế / Ảnh tạm | Gợi ý vẽ (cùng kiểu huy chương đất sét 3D như 8 huy hiệu cũ) |
|---|---|---|
| Bạn Đua Vui Vẻ (`friend_racer`) | `badge-friend-racer.png` (Đã vẽ 3D) | Hai tên lửa nhỏ bay song song, dải ruy băng cam |
| Nhà Vô Địch (`friend_champion`) | `badge-friend-champion.png` (Đã vẽ 3D) | Cúp vàng có ngôi sao, ruy băng đỏ |
| Cuộc Đua Lớn (`big_race`) | `badge-big-race.png` (Đã vẽ 3D) | Bốn tên lửa bốn màu quanh hành tinh |
| Cổ Vũ Nhiệt Tình (`cheerleader`) | `badge-cheerleader.png` (Đã vẽ 3D) | Cờ cổ vũ + trái tim |

| Sticker hiếm | Ảnh thực tế / Ảnh tạm | Gợi ý vẽ (Chíp 3D, viền vàng lấp lánh) |
|---|---|---|
| `rare_chip_sleep` Chíp ngủ say | `sticker-rare-chip-sleep.png` (Đã vẽ 3D) | Chíp ngủ trên mặt trăng |
| `rare_chip_write` Chíp tập viết | `sticker-rare-chip-write.png` (Đã vẽ 3D) | Chíp viết chữ phát sáng |
| `rare_rocket_chip` Chíp lái tên lửa | `sticker-rare-rocket-chip.png` (Đã vẽ 3D) | Chíp đội mũ phi công vàng |
| `rare_crown` Vương miện vàng | `sticker-rare-crown.png` (Đã vẽ 3D) | Chíp đội vương miện |
| `rare_comet` Sao chổi rực rỡ | `sticker-rare-comet.png` (Đã vẽ 3D) | Chíp cưỡi sao chổi |
| `rare_planet` Hành tinh vành đai | `sticker-rare-planet.png` (Đã vẽ 3D) | Chíp ngồi trên vành Sao Thổ |

Sticker của 4 huy hiệu mới dùng tư thế Chíp có sẵn: giơ ngón cái, vui mừng, ngạc nhiên, cổ vũ.

## Bộ ảnh đại diện con vật & Sticker Đua Bạn Bè (2B-2 / Online)

Hiện đang dùng ảnh giữ chỗ vector/canvas do `tools/assets/make_placeholders.py` sinh ra (không ghi đè khi thay ảnh thật).
Khi vẽ bằng Gemini:
- **Câu lệnh chung:** `soft 3D render, cute rounded toy-like shapes, smooth glossy plastic and soft clay materials, soft warm studio lighting, gentle shadows, vibrant colors, solid green background #00FF00, no text`
- Tách nền bằng script: `python3 tools/assets/chroma_key.py <ảnh> <config.json> <thư mục ra>`

### 12 Ảnh đại diện con vật (`assets/images/avatars/`)

| Tên file | Nhân vật | Gợi ý mô tả Gemini (3D mềm kiểu đồ chơi như Chíp, nền xanh lá #00FF00) |
|---|---|---|
| `fox.png` | Cáo con | Chú cáo con màu cam đất sét mềm, tai vểnh, má phúng phính, mắt to tròn lanh lợi |
| `panda.png` | Gấu trúc | Chú gấu trúc con tròn xoe trắng đen, ôm cành măng tre đồ chơi, má hồng |
| `bunny.png` | Thỏ con | Bé thỏ con màu trắng hồng pastel, hai tai dài cụp nhẹ, nơ nhỏ xinh xắn |
| `tiger.png` | Hổ con | Chú hổ con màu vàng cam có sọc vằn mềm mại, cười toe toét dũng cảm |
| `cat.png` | Mèo con | Mèo con tròn trịa lông vàng kem, râu mép ngộ nghĩnh, mắt biếc long lanh |
| `dog.png` | Cún con | Chú cún con tai cụp màu nâu ấm, mũi đen tròn ươn ướt, đeo vòng cổ đỏ |
| `elephant.png` | Voi con | Chú voi con màu xanh đá pastel (slate blue), vòi cong giơ lên chào, tai to |
| `dino.png` | Khủng long | Bé khủng long bạo chúa tí hon màu xanh lá mạ, gai lưng tròn mềm, bụng vàng |
| `owl.png` | Cú mèo | Chú cú mèo con mắt tròn xoe sáng ngời, lông tím pastel mềm mại, đầu nghiêng tò mò |
| `penguin.png` | Cánh cụt | Chim cánh cụt con mập mạp bụng trắng lưng đen, mỏ cam, lắc lư ngộ nghĩnh |
| `bear.png` | Gấu con | Gấu nâu con ấm áp, ôm hũ mật ong đất sét nhỏ, biểu cảm hiền lành |
| `unicorn.png` | Kỳ lân | Bé kỳ lân màu trắng ngọc, bờm ngũ sắc pastel, sừng vàng xoắn ốc đồ chơi |

### 8 Sticker Đua bạn bè (`assets/images/game/`)

| Tên file | Sticker | Gợi ý mô tả Gemini (3D mềm kiểu đồ chơi như Chíp, nền xanh lá #00FF00) |
|---|---|---|
| `sticker-tease-bubble.png` | Bọt bóng trêu | Bong bóng xà phòng 3D trong veo ngũ sắc bốc lên lung linh, phản chiếu ánh sáng |
| `sticker-tease-tongue.png` | Lè lưỡi trêu | Biểu tượng mặt cười 3D đất sét lè lưỡi nháy mắt tinh nghịch lém lỉnh |
| `sticker-tease-byebye.png` | Vẫy tay tạm biệt | Bàn tay găng trắng 3D vẫy tay chào tạm biệt bye-bye bồng bềnh |
| `sticker-tease-rain.png` | Mưa rào | Đám mây nhỏ màu xanh xám có giọt mưa rơi tí tách kèm hạt mưa lấp lánh |
| `sticker-tease-sleepy.png` | Buồn ngủ | Mũ ngủ sọc xanh trắng kèm chữ zZz 3D bồng bềnh lơ lửng |
| `sticker-tease-turtle.png` | Rùa bò chậm | Chú rùa con mai tròn màu xanh ngọc bò chậm rãi, đầu rụt rè ngộ nghĩnh |
| `sticker-tease-smoke.png` | Xì khói | Đám mây khói xì poof xám trắng bùng ra tròn xoe như khói ống xả xe đồ chơi |
| `sticker-party.png` | Pháo hoa tiệc | Ống pháo giấy bung tỏa hoa giấy ngũ sắc và dải ruy băng lấp lánh ăn mừng |


## Đảo Khám phá — Địa lý (51 ảnh)

Hiện đang dùng ảnh tạm (vòng tròn xanh có chữ) do `tools/assets/make_placeholders.py` sinh. Ảnh thật ghi đè đúng tên file; script ảnh tạm không bao giờ ghi đè ảnh thật. Thẻ "Đảo Khám phá" chỉ hiện khi bật công tắc `EXPLORE_ISLAND`. Chỉ bật sau khi ảnh thật đã thay hết và chữ đã được duyệt (`docs/superpowers/specs/assets/dia-ly-noi-dung.md`).

**Thứ tự làm:**
1. Làm **3 ảnh mẫu** trước: `geo-ho-guom`, `geo-vinh-ha-long`, `geo-thap-eiffel`. Xem ba ảnh cạnh nhau. Nếu cùng góc nhìn, cùng kiểu đế, cùng ánh sáng và đúng "đồ chơi" thì làm tiếp phần còn lại trong **cùng cuộc chat** (gửi kèm 3 ảnh mẫu đã chọn làm ảnh tham chiếu).
2. Mỗi ảnh tạo riêng một lần, khổ vuông 1:1 (1024×1024).
3. Tách nền và xuất ảnh:
   ```
   python3 tools/assets/chroma_key.py <ảnh.png> tools/assets/configs/explore/<tên>.json assets/images/explore
   ```
   Riêng `ic-kham-pha` xuất vào `assets/images`. Cấu hình mặc định cắt cả khung 1024×1024. Nếu ảnh có kích thước khác hoặc vật nằm lệch thì sửa `box` trong file `.json`.
4. Chạy `flutter test test/ui/assets_test.dart` để kiểm tra đủ 3 độ phân giải và có nền trong suốt.

**Đoạn phong cách chung.** Dán vào cuối mọi câu lệnh, giữ nguyên:

> Style: a miniature diorama toy, soft 3D render, cute rounded chunky shapes, smooth matte clay and soft plastic materials, sitting on a small round grassy base with soft rounded edges, three-quarter view from slightly above, centered, filling about 80% of the frame, soft warm studio lighting, gentle soft shadow under the base, bright friendly pastel colors, simple details suitable for a 4-year-old, square 1:1 image, solid flat pure green background #00FF00 everywhere around the object, no text, no letters, no logos, no people, no watermark, no sparkle icon in the corner.

Lưu ý:
- **Không có người** trong ảnh. Muốn có "người" (bán hàng, chèo thuyền) thì chỉ dùng hình nhân gỗ tròn không mặt.
- Vật không được có màu xanh lá thuần giống nền, vì script sẽ xóa luôn. Cây cỏ và đế cỏ dùng **xanh lá ngả vàng hoặc xanh rêu** (`olive / sage green`), không dùng `#00FF00`.
- Gemini hay tự thêm chữ hoặc biển tên. Nếu có thì yêu cầu vẽ lại: "remove all text and signs".

### Sảnh đảo (4 ảnh)

| File | Câu lệnh (dán thêm đoạn phong cách chung) |
|---|---|
| `ic-kham-pha.png` (ra `assets/images/`) | A tiny round tropical island with a palm tree, a little globe and a golden compass standing on the sand, turquoise water ring around the island |
| `island-dia-ly.png` | A tiny island shaped like a small hill with a red flag pole without text, a little rolled paper map and a compass, a small blue river winding down to the sea |
| `island-sinh-hoc.png` | A tiny island covered with leafy trees, a big friendly flower, a ladybug and a butterfly, a small pond with a frog |
| `island-lich-su.png` | A tiny island with an ancient stone gate, a bronze drum and an old scroll, soft beige and terracotta colors |

### Cấp 1 — Cảnh vật quanh em

| File | Câu lệnh |
|---|---|
| `geo-nui.png` | A tall friendly mountain with layered slopes and a little white cloud touching its rounded peak, small pine trees at the bottom |
| `geo-song.png` | A gentle blue river winding through soft hills, a tiny wooden boat floating on it |
| `geo-bien.png` | A cheerful sea scene: turquoise waves with white foam rolling onto a small golden sandy beach, a seashell on the sand |
| `geo-rung.png` | A small lush forest of round leafy trees in several sage and olive greens, a little bird on a branch and a deer peeking out |
| `geo-dong-lua.png` | A small rice paddy field in neat rows of young rice plants, water reflecting the sky, a tiny scarecrow without a face |
| `geo-hang-dong.png` | A rocky hill with a big rounded cave entrance, soft glowing crystals and stalactites inside the cave |

### Cấp 2 — Thời tiết

| File | Câu lệnh |
|---|---|
| `geo-nang.png` | A bright smiling sun with rounded rays shining over a little hill with a flower |
| `geo-mua.png` | A soft grey cloud with big blue raindrops falling on a little hill with a small puddle and an open umbrella |
| `geo-gio.png` | Swirly wind lines blowing a colorful kite high above a little hill, leaves flying and a tree bending gently |
| `geo-may.png` | Three fluffy white clouds floating above a little hill, soft and puffy like cotton |
| `geo-cau-vong.png` | A bright rainbow arching over a little hill, with a small white cloud at each end |
| `geo-sam-set.png` | A dark rounded storm cloud with a bright yellow zigzag lightning bolt, a tiny house with a warm lit window on the hill below |

### Cấp 3 — Đất nước em

| File | Câu lệnh |
|---|---|
| `geo-co-viet-nam.png` | The flag of Vietnam waving on a pole: a red flag with one large yellow five-pointed star in the center, nothing else on the flag |
| `geo-ban-do-chu-s.png` | A raised toy relief map of Vietnam, the S-shaped country in soft green and yellow with mountains in the north, the blue sea along the east coast, **clearly including the Hoang Sa (Paracel) islands and the Truong Sa (Spratly) islands as small island groups in the sea to the east**, no text, no labels, no borders of other countries drawn |
| `geo-non-la.png` | A Vietnamese conical palm-leaf hat (non la) resting on a little stand, light straw color with visible leaf ribs, a soft ribbon tie |
| `geo-ao-dai.png` | A Vietnamese ao dai dress displayed on a small wooden dress stand (no person), long flowing panels in soft red with a delicate flower pattern, white trousers |
| `geo-hoa-sen.png` | A pink lotus flower in bloom rising from a small pond with round green lotus leaves |

### Cấp 4 — Miền Bắc

| File | Câu lệnh |
|---|---|
| `geo-ho-guom.png` | Hoan Kiem Lake in Hanoi: a small green lake with the Turtle Tower (a small three-tiered old tower) on a tiny islet in the middle, and the red curved The Huc wooden bridge leading to a little temple on the shore, willow trees |
| `geo-vinh-ha-long.png` | Ha Long Bay: several tall rounded limestone karst islands rising from emerald water, a small wooden junk boat with brown sails |
| `geo-van-mieu.png` | The Temple of Literature in Hanoi: the Khue Van Cac pavilion, a small two-storey square gate pavilion with round windows, beside a square pond, old trees |
| `geo-chua-mot-cot.png` | The One Pillar Pagoda in Hanoi: a small wooden pagoda with a curved tiled roof standing on a single stone pillar in the middle of a square lotus pond |
| `geo-ruong-bac-thang.png` | Rice terraces of Sa Pa: layered curved rice terraces stepping down a mountain slope like stairs, golden and green bands |

### Cấp 5 — Miền Trung

| File | Câu lệnh |
|---|---|
| `geo-co-do-hue.png` | The Meridian Gate of the Hue Imperial City: a grand old gate with tiered yellow-tiled roofs on a thick stone base with three arches, beside a calm river |
| `geo-chua-cau.png` | The Japanese Covered Bridge in Hoi An: a small arched wooden bridge with a tiled roof over a canal, yellow walls and colorful silk lanterns hanging nearby |
| `geo-cau-rong.png` | The Dragon Bridge in Da Nang: a bridge whose arches are shaped like a long golden-yellow dragon with its head raised, over a blue river |
| `geo-dong-phong-nha.png` | Phong Nha cave: a tall cave mouth in a forested limestone mountain with a small boat entering on a turquoise river, sparkling stalactites inside |
| `geo-cau-vang.png` | The Golden Bridge in Ba Na Hills: a curving golden walkway bridge held up by two giant mossy grey stone hands rising from the mountain |

### Cấp 6 — Miền Nam

| File | Câu lệnh |
|---|---|
| `geo-cho-ben-thanh.png` | Ben Thanh Market in Saigon: a cream-colored market building with a central clock tower above the main entrance (clock without numbers), small stalls with fruit baskets |
| `geo-cho-noi-cai-rang.png` | Cai Rang floating market in the Mekong Delta: several small wooden boats on a brown river loaded with watermelons, pineapples and bananas, long poles with fruit hanging on top |
| `geo-nha-tho-duc-ba.png` | Notre-Dame Cathedral of Saigon: a red-brick church with two tall pointed square towers and a rose window, small trees in front |
| `geo-buu-dien-sai-gon.png` | The Saigon Central Post Office: a long yellow colonial building with a big arched entrance, green window shutters and a round clock face above (no numbers) |
| `geo-mui-ca-mau.png` | Ca Mau Cape: the pointed southern tip of land with mangrove trees on its roots, waves on both sides, a small sailboat-shaped monument on the tip |

### Cấp 7 — Châu Á

| File | Câu lệnh |
|---|---|
| `geo-van-ly-truong-thanh.png` | The Great Wall of China: a long stone wall with square watchtowers snaking over green rolling mountains |
| `geo-nui-phu-si.png` | Mount Fuji: a cone-shaped mountain with a snowy white top, a small red pagoda and pink cherry blossom trees at its foot |
| `geo-taj-mahal.png` | The Taj Mahal: a white marble palace with a big onion-shaped dome and four slender towers, a long reflecting pool in front |
| `geo-angkor-wat.png` | Angkor Wat: an ancient grey-brown stone temple with five lotus-bud shaped towers, reflected in a pond with lilies |
| `geo-thap-petronas.png` | The Petronas Twin Towers: two identical tall silver skyscrapers side by side joined by a little sky bridge |

### Cấp 8 — Châu Âu & châu Phi

| File | Câu lệnh |
|---|---|
| `geo-thap-eiffel.png` | The Eiffel Tower: a tall brown iron lattice tower on a small round park base with tiny trees |
| `geo-kim-tu-thap.png` | The pyramids of Giza: one big and two smaller sandy-yellow pyramids in the desert, a small sphinx and a palm tree |
| `geo-thap-pisa.png` | The Leaning Tower of Pisa: a round white marble bell tower with many columns, clearly leaning to one side |
| `geo-big-ben.png` | Big Ben: a tall golden-brown gothic clock tower with a big round clock face (no numbers) and a pointed green roof |
| `geo-dau-truong-la-ma.png` | The Colosseum in Rome: a round ancient stone arena with rows of arches, one side taller than the other as if partly broken |

### Cấp 9 — Châu Mỹ & châu Úc

| File | Câu lệnh |
|---|---|
| `geo-tuong-nu-than-tu-do.png` | The Statue of Liberty: a pale blue-green copper statue holding a torch up high, on a stone pedestal on a tiny island, the statue's face simple and friendly |
| `geo-nha-hat-opera-sydney.png` | The Sydney Opera House: white shell-shaped roofs like sails on a harbor edge, blue water around |
| `geo-machu-picchu.png` | Machu Picchu: old stone terraces and small stone houses on a mountain top, with the tall pointed green peak behind, a little llama |
| `geo-tuong-chua-cuu-the.png` | The Christ the Redeemer statue in Rio: a tall white statue with arms spread wide standing on top of a green mountain peak, simple smooth figure without facial detail |
| `geo-thac-niagara.png` | Niagara Falls: a wide curved waterfall pouring white foamy water into a river, a small rainbow in the mist and a tiny blue boat |
