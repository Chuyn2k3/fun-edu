# Trò chơi "Chíp du lịch" + sắp lại Góc Chơi (thiết kế)

Ngày: 2026-11-25 · Nhánh: `chipchip` · Trạng thái: chờ chủ dự án duyệt

## 1. Ý định và lý do

Chủ dự án muốn **một trò chơi mới** trong Góc Chơi, và muốn **sắp lại chỗ hiển thị** để Góc Chơi chứa được nhiều trò. Hiện Góc Chơi chỉ có một trò là Đua tên lửa (một mình hoặc với bạn).

AI đề xuất các ý tưởng mới ngoài spec gốc; chủ dự án chọn **"Chíp du lịch"**:
- Chíp đi một **hành trình dài** qua các địa danh của đảo Địa lý.
- Mỗi lần chơi, Chíp đi tiếp từ chỗ lần trước dừng.
- Tới địa danh nào, bé nhận **bưu thiếp** địa danh đó, dán vào **sổ tem**.

Lý do chọn trò này:
- Nối Đảo Khám phá với Góc Chơi, dùng lại ảnh địa danh.
- Cho bé lý do quay lại chơi là sưu tầm đủ bưu thiếp.
- Nhịp nhẹ, khác hẳn đua tên lửa.

## 2. Mục tiêu / không làm / phản mục tiêu

**Mục tiêu**
- Bé 3–6 tuổi chơi được một mình, offline, khoảng 3–5 phút mỗi lần (10 câu).
- Hành trình kéo dài khoảng 7–10 lần chơi. Sổ tem đầy dần, và tiến độ không bao giờ mất, kể cả khi dùng hai máy.
- Góc Chơi có một **kệ trò chơi** chứa được thêm trò về sau mà không phải dựng lại bố cục.

**Không làm đợt này**
- Chơi với bạn qua mạng, chơi nhiều bé trên một máy.
- Hành trình có nhiều nhánh, chọn đường đi.
- Huy hiệu mới cho Chíp du lịch.
- Câu hỏi Địa lý trong trò: trò hỏi Toán và Tiếng Việt; Địa lý xuất hiện qua bưu thiếp.

**Phản mục tiêu**
- Bé bị lùi hoặc mất bưu thiếp; có "thua", có đếm giờ gây áp lực.
- Trò chơi như một bài kiểm tra (chữ nhiều, chờ lâu).
- Trò hiện ra với ảnh tạm hoặc chữ địa danh chưa duyệt.
- Góc Chơi bị tràn hoặc chật hơn trên điện thoại nhỏ.

## 3. Ràng buộc

- Các quy ước trong `AGENTS.md`. Đặc biệt:
  - dữ liệu trò chơi tách khỏi dữ liệu học; engine trò chơi không gọi mạng;
  - chỉ dùng Riverpod; màu chỉ lấy từ `tokens.dart` (`GameColors` cho cảnh chơi); ảnh chỉ qua `AppImages`;
  - nút bé ≥ 64 (tablet ≥ 80); tablet rẽ nhánh ngay trong file.
- Ảnh địa danh và câu kể dùng chung với Đảo Khám phá (`lib/explore/geography_level.dart`, `AppImages.geography`). Trò này **ẩn sau cùng công tắc** `exploreIslandEnabledProvider` (`EXPLORE_ISLAND`): khi công tắc tắt, Góc Chơi trông như hiện nay, chỉ có Đua tên lửa.
- Không đổi schema drift, không sửa máy chủ (cách A).

## 4. Các cách đã cân nhắc

Có ba cách lưu "Chíp đang ở đâu":

| Cách | Mô tả | Được / mất | Kết quả |
|---|---|---|---|
| **A** | Vị trí là một bộ đếm trong `game_counters`, khóa `trip.step`. Bưu thiếp suy ra từ vị trí. | Không đổi schema, không sửa máy chủ. Đồng bộ có sẵn: bộ đếm cộng dồn theo từng máy, nên chơi hai máy lúc offline thì bước cộng lại, chỉ đi tới. Đổi lại, khó làm hành trình nhiều nhánh về sau. | **Chủ dự án chọn** |
| B | Bảng drift riêng (vị trí + bưu thiếp kèm ngày) và loại bản ghi đồng bộ mới | Linh hoạt hơn, nhưng phải đổi schema, sửa máy chủ và test máy chủ; khoảng gấp đôi việc | Bỏ |
| C | Vị trí lưu trong `settings` | Nhanh nhất, nhưng khi đồng bộ thì bản sửa sau cùng thắng, có thể làm Chíp lùi và mất bưu thiếp | Bỏ |

