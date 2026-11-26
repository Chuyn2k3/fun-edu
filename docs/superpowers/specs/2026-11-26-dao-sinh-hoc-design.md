# Đảo Sinh học "Khám phá sự sống" + khung đảo dùng chung (thiết kế)

Ngày: 2026-11-26 · Nhánh: `chipchip` · Trạng thái: chờ chủ dự án duyệt (đã qua rà soát)

## 1. Ý định và lý do

Chủ dự án muốn mở đảo thứ hai trên Đảo Khám phá: **Sinh học**, dùng lại cách làm của Địa lý. Cụ thể là:
- bản đồ 9 cấp, mỗi lượt 5 câu, chọn 1 trong 3 ảnh 3D đồ chơi;
- Chíp đọc câu kể sau khi bé trả lời đúng;
- cấp đồng bộ giữa các máy và hiện trong Góc ba mẹ;
- nằm sau công tắc `EXPLORE_ISLAND`.

Chủ dự án chọn thêm hai điều:
- **dạng câu ghép đôi** (nhìn một ảnh, chọn ảnh hợp với nó) cho các cấp "con gì ăn gì" và "lớn lên thế nào";
- **cách A**: biến khung Địa lý thành **khung chung cho mọi đảo**. Lịch sử về sau chỉ cần thêm nội dung và ảnh.

Môn Tiếng Anh đã có cấp "Con vật" và "Gia đình & Cơ thể". Sinh học không dạy lại tên gọi, mà dạy **con vật sống ở đâu, ăn gì, lớn lên thế nào; cây lớn ra sao; bộ phận cơ thể dùng để làm gì**.

## 2. Mục tiêu / không làm / phản mục tiêu

**Mục tiêu**
- Một khung đảo dùng chung gồm màn học, bản đồ, màn luyện, thẻ Góc ba mẹ và sảnh. Thêm một đảo chỉ là thêm một khai báo, nội dung và ảnh.
- Địa lý chạy trên khung mới **y như hiện nay**: cùng đường dẫn, cùng khóa lưu `'dia-ly'`, và các test Địa lý hiện có vẫn đạt.
- Đảo Sinh học 9 cấp, khóa lưu `'sinh-hoc'`.
- Dạng câu ghép đôi dùng được cho mọi đảo.

**Không làm**
- Lịch sử: thẻ trong sảnh vẫn hiện "Sắp có".
- Không đưa Sinh học vào Bài hôm nay, trận đua, Chíp du lịch hay Sưu tập.
- Không làm bài xếp cấp lần đầu: bé bắt đầu từ cấp 1.

**Phản mục tiêu**
- Địa lý đổi hành vi hoặc mất tiến độ sau khi chuyển sang khung mới.
- Câu kể sai sự thật, đáng sợ (thú ăn thịt, săn mồi, chết), hoặc nhắc tên đáp án.
- Câu hỏi đòi bé phải biết đọc chữ.
- Ảnh tạm hoặc chữ chưa duyệt lọt tới tay bé.

## 3. Ràng buộc

- Mọi quy ước trong `AGENTS.md`, như với Địa lý. Riêng màu `Subject.sinhHoc` phải khác các môn đang có, chữ trắng trên màu chính đạt tương phản ≥ 4.5:1. Gợi ý: xanh lá ngả vàng đậm hoặc xanh rêu, khác `tiengAnh` `#0F8A5F`.
- Không đổi schema drift. Cấp lưu trong `subject_levels`; đồng bộ đã chạy chung cho mọi khóa môn, máy chủ không phải sửa.
- Câu kể theo cùng luật với Địa lý:
  - tối đa 15 từ, không chữ số, không nhắc tên đáp án;
  - thêm cho Sinh học: không có chuyện săn mồi, ăn thịt, chết hay bị thương.
