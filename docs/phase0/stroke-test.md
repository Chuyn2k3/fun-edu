# Thử bộ chấm nét với bé (giai đoạn 0)

Tài liệu này dành cho chủ dự án. Làm lần lượt từ phần 1 đến phần 6. Mục tiêu: kiểm tra xem app chấm nét có đủ tốt để bé dùng không.

## 1. Chuẩn bị máy và cài bản debug

Cần trên máy tính của bạn: Flutter SDK và (cho Android) Android SDK; (cho iPhone/iPad) Xcode.

**Android (điện thoại hoặc máy tính bảng)**
1. Trên thiết bị: Cài đặt > Giới thiệu > bấm 7 lần vào "Số bản dựng" để bật Tùy chọn nhà phát triển, rồi bật "Gỡ lỗi USB".
2. Cắm cáp USB, chọn "Cho phép" trên thiết bị khi được hỏi.
3. Kiểm tra máy được nhận: `flutter devices`.
4. Cài và chạy bản debug:
   ```
   cd app
   flutter run -d <mã-thiết-bị>
   ```
   Lặp lại với từng thiết bị (điện thoại, rồi máy tính bảng).

**iOS (iPhone/iPad)**: mở `app/ios/Runner.xcworkspace` bằng Xcode, chọn Team ký ứng dụng, cắm thiết bị rồi chạy `flutter run -d <mã-thiết-bị>`.

Chỉ bản debug mới có màn hình ghi nét `/dev/recorder`. Đừng dùng bản release cho việc này.

## 2. Ghi 9 nét mẫu bằng `/dev/recorder`

Cần ghi 9 glyph (đã có sẵn `net-ngang` và `net-thang-dung`):

| id | Nhãn gợi ý | Ghi chú |
|---|---|---|
| `net-xien` | Nét xiên | 1 nét |
| `net-cong` | Nét cong | 1 nét |
| `net-moc` | Nét móc | 1 nét |
| `so-0` | Số 0 | 1 nét |
| `so-1` | Số 1 | theo mẫu chữ trường tiểu học |
| `so-2` | Số 2 | |
| `so-3` | Số 3 | |
| `chu-a` | Chữ a | |
| `chu-b` | Chữ b | |

Cách ghi:
1. Mở màn hình ghi nét: trong bản debug đi tới đường dẫn `/dev/recorder` (từ trang chủ nếu có nút dẫn tới, hoặc đặt tuyến khởi đầu bằng `flutter run --route=/dev/recorder`).
2. Nhập ô **id** đúng như bảng trên (chữ thường, có gạch ngang) và ô **nhãn** (tên hiển thị cho bé).
3. Viết trên khung vẽ theo **mẫu chữ tiểu học**: đúng **thứ tự nét** và đúng **hướng** (điểm bắt đầu tới điểm kết thúc). Dùng **bút cảm ứng** nếu có, nét sẽ đều hơn ngón tay. Viết chậm, trơn, không run.
4. Nhấc tay là kết thúc một nét; glyph nhiều nét thì viết các nét lần lượt theo đúng thứ tự.
5. Viết sai thì bấm **Hoàn tác** (bỏ nét cuối) hoặc **Xóa** (làm lại từ đầu).
6. Bấm **Xuất**. JSON được chép vào clipboard **của điện thoại/máy tính bảng** và đồng thời in ra **terminal trên máy tính** đang chạy `flutter run`.
7. Đưa JSON về máy tính: mở cửa sổ terminal đang chạy `flutter run`, tìm đoạn JSON vừa in ra sau khi bấm Xuất (bắt đầu bằng `{"id": ...`), bôi đen và sao chép. Dán vào file `app/assets/glyphs/<id>.json` (ví dụ `app/assets/glyphs/so-2.json`) rồi lưu. Tên file phải trùng `id` trong JSON.
   Cách dự phòng nếu terminal không có JSON: trên thiết bị, dán (clipboard) vào một app ghi chú hoặc tin nhắn rồi gửi cho chính bạn, mở trên máy tính và sao chép vào file như trên.
8. Lặp lại cho đủ 9 glyph.

Kiểm tra: từ thư mục `app`, chạy `flutter test`. Bài test `test/stroke/assets_self_grade_test.dart` tự đọc mọi file trong `assets/glyphs/` và kiểm tra mỗi glyph chấm đúng chính nét mẫu của nó. Test đỏ nghĩa là file glyph đó có vấn đề (sai id, rỗng, hoặc nét ghi quá lạ), hãy ghi lại.