Về trò chơi, các ý tưởng đã cân nhắc là Vẽ cầu cho Chíp, Hứng quả, Bắn bóng bay và các trò trong spec gốc. Chủ dự án chọn Chíp du lịch.

Hành trình **dài, lưu lại** (chủ dự án chọn), không chơi theo chặng ngắn.

## 5. Thiết kế

### 5.1 Hành trình

- **Các trạm** là 30 địa danh của đảo Địa lý cấp 4–9, theo đúng thứ tự trong `geographyLevels`: Hồ Gươm → … → Thác Niagara.
  - Không dùng mục của cấp 1–3 (cảnh vật, thời tiết, biểu tượng), vì đó không phải nơi để "đến".
  - Danh sách trạm lấy từ dữ liệu, không chép tay.
- Có **ô xuất phát** "Nhà Chíp" trước trạm 1.
- **4 bước giữa hai trạm.** Trạm thứ *k* (k = 1..30) ở bước `4k`; tổng cộng 120 bước.
- **Vị trí** = giá trị bộ đếm `trip.step`, kẹp trong 0..120.
- **Bưu thiếp đã có** = các trạm có bước ≤ vị trí.
- **Hết hành trình** (vị trí ≥ 120):
  - Chíp đứng ở đích và có màn "Hoàn thành chuyến du lịch!".
  - Bé vẫn chơi được: mỗi lần chơi vẫn nhận sao vũ trụ, nhưng Chíp không đi thêm.
  - *(Quyết định của người viết spec: đơn giản; vòng hai để sau.)*

### 5.2 Một lần chơi

- 10 câu, 3 lựa chọn, lấy bằng `buildRaceQuestions(...)` theo cấp hiện tại của bé.
  - Xen kẽ Toán và Tiếng Việt: câu chẵn Toán, câu lẻ Tiếng Việt.
  - Không có màn chọn môn: một chạm là chơi.
  - Không dùng sao chổi.
  - *(Quyết định của người viết spec.)*
- **Bước đi theo câu trả lời:**
  - Đúng ngay lần đầu: Chíp đi **2 bước**.
  - Sai rồi mới đúng: đi **1 bước**.
  - Chọn sai: ô rung, Chíp động viên, bé chọn lại. Không bao giờ lùi.
  - Một lần chơi đi tối đa 20 bước, nên mỗi lần qua được khoảng 3–5 trạm.
- **Tới trạm:**
  - Chíp dừng, bưu thiếp lật ra giữa màn, hiện ảnh địa danh và tên.
  - Chíp đọc `speech` rồi `fact` (thời gian chờ theo `geographyAnswerPause`).
  - Bé chạm "Đi tiếp" để sang câu sau.
- **Hết 10 câu:** màn tổng kết hiện các bưu thiếp mới nhận trong lần chơi và số sao vũ trụ nhận được. Có hai nút: "Chơi tiếp" và "Về Góc Chơi".
- **Sao vũ trụ** (dùng chung với đua tên lửa):
  - +1 cho mỗi câu đúng ngay lần đầu;
  - +2 cho mỗi bưu thiếp mới.
  - *(Quyết định của người viết spec: cùng tiền tệ với Xưởng độ; trò này không có phần thưởng riêng.)*
- **Bỏ ngang giữa chừng:** các bước đã đi vẫn được giữ. Mỗi câu đúng ghi bước ngay, không chờ hết lượt. Không mất gì.

### 5.3 Màn chơi `/game/travel`