- Ảnh 3D đồ chơi trên nền xanh lá, tách nền bằng `chroma_key.py`, nằm trong `assets/images/explore/`, không nạp sẵn lúc mở app. Ảnh có con vật hoặc cây màu xanh lá thì dùng xanh lá ngả vàng hoặc xanh rêu, để không trùng màu nền.
- Thời gian chờ sau câu đúng theo `SpeechWait`: Chíp nói xong mới sang câu kế.

## 4. Các cách đã cân nhắc

| Cách | Mô tả | Được / mất | Kết quả |
|---|---|---|---|
| **A** | Biến khung Địa lý thành khung chung cho mọi đảo; Địa lý và Sinh học là hai khai báo | Một bản code, sửa lỗi một nơi, Lịch sử về sau rẻ; đổi lại phải sửa phần Địa lý vừa làm | **Chủ dự án chọn** |
| B | Chép bộ file Địa lý thành bộ Sinh học | Nhanh lần này; nhưng có hai bản code gần giống nhau, đến Lịch sử thành ba | Bỏ |

Dạng câu: **thêm dạng ghép đôi** (chủ dự án chọn). Phương án giữ đúng hai dạng cũ bị bỏ, vì khi đó cấp 5–6 chỉ còn là nhận mặt con vật và đồ ăn.

## 5. Thiết kế

### 5.1 Khung đảo chung

- **Một khai báo đảo** gồm:
  - `id`: dùng làm khóa lưu và trong đường dẫn: `'dia-ly'`, `'sinh-hoc'`;
  - tên đảo trong sảnh ("Địa lý", "Sinh học");
  - tên bản đồ ("Khám phá Việt Nam", "Khám phá sự sống");
  - màu (`Subject`), ảnh đảo trong sảnh, danh sách cấp.
- **Danh sách đảo** dùng cho sảnh, thẻ Góc ba mẹ và thẻ trang chủ: `[địa lý, sinh học]`. Lịch sử thêm vào sau.
- **Mỗi đảo có cờ `ready` riêng** trong khai báo (hằng số trong code). Địa lý `ready = true`; Sinh học `ready = false` cho tới khi chủ dự án duyệt chữ và có ảnh thật. Công tắc `EXPLORE_ISLAND` vẫn bật/tắt cả Đảo Khám phá. Khi bật, chỉ đảo `ready` mới:
  - mở được từ sảnh (đảo chưa `ready` hiện "Sắp có" như Lịch sử);
  - có thẻ trong Góc ba mẹ;
  - được tính vào vòng tiến độ trên trang chủ.

  Nhờ vậy bật Đảo Khám phá cho Địa lý không làm lộ ảnh tạm hay chữ chưa duyệt của Sinh học. Test bật cờ `ready` qua một provider, giống `exploreIslandEnabledProvider`. *(Quyết định của người viết spec.)*
- **Mục** (hiện là `GeoItem`): `id`, `name`, `speech`, `fact`, `clue`, ảnh.
  - Ảnh tra theo đường dẫn `assets/images/explore/<tiền tố đảo>-<id>.png`: Địa lý giữ nguyên `geo-`, Sinh học dùng `bio-`.
  - Trò Chíp du lịch vẫn dùng mục Địa lý như cũ.
- **Mục ghép đôi** (mới), dùng cho cấp có dạng ghép đôi:
  - một ảnh **đề** (thỏ, quả trứng) và một ảnh **đáp** (cà rốt, gà con), mỗi ảnh có `name`/`speech`;
  - một câu hỏi (`'Thỏ thích ăn gì?'`, đọc bằng `speech` riêng nếu tên nước ngoài) và một câu kể;
  - lựa chọn sai là ảnh **đáp** của các mục ghép đôi khác trong cùng cấp, **trừ những ảnh cũng đúng**. Mỗi mục ghép đôi có danh sách `alsoRight` (id ảnh đáp không bao giờ được đưa ra làm lựa chọn sai). Ví dụ thỏ cũng ăn cỏ, nên "Thỏ thích ăn gì?" không bao giờ có cỏ trong lựa chọn; bò cũng ăn cà rốt, nên "Bò thích ăn gì?" không có cà rốt. Mỗi câu vẫn phải còn đủ 2 lựa chọn sai, có test kiểm. *(Quyết định của người viết spec.)*