Sau khi thêm file glyph, phải **dừng hẳn app** (bấm `q` trong terminal `flutter run`, hoặc vuốt tắt app) rồi chạy lại `flutter run`. Hot reload/hot restart **không** nhận file asset mới. Khi đó trang chủ mới liệt kê đủ 9 glyph. Cuối cùng commit các file `.json`.

## 3. Kịch bản buổi thử

Chuẩn bị: sạc đầy máy, tắt thông báo, bật sáng màn hình, một bàn thấp, một người lớn ngồi cạnh. Mỗi buổi 10 đến 15 phút, bé mệt thì dừng.

Với **mỗi bé**:
1. Giới thiệu vui, không nói là "kiểm tra". Cho bé làm quen vài giây với việc chạm và kéo.
2. Bé lần lượt tô: 5 nét cơ bản (`net-ngang`, `net-thang-dung`, `net-xien`, `net-cong`, `net-moc`), số 0, 1, 2, 3, chữ a, chữ b. Mở từng glyph từ trang chủ.
3. Mỗi nét bé vẽ, người lớn **tự đánh giá theo mắt** ngay lúc đó: nét này có phải là nét đúng không (đúng thứ tự, đúng chiều, đủ dài, bám theo đường chấm)? Nét hơi xấu nhưng đúng thì tính là **đúng**.
4. Cùng lúc, nhìn app báo gì ("Đúng rồi!", "Vẽ dài thêm chút nữa nhé", "Bé vẽ ngược chiều rồi", "Đi theo đường chấm nhé", "Nét này vẽ sau nhé"). Ghi vào phiếu bên dưới.
5. Hết một glyph, app báo "Giỏi quá!". Cho bé bấm "Làm lại" nếu bé thích.
6. Đừng sửa nét hay chỉ cho bé trong lúc thử, để thấy cách bé tự vẽ.

Phiếu ghi nhanh (mỗi nét bé vẽ một dòng):

| Bé | Glyph | Nét số | Mắt người: đúng/sai | App: đúng/sai | Ghi chú (app báo gì) |
|---|---|---|---|---|---|
| | | | | | |

Cuối buổi, tính tổng vào bảng kết quả ở phần 4.

## 3b. Kiểm tra bắt lỗi (người lớn làm, không cần bé)

Bé sẽ không cố tình vẽ sai, nên tiêu chí "sai thứ tự hoặc sai chiều phải bị bắt" do **người lớn** kiểm tra. Với **mỗi glyph**, người lớn cố tình:
1. **Sai chiều**: vẽ một nét đúng đường nhưng ngược chiều (từ cuối về đầu). Mong đợi app báo "Bé vẽ ngược chiều rồi".
2. **Sai thứ tự** (chỉ với glyph từ 2 nét trở lên, như số 2, 3, chữ a, b nếu có nhiều nét): vẽ nét thứ 2 trước nét thứ 1. Mong đợi app báo "Nét này vẽ sau nhé".

Ghi kết quả (Bắt được / Lọt):

| Glyph | Số nét | Sai chiều: app bắt? | Sai thứ tự: app bắt? | Ghi chú |
|---|---|---|---|---|
| net-ngang | | | không áp dụng (1 nét) | |
| net-thang-dung | | | không áp dụng (1 nét) | |
| net-xien | | | không áp dụng (1 nét) | |
| net-cong | | | không áp dụng (1 nét) | |
| net-moc | | | không áp dụng (1 nét) | |
| so-0 | | | | |
| so-1 | | | | |
| so-2 | | | | |
| so-3 | | | | |
| chu-a | | | | |
| chu-b | | | | |

## 4. Bảng kết quả

Điền sau buổi thử. Các số tính theo **nét** (mỗi lần bé nhấc tay là một nét).

- "App chấm đúng": app báo đúng và người lớn cũng thấy đúng.
- "App chấm sai": nét người lớn thấy **sai** mà app cũng báo sai (app bắt đúng lỗi).
- "Người lớn thấy đúng nhưng app chấm sai": **lỗi cần sửa**, bé vẽ đúng mà app từ chối.
- Lỗi ngược (người lớn thấy sai nhưng app báo đúng) ghi chung vào cột Ghi chú.

