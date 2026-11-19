# Kế hoạch: Đua tên lửa — đồng bộ thiết kế, bỏ "nét AI" (2026-11-19)

> Người lập kế hoạch / rà soát: kỹ sư trưởng (AI). Người code: AI khác.
> Đọc `AGENTS.md`, `docs/PROJECT_STATE.md` mục 2 (phong cách đã chốt) trước.
> **Có cổng duyệt:** Giai đoạn 0 tạo ảnh mẫu tĩnh → chủ dự án duyệt → mới làm Giai đoạn 1–3.
> Không đổi engine trận đua (`lib/game/engine/`), dữ liệu, luật sao, luật huy hiệu. Đây là việc **thuần giao diện**.

## 1. Vấn đề (góp ý của chủ dự án + rà soát ảnh chụp)

Chủ dự án nói: "nhìn ra nét AI, chỉ show UI chứ không có sự hòa hợp, chiều sâu". Rà soát ảnh chụp (`tools/shot/game_shot_test.dart`, `hub_shot_test.dart`; điện thoại 390×844, iPad ngang 1366×1024) cho thấy các nguyên nhân cụ thể:

| # | Vấn đề | Chỗ thấy |
|---|---|---|
| D1 | **Bốn ngôn ngữ chất liệu trên cùng một màn:** kính mờ tối viền neon (`FloatingCockpitHUD`: `BackdropFilter` + viền `0x559C7DFF`), viên trắng kiểu kẹo (`_HudPill`, nút tạm dừng), viên cam phát sáng viền trắng (`_NitroBadge`), tên lửa đất sét 3D. Không có một nguồn sáng hay chất liệu chung, nên mỗi thứ như được dán vào từ một bộ khác nhau. | `race_screen.dart` |
| D2 | **Không có bố cục, mọi thứ trôi lơ lửng:** hai tên lửa giữa khoảng tím trống, hành tinh nhỏ xa xa, chữ "VƯỢT LÊN!" lơ lửng. **Nhìn không ra đây là cuộc đua:** ai đang dẫn chỉ thể hiện bằng thanh tiến độ mảnh ~4px ở mép phải. | cảnh đua |
| D3 | **Dùng chữ để báo cho bé chưa biết đọc:** "VƯỢT LÊN!", "NITRO x2!" (tiếng Anh), "Câu sao chổi! Đúng là bay vọt 2 nấc". Lúc có combo, ba nhãn chồng lên nhau phía trên câu hỏi. | `game-comet.png` |
| D4 | **Hai tên lửa không cùng một bộ:** tên lửa của bé là khối cam trơn, không có ai ngồi trong; tên lửa của Chíp có cửa kính và Chíp vẫy tay. Bé không thấy "mình" trong cuộc đua. | cảnh đua |
| D5 | **Hiệu ứng chung chung:** vệt trắng dọc cố định trông như mưa, sao ✦ rải rác, quầng sáng neon, nền kính mờ. Đây chính là bộ "mặc định" thường thấy ở giao diện do AI sinh. | cảnh đua |
| D6 | **Màn kết quả là một chồng viên thuốc:** trời tím cắt ngang thành nền kem, có một dải hồng ở giữa; các viên "+9 sao", "+2 Sao May Mắn" (emoji thành ô vuông), thẻ quà dùng ảnh **làm mờ** trông như ảnh lỗi chưa tải xong. | `game-win.png`, `game-lose.png` |
| D7 | **iPad ngang:** panel câu hỏi bên phải là một khối tối rất lớn, phím và câu hỏi chỉ chiếm 1/3 ở giữa. | `ipad-toan.png` |
| D8 | 13 mã màu viết thẳng trong `race_screen.dart`, 1 trong `speed_lines.dart` (vi phạm quy ước "màu chỉ từ `tokens.dart`"). `GameColors.ink` vẫn còn dù tài liệu ghi đã bỏ. | code |