- **Dạng câu** của mỗi cấp, một trong ba:
  - `pickImage` + `listenClue` như Địa lý (cấp 1–3 chỉ `pickImage`, cấp sau trộn);
  - **chỉ `pairPick`**: cấp ghép đôi.
- **Màn ghép đôi:**
  - ảnh đề to ở giữa (≥ 160 trên điện thoại, ≥ 220 trên tablet), Chíp đọc câu hỏi;
  - bên dưới là 3 ảnh đáp, cùng kiểu thẻ và kích thước tối thiểu như hiện nay;
  - chọn đúng thì Chíp đọc `'${đáp.speech}! ${fact}'`.
- **Đường dẫn:**
  - `/kham-pha` (sảnh), `/subject/<id>` (bản đồ), `/practice-<id>/:levelIndex` (màn luyện);
  - Địa lý giữ nguyên `/subject/dia-ly` và `/practice-dia-ly/:i`;
  - Sinh học là `/subject/sinh-hoc` và `/practice-sinh-hoc/:i`.
- **Sảnh:** thẻ Sinh học mở bản đồ Sinh học; Lịch sử vẫn "Sắp có".
- **Thẻ trang chủ "Đảo Khám phá":** vòng tiến độ là **tổng số cấp đã mở của các đảo `ready`** trên tổng số cấp của các đảo đó. Ví dụ chỉ Địa lý `ready`, đang cấp 4: `4/9` (như hiện nay). Cả hai `ready`, Địa lý cấp 4, Sinh học cấp 2: `6/18`. *(Quyết định của người viết spec: một con số cho cả đảo; thêm Lịch sử thì tự thành `/27`.)*
- **Góc ba mẹ:** mỗi đảo một thẻ ("Địa lý", "Sinh học"), hiện cùng điều kiện công tắc như hiện nay.
- **Provider:** cấp của từng đảo đọc theo khóa, kẹp trong số cấp của đảo đó. `geographyLevelIndexProvider` giữ tên (hoặc thành alias) để code và test cũ vẫn chạy.

### 5.2 Nội dung Sinh học — "Khám phá sự sống"

| # | id | Tiêu đề | Dạng | Mục |
|---|---|---|---|---|
| 1 | `vat-nuoi` | Con vật trong nhà | chọn ảnh | chó, mèo, gà, vịt, lợn, trâu |
| 2 | `trong-rung` | Con vật trong rừng | chọn ảnh | voi, hổ, khỉ, gấu, hươu cao cổ |
| 3 | `duoi-nuoc` | Dưới nước | chọn ảnh | cá, cua, tôm, cá heo, rùa biển |
| 4 | `bau-troi` | Trên bầu trời | chọn ảnh + đố | chim sẻ, bướm, ong, chuồn chuồn, cò |
| 5 | `an-gi` | Con gì ăn gì? | ghép đôi | thỏ → cà rốt, khỉ → chuối, mèo → cá, bò → cỏ, ong → hoa |
| 6 | `lon-len` | Lớn lên thế nào? | ghép đôi | trứng → gà con, nòng nọc → ếch, sâu → bướm, hạt → cây mầm, bê con → bò |
| 7 | `cay-hoa` | Cây và hoa | chọn ảnh + đố | rễ cây, lá cây, hoa, quả, hạt |
| 8 | `rau-qua` | Rau củ quả | chọn ảnh + đố | cà rốt, bắp cải, cà chua, xoài, dưa hấu, bí ngô |
| 9 | `co-the` | Cơ thể em làm gì? | chọn ảnh + đố | mắt (nhìn), tai (nghe), mũi (ngửi), miệng (ăn, nói), tay (cầm), chân (đi) |