| Glyph | Số nét | App chấm đúng | App chấm sai | Người lớn thấy đúng nhưng app chấm sai | Ghi chú |
|---|---|---|---|---|---|
| net-ngang | | | | | |
| net-thang-dung | | | | | |
| net-xien | | | | | |
| net-cong | | | | | |
| net-moc | | | | | |
| so-0 | | | | | |
| so-1 | | | | | |
| so-2 | | | | | |
| so-3 | | | | | |
| chu-a | | | | | |
| chu-b | | | | | |
| **Tổng** | | | | | |

Tỷ lệ chấm sai nét đúng = (tổng cột cuối) / (số nét người lớn thấy đúng) = ______ . Đạt khi dưới khoảng 1/10.

### Tiêu chí đạt (theo spec)
- Nét hơi xấu nhưng đúng thì được chấp nhận.
- Sai thứ tự nét hoặc sai chiều thì phải bị bắt: mọi dòng ở bảng phần 3b đều "Bắt được" (lọt dòng nào là chưa đạt).
- Tỷ lệ app chấm sai một nét đúng dưới khoảng 1/10.

Kết luận: [ ] Đạt   [ ] Chưa đạt, cần chỉnh ngưỡng (xem phần 6).

## 5. Tùy chọn: lấy nhật ký chấm từ máy Android

Bảng ghi tay ở phần 3 và 4 là bản ghi chính. Nếu muốn đối chiếu, app còn tự lưu mỗi nét đã chấm (glyph, thứ tự nét, đúng/sai, lỗi, độ lệch, giờ) vào CSDL cục bộ `funedu`. Với bản debug, `drift_flutter` đặt file trong thư mục tài liệu của app, trên Android là `/data/data/com.ibme.funedu/app_flutter/funedu.sqlite`.

Lấy về máy tính (cần `adb` và `sqlite3`):
```
adb exec-out run-as com.ibme.funedu cat app_flutter/funedu.sqlite > funedu.sqlite
```
Nếu có file `funedu.sqlite-wal`, lấy cả nó cạnh file trên (cùng cách, đổi tên file) trước khi mở.

Đếm số nét đúng/tổng theo glyph:
```
sqlite3 funedu.sqlite "SELECT glyph_id, SUM(ok) AS ok, COUNT(*) AS total FROM stroke_attempts GROUP BY glyph_id ORDER BY glyph_id;"
```
Xem các nét bị từ chối và lý do:
```
sqlite3 funedu.sqlite "SELECT glyph_id, stroke_index, error, ROUND(deviation,3) FROM stroke_attempts WHERE ok = 0 ORDER BY created_at;"
```
Lưu ý: số này gồm cả lần bé vẽ thử, làm lại; chỉ dùng để đối chiếu, không thay cho đánh giá của người lớn. Nếu tên cột khác, xem bằng `sqlite3 funedu.sqlite ".schema stroke_attempts"`.

## 6. Nếu không đạt: chỉnh ngưỡng nào

Các ngưỡng nằm trong `GradeConfig` (`app/lib/stroke/grader.dart`). Chỉ chỉnh ngưỡng, không đổi thuật toán.

| Triệu chứng | Ngưỡng chỉnh | Mặc định |
|---|---|---|
| Nét đúng nhưng lệch nhẹ vẫn bị "Đi theo đường chấm nhé" (trung bình) | tăng `tolerance` | 0.12 |
| Nét đúng, chỉ một đoạn ngắn run/vọt xa bị từ chối | tăng `maxPointDistance` | 0.25 |
| Nét hơi ngắn đã bị "Vẽ dài thêm chút nữa nhé" | giảm `minLengthRatio` | 0.6 |
| Nét đúng chiều bị báo ngược, hoặc nét ngược chiều lọt qua | `directionRatio`: tăng để dễ bắt ngược hơn, giảm để ít báo nhầm ngược hơn | 0.6 |
| Chấm (nét là một điểm) chấm gần đúng mà bị từ chối | tăng `dotRadius` | 0.1 |
| App cho qua nét sai (quá dễ) | làm ngược lại: giảm `tolerance` / `maxPointDistance`, tăng `minLengthRatio` | |

Mỗi lần chỉnh: tăng/giảm từng chút (khoảng 0.02 đến 0.03), chạy lại cùng nét trên máy, rồi:
1. Thêm một test tái hiện nét bé bị chấm sai (dựa theo các test trong `app/test/stroke/grader_test.dart`).
2. Chạy lại toàn bộ `flutter test` và `flutter analyze`.
3. Thử lại với bé và điền lại bảng kết quả.