```
┌─────────────────────────────────────┐
│ ‹   Chíp du lịch      📮 7/30   ⭐ 120│
│                                     │
│  ●─●─●─[Huế]─●─●─●─[Hội An]─●─●─…   │  ← bàn cờ cuộn ngang theo Chíp
│        🐤                            │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🔊 3 + 2 = ?                     │ │  ← bàn trả lời của đua tên lửa
│ │  [4]      [5]      [6]           │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Bàn cờ** vẽ bằng `CustomPainter`, giống cách vẽ cảnh đua:
- Nền giấy bản đồ màu kem.
- Đường đi nét đứt uốn lượn; các ô bước là chấm tròn.
- Trạm là con tem tròn có viền răng cưa, bên trong là ảnh `AppImages.geography[id]`.
  - Trạm chưa tới: tem mờ có dấu "?".
  - Trạm đã tới: tem rõ.
- Chíp là ảnh `AppImages.chipMain` (hoặc tư thế vui khi tới trạm), nhảy từng ô một (khoảng 250 ms mỗi bước).
- Bàn cờ tự cuộn để Chíp luôn trong khung, và thấy trước trạm kế tiếp.
- Chữ trên bàn cờ chỉ có tên trạm kế tiếp, cho ba mẹ đọc.

**Bố cục**
- Điện thoại dọc: bàn cờ ở trên (khoảng 45% chiều cao), bàn trả lời ở dưới.
- Tablet ngang: bàn cờ bên trái (khoảng 60%), bàn trả lời bên phải; giống tỉ lệ 60/40 của màn đua trên iPad ngang.

Bàn trả lời **dùng lại** widget của đua tên lửa, gồm phím, loa và chuyện rung khi chọn sai. Builder tách ra phần dùng chung nếu cần, nhưng không đổi hành vi của đua tên lửa.

### 5.4 Sổ tem `/game/postcards`

- Lưới 30 ô bưu thiếp (điện thoại 3 cột, tablet 5–6 cột), xếp theo thứ tự trạm. Có tiêu đề nhóm theo miền hoặc châu: Miền Bắc, Miền Trung, Miền Nam, Châu Á, Châu Âu & châu Phi, Châu Mỹ & châu Úc.
- Ô đã có: ảnh và tên. Chạm vào thì mở bưu thiếp to, Chíp đọc tên và câu kể.
- Ô chưa có: bóng mờ có "?". Chạm vào thì Chíp nói "Chíp chưa tới đây, mình đi tiếp nhé!".

### 5.5 Sắp lại Góc Chơi (kệ trò chơi)

**Khi công tắc tắt:** Góc Chơi giữ đúng như hiện nay. Không có thay đổi nào bé nhìn thấy.

**Khi công tắc bật:**
- Thẻ lớn "Đua tên lửa" (`_RaceHero`) thay bằng **kệ trò chơi**: hai thẻ to ngang nhau, "Đua tên lửa" và "Chíp du lịch".
  - Thẻ Chíp du lịch hiện số bưu thiếp `n/30` và ảnh trạm kế tiếp.
  - Chưa thêm thẻ "Sắp có" cho trò khác. *(Quyết định của người viết spec: không hứa trước.)*
- Kệ là một danh sách thẻ trò. Thêm trò về sau chỉ là thêm một thẻ; quá 2 trò thì xếp 2 cột nhiều hàng (điện thoại) hoặc một hàng (tablet ngang).
- Phần còn lại giữ nguyên thứ tự: Mời bạn đua / Nhập mã, Bạn bè, Xưởng độ.
- Hàng "Huy hiệu | Sticker" thành **"Huy hiệu | Sticker | Sổ tem"** (3 thẻ).

```
Điện thoại, công tắc bật
Chơi                          ⭐ 120
┌──────────────┐ ┌──────────────┐
│ 🚀           │ │ 🐤 📮        │
│ Đua tên lửa  │ │ Chíp du lịch │
│ Đua với Chíp │ │ 7/30 bưu thiếp│
└──────────────┘ └──────────────┘
[Mời bạn đua]   [Nhập mã]
Bạn bè …
[Xưởng độ tên lửa              ]
[Huy hiệu] [Sticker] [Sổ tem]
Thành tích …
```

Tablet dọc và tablet ngang làm theo cùng ý; builder canh lại kích thước để không tràn.

Phải giữ nguyên các test Góc Chơi hiện có khi công tắc tắt. Ảnh thẻ Chíp du lịch tạm dùng `AppImages.islandDiaLy`.

### 5.6 Dữ liệu

- `GameRepository`:
  - `Future<int> tripStep()`: đọc `trip.step`, kẹp trong 0..120.
  - `Future<TripAdvance> advanceTrip(int steps)`: tăng bộ đếm qua `_bumpCounter` (đồng bộ theo máy như các bộ đếm khác), không vượt 120. Kết quả trả về:
    - bước cũ và bước mới;
    - danh sách bưu thiếp mới;
    - số sao vũ trụ đã cộng (+2 cho mỗi bưu thiếp mới), cộng trong cùng transaction.
  - `Future<void> recordTripAnswer()`: +1 sao vũ trụ cho câu đúng ngay lần đầu. Builder có thể gộp vào `advanceTrip`.
- Danh sách trạm: `List<GeoItem> tripStops` lấy từ `geographyLevels.skip(3)`, đặt trong `lib/game/travel/` (engine thuần Dart, không gọi mạng).
- Lần chơi không lưu vào `race_results`; không ảnh hưởng thống kê và huy hiệu của đua tên lửa.
- Provider cho Góc Chơi: `tripProgressProvider` gồm vị trí, số bưu thiếp và trạm kế tiếp. Làm mới sau mỗi lần chơi và sau đồng bộ, giống cách làm mới `gameHubProvider` hiện nay.

### 5.7 Đường đi giữa các màn

`/game` → chạm thẻ Chíp du lịch → `/game/travel` → hết lượt thì màn tổng kết (trong cùng màn) → "Về Góc Chơi" (`/game`) hoặc "Chơi tiếp".

`/game` → chạm Sổ tem → `/game/postcards`.

Nút quay lại (và nút back hệ thống) giữa lượt thì về `/game`. Không hỏi lại, vì bước đã lưu.

### 5.8 Giọng đọc

- Câu hỏi: đọc như trong đua tên lửa (`spoken` của câu hỏi).
- Tới trạm: "Chíp tới ${speech} rồi! ${fact}".
- Hết hành trình: "Chíp đã đi khắp nơi rồi! Cảm ơn bạn nhỏ đã đi cùng Chíp!"

## 6. Kiểm thử

- **Engine:**
  - 30 trạm theo đúng thứ tự, trạm *k* ở bước 4k;
  - bưu thiếp suy ra từ vị trí; tối đa 120 bước;
  - đúng ngay lần đầu đi 2 bước, sai rồi đúng đi 1, sai không lùi;
  - mỗi lần chơi tối đa 20 bước;
  - câu hỏi xen kẽ Toán và Tiếng Việt, không có sao chổi.
- **Repository:**
  - `advanceTrip` cộng bộ đếm, trả đúng các bưu thiếp mới, cộng sao vũ trụ;
  - kẹp ở 120; bỏ ngang vẫn giữ bước;
  - hai máy cùng đi lúc offline rồi đồng bộ thì vị trí là tổng hai máy, kẹp ở 120.
- **Widget:**
  - màn chơi: trả lời và đi; tới trạm thì hiện bưu thiếp; tổng kết; quay lại giữa lượt;
  - sổ tem: ô đã có và ô chưa có;
  - Góc Chơi khi công tắc tắt: không đổi, các test cũ vẫn đạt;
  - Góc Chơi khi công tắc bật: kệ có 2 thẻ, sổ tem mở được;
  - không tràn ở 375×667, 390×844, iPad dọc và iPad ngang.
- Ảnh địa danh hỏng thì tem hiện ô màu kèm tên, giống màn học Địa lý.

## 7. Để lại cho người làm

- Tên class, cách chia file, cách tách bàn trả lời dùng chung.
- Hình dạng cụ thể của đường đi và màu bàn cờ (lấy từ `GameColors`, thêm token nếu cần).
- Hiệu ứng bưu thiếp lật, nhảy ô (giữ nhẹ, không blur).
- Kích thước kệ và thẻ trên từng loại màn hình.