Ghi chú về nội dung:
- **Cấp 9** dạy công dụng, khác cấp Tiếng Anh vốn dạy tên:
  - câu đố dạng "Bộ phận giúp em nghe tiếng chim hót";
  - câu "Đâu là cái mũi?" vẫn có cho bé nhỏ;
  - ảnh vẽ một bộ phận trên mặt hoặc thân một búp bê đồ chơi tròn, không vẽ người thật.
- **Cấp 5:** `mèo → cá` là cá nấu sẵn trong đĩa, không vẽ cá sống bị ăn. `bò → cỏ` dùng ảnh bó cỏ.
- Ảnh mới, khoảng **57 cái**: 6 + 5 + 5 + 5 + 10 (5 cặp) + 10 (5 cặp) + 5 + 6 + 6, cộng 1 ảnh đảo Sinh học (thay ảnh tạm `island-sinh-hoc`).
  - Chỉ dùng chung ảnh khi cùng một vật và cùng nghĩa: cà rốt ở cấp 5 và cấp 8 dùng chung một ảnh; bướm ở cấp 4 và cấp 6 dùng chung. Builder ghi rõ cặp nào dùng chung.
- **Toàn bộ chữ** phải được chủ dự án duyệt trong một bảng duyệt mới `docs/superpowers/specs/assets/sinh-hoc-noi-dung.md`, giống bảng Địa lý.

### 5.3 Ảnh và câu lệnh

- Thêm vào `docs/phase0/asset-list.md` mục "Đảo Sinh học": dùng chung đoạn phong cách của Đảo Khám phá, mỗi ảnh một dòng mô tả.
- Con vật vẽ hiền, đứng một mình, không có cảnh săn mồi.
- Ảnh tạm sinh bằng `make_placeholders.py` (thêm các mục `bio-`), không bao giờ ghi đè ảnh thật.

## 6. Kiểm thử

- **Địa lý:**
  - mọi test hiện có vẫn đạt;
  - test đồng bộ và lưu cấp `'dia-ly'` không đổi;
  - đường dẫn cũ vẫn mở đúng màn.
- **Khung chung:**
  - thêm đảo thử nghiệm trong test thì sảnh, bản đồ và màn luyện chạy được;
  - cấp lưu vượt số cấp thì bị kẹp lại.
- **Dạng ghép đôi:**
  - 3 lựa chọn khác nhau, đáp án nằm trong số đó;
  - lựa chọn sai lấy từ ảnh đáp của các mục khác cùng cấp, không bao giờ là ảnh trong `alsoRight`;
  - không lặp đáp án trong 5 câu khi cấp có đủ mục;
  - câu đọc đúng; Chíp chờ nói xong mới sang câu kế.
- **Nội dung Sinh học:**
  - có 9 cấp; mỗi mục có ảnh và đủ chữ; câu kể ≤ 15 từ, không chữ số, không nhắc tên đáp án;
  - không có các từ cấm: "ăn thịt", "săn", "chết", "máu".
- **Thẻ trang chủ:** hiện tổng cấp của các đảo `ready`, kẹp đúng.
- **Cờ `ready`:** Sinh học chưa `ready` thì sảnh hiện "Sắp có", không có thẻ Góc ba mẹ, trang chủ vẫn `n/9`.
- **Thẻ Góc ba mẹ:** Sinh học hiện khi bật công tắc.
- **Bố cục:** không tràn ở 375×667 (chữ ×2.0), 390×844, iPad dọc và iPad ngang, cho cả màn ghép đôi.

## 7. Để lại cho người làm

- Tên class, tên file, cách chuyển Địa lý sang khung mới (đổi tên `GeoItem` hay giữ alias).
- Màu cụ thể của `Subject.sinhHoc`, trong giới hạn tương phản.
- Câu chữ của 47 mục và 10 cặp ghép đôi, theo luật ở §3; chủ dự án duyệt sau.
- Cách chia gói câu hỏi ghép đôi (có cần cờ riêng cho mỗi cấp hay không).