## 2. Hướng thiết kế (kỹ sư trưởng đề xuất, chờ chủ dự án duyệt ở Giai đoạn 0)

**Ý chính: "Đường sao về hành tinh". Biến cuộc đua thành một con đường nhìn thấy được, và dùng lại chất liệu đồ chơi của toàn app.**

1. **Một con đường, mười bậc sao.** Từ đáy cảnh tới hành tinh đích là một đường cong mềm, gồm 10 "bậc" (sao nhỏ hoặc tiểu hành tinh 3D, cùng chất đất sét). Trả lời đúng thì bậc kế tiếp sáng lên và tên lửa *nhảy* tới bậc đó. Hai tên lửa đi trên hai làn song song của cùng con đường. → Bé **nhìn là biết** ai đang dẫn, còn mấy bậc nữa; thanh tiến độ ở mép phải bỏ được. Hành tinh đích to dần theo tiến độ (giữ logic camera hiện có).
2. **Một nguồn sáng, một chất liệu.** Mọi vật (tên lửa, bậc sao, hành tinh, phím, thẻ câu hỏi) có ánh sáng từ trên-trái, bóng mềm xuống dưới-phải, mép dày kiểu `raisedDecoration`. Bỏ kính mờ, viền neon, quầng phát sáng quanh chữ.
3. **Trời chạng vạng ấm thay cho vũ trụ đen tím.** Dùng đúng dải màu đã có ở thẻ "Đua tên lửa" của Góc Chơi và màn kết quả (`skyTop → skyUpper → skyLower → skyHorizon`), để Góc Chơi → trận đua → kết quả là **một thế giới liền mạch**. Sao nền nhỏ, ít, không nhấp nháy loạn.
4. **Khu trả lời là "bàn học" kem của app**, giống các màn học khác: nền `AppColors.background`, thẻ câu hỏi trắng, ba phím kẹo. Mép trên của khu này là một đường cong mềm (như mặt đất / mép mây), không phải hộp bo góc trôi nổi.
5. **Báo bằng hình và giọng, không bằng chữ:**
   - Combo/Nitro → ngọn lửa tên lửa bé dài hơn và chuyển sang màu xanh-trắng, có vài vệt gió *chéo ngắn sau đuôi*, Chíp nói "Nhanh quá!". Bỏ chữ "NITRO".
   - Câu sao chổi → ảnh `AppImages.comet` bay vào và đậu ở góc thẻ câu hỏi, thẻ có viền vàng; Chíp đọc câu giải thích (giữ `_cometLine` cho giọng đọc, không hiện thành chữ).
   - Vượt lên → Chíp đổi nét mặt (ảnh `chipSurprise`/`chipEncourage` trong khung tròn nhỏ cạnh tên lửa Chíp), không có banner chữ.
   - Trên cảnh chỉ còn **một** dòng chữ: "Câu N/10" (cho ba mẹ đang ngồi cạnh).
6. **Tên lửa của bé có người lái:** cửa kính tên lửa hiện ảnh đại diện của bé (`KidProfile.avatar`, cắt tròn, đặt theo tọa độ cửa kính của từng ảnh tên lửa). Chưa có tọa độ thì để trong `rocket_sprite.dart` dạng bảng `windowCenter`/`windowRadius` theo id tên lửa.
7. **Bỏ vệt trắng dọc thường trực** (`streakLight` hiện luôn). Chỉ hiện vệt chéo ngắn khi đang bứt tốc.

> Phương án dự phòng nếu chủ dự án không thích "con đường": giữ bay tự do như hiện tại, nhưng vẫn làm các điểm 2–7. Điểm 1 là thay đổi lớn nhất và cũng giải quyết D2 tốt nhất.

## 3. Giai đoạn 0 — Ảnh mẫu tĩnh (CỔNG DUYỆT, khoảng 0,5 ngày)

Mục tiêu: chủ dự án nhìn ảnh và quyết, **trước khi** viết animation.

- Làm một harness mới `tools/shot/race_mock_shot_test.dart`: dựng cảnh mới **tĩnh** (chưa có ticker), dữ liệu giả.
- Xuất 5 ảnh: điện thoại 390×844 ở câu 2 (Chíp dẫn), câu 6 (bé dẫn, đang Nitro), câu sao chổi; iPad ngang 1366×1024 câu 6; màn kết quả thắng (theo mục 5).
- Đặt ảnh cạnh ảnh cũ trong `docs/superpowers/specs/assets/race-redesign/` (trước/sau).
- **Dừng lại, gửi kỹ sư trưởng rà soát, rồi chủ dự án duyệt.** Không làm Giai đoạn 1 khi chưa được duyệt.

## 4. Giai đoạn 1 — Cảnh đua (sau khi duyệt)

Phạm vi file: `lib/game/scene/` (`race_scene.dart`, `space_track.dart`, `speed_lines.dart`, `rocket_sprite.dart`), `lib/ui/theme/tokens.dart`.

1. `StarPath`: hình học con đường (đường cong Bézier, 11 điểm = vị trí 0..10) thay cho `TrackGeometry` cũ. Hàm thuần, có test: điểm 10 trùng tâm hành tinh, khoảng cách các bậc giảm dần theo phối cảnh, hai làn không chồng nhau ở mọi bậc với mọi kích thước 320–1366.
2. Vẽ bậc sao: đã qua = vàng sáng, kế tiếp = nhấp nháy nhẹ (tắt khi giảm chuyển động), chưa tới = mờ. Vẽ vào lớp tĩnh, **chỉ vẽ lại khi số bậc đổi** (không vẽ mỗi khung).
3. Tên lửa nhảy giữa các bậc: giữ lò xo hiện có (ζ 0,75), chỉ đổi đích sang `StarPath.point(step)`. Thêm ảnh đại diện bé trong cửa kính.
4. Bỏ: vệt dọc thường trực, thanh tiến độ mép phải, banner "VƯỢT LÊN!" vẽ trên cảnh. Giữ: lửa 4 lớp, khói `drawRawAtlas`, sao chổi, sao may mắn (đặt trên bậc 4 và 8).
5. Màu: mọi màu mới vào `GameColors`; xóa các token không còn dùng (`track*`, `laneLine`, `progress*`...) sau khi chắc không còn tham chiếu.
6. Hiệu năng: giữ 4 lớp `RepaintBoundary`; bỏ `BackdropFilter` (đang tốn nhiều nhất). Chạy `tools/shot/race_bench_test.dart`, kết quả **không được chậm hơn** số cũ.

## 5. Giai đoạn 2 — Khu trả lời và màn trận đấu

Phạm vi: `lib/features/game/race_screen.dart`, `answer_keys.dart`.

1. Thay `FloatingCockpitHUD` bằng `AnswerDesk`: nền kem, mép trên cong (CustomClipper), thẻ câu hỏi + 3 phím giữ nguyên hành vi (rung khi sai, dấu tích khi đúng, `GlyphView`).
2. Bỏ `_NitroBadge` và `_CometBanner` dạng chữ. Thay bằng: sao chổi đậu góc thẻ (ảnh `AppImages.comet`), viền thẻ vàng `GameColors.cometRim`; trạng thái Nitro thể hiện trong cảnh (Giai đoạn 1).
3. Nút tạm dừng và "Câu N/10" đặt trên một dải trên cùng, cùng chất liệu kẹo trắng; bỏ viên trắng lơ lửng giữa trời.
4. iPad ngang: cảnh chiếm 60%, bàn trả lời 40%. Thẻ câu hỏi ở trên, ba phím **vuông** xếp hàng ngang (hoặc dọc nếu hẹp), cụm này căn giữa theo chiều dọc, **không còn khối tối trống**.
5. Mọi `Color(0x…)` trong file chuyển vào `GameColors`. Sau khi xong, `grep -rn 'Color(0x' lib/features lib/game` phải trả về rỗng.
6. Chuỗi giọng đọc: "Nhanh quá!" (Nitro), câu sao chổi đọc như cũ. Thêm vào `voice_lines.dart` nếu có danh sách ở đó.

## 6. Giai đoạn 3 — Màn kết quả

Phạm vi: `lib/features/game/race_result_screen.dart`.

1. Trời chuyển sang kem **bằng một dải chuyển màu dài** (≥ 120 pt), bỏ cạnh cắt và dải hồng gắt.
2. Gộp phần thưởng thành **một** thẻ: "+9" kèm ảnh `icStar`, nếu có thêm "+2" kèm sao may mắn (ảnh, không emoji), trong cùng một hàng.
3. Thẻ quà kế tiếp: thay ảnh làm mờ bằng **bóng đen của món quà** (`ColorFiltered` với màu `GameColors.lockedSilhouette`) kèm dấu "?". Đây là cách quen thuộc với bé ("chưa mở"), không trông như ảnh hỏng.
4. Tiêu đề thua giữ ngắn: "Suýt nữa thôi!" ở dòng to; "Chỉ còn 2 bước!" ở dòng nhỏ (tránh xuống dòng giữa cụm "2 nấc").
5. Giữ nguyên luồng: cảnh hạ cánh, pháo hoa, huy hiệu, `RewardOfferSheet`.

## 7. Không làm trong đợt này

- Không đổi Góc Chơi, Xưởng độ, tủ huy hiệu, album (chỉ đổi màu nếu dùng token bị xóa).
- Không tạo ảnh 3D mới bằng Gemini (trừ khi Giai đoạn 0 cho thấy bắt buộc; nếu cần thì liệt kê và hỏi trước).
- Không đổi engine, `RaceController`, dữ liệu drift.

## 8. Tiêu chí nghiệm thu (kỹ sư trưởng dùng để rà soát)

- [ ] Ảnh Giai đoạn 0 đã được chủ dự án duyệt (ghi ngày vào `PROJECT_STATE.md`).
- [ ] Ở mọi khung hình chụp được: **không có chữ tiếng Anh**; trên cảnh chỉ có "Câu N/10".
- [ ] Không còn `BackdropFilter`, `ImageFilter.blur` trong `lib/features/game/`.
- [ ] Không còn `Color(0x` trong `lib/features/game/` và `lib/game/scene/`.
- [ ] Nhìn ảnh không có chữ, vẫn biết ai đang dẫn và còn mấy bậc (thử: cho một người chưa xem app nhìn ảnh câu 6 rồi hỏi).
- [ ] iPad ngang: bàn trả lời không có vùng trống > 25% chiều cao.
- [ ] Giảm chuyển động: không ticker, không nhấp nháy, tên lửa nhảy thẳng tới bậc.
- [ ] Nút bé ≥ 64 (điện thoại) / ≥ 80 (tablet); chữ tương phản ≥ 4.5:1 (có test `contrastRatio` cho màu mới).
- [ ] `race_bench_test.dart` không chậm hơn trước (ghi số trước/sau trong báo cáo).
- [ ] Test cũ tham chiếu `FloatingCockpitHUD`, `NITRO`, thanh tiến độ: cập nhật theo hành vi mới, **không xóa test hành vi** (rung khi sai, đồng hồ dừng khi tạm dừng, xoay iPad không mất trận...).
- [ ] `flutter analyze` sạch, `flutter test` đạt hết; cập nhật `docs/PROJECT_STATE.md` mục 6–8 và `docs/perf.md` nếu đổi lớp vẽ.
- [ ] Mỗi giai đoạn ít nhất một commit; báo cáo kèm ảnh trước/sau (điện thoại + iPad ngang).
