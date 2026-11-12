# Đại tu Fun Edu — bản tổng hợp kế hoạch (NHÁP)

> Trạng thái: **nháp tổng hợp từ cuộc trao đổi ngày 2026-11-12, chưa được duyệt.**
> Quy ước: **[Bạn]** = điều chủ dự án đã nói. **[Đoán]** = ý của Claude, chưa được đồng ý. **[Mở]** = còn chưa quyết.

## 1. Vì sao làm

App hiện tại (nhánh `develop` bản mobile, nhánh `new-web` bản web tại `hocvui.ibme.edu.vn`) đã có trên store nhưng:

- **[Bạn]** giao diện không thân thiện, chức năng ít, không độc đáo, lủng củng, chủ yếu làm để đối phó.
- **[Bạn]** muốn một bản mới hoàn toàn, hiệu quả hơn, tốt hơn. Chức năng không nhất thiết giống bản cũ.
- Thực trạng kỹ thuật (Claude quan sát): 5 cơ chế quản lý state trộn lẫn (Riverpod, Provider, Bloc, GetX, states_rebuilder), code chết và file trùng, mỗi tính năng là một khối rời, nội dung nằm cứng trong từng màn, hai nhánh mobile/web đã lệch nhau nhiều, `tflite` không chạy được trên web. File `env.g.dart` (khóa OpenAI) đang được commit, cần rà lại.
- Đối chiếu: StarJar Quiz (app cùng loại) được chủ dự án đánh giá là chức năng nhiều, UI dễ nhìn, đồng nhất. Điểm mạnh của nó: một ý tưởng xuyên suốt (sao vào hũ), linh vật, nội dung tách khỏi trò chơi, góc phụ huynh riêng, cộng đồng chia sẻ bộ câu hỏi, không quảng cáo.

## 2. Người dùng và mục tiêu

- **[Bạn]** Người dùng chính: trẻ tiền tiểu học. Claude hiểu là khoảng 3–6 tuổi **[Đoán]**.
- **[Bạn]** Có doanh thu từ gói premium.
- **[Bạn]** Muốn app đủ hấp dẫn để bé quay lại mỗi ngày, như một trò chơi, và có tính thi đua.

### Mục tiêu
1. Bé muốn mở app mỗi ngày, có vòng thưởng hằng ngày và phòng thi đua.
2. Giao diện đồng nhất, thân thiện, ít chữ, dùng được khi chưa biết đọc.
3. Nội dung và trò chơi tách rời: một kho câu hỏi dùng chung cho mọi trò chơi **[Đoán]**.
4. Ba mẹ có khu riêng để theo dõi và kiểm soát.

### Không phải mục tiêu / điều tránh
- **[Bạn]** Không có quảng cáo.
- **[Đoán]** Không chat tự do, không hiện tên thật, không thu thông tin cá nhân của bé. Không dùng cơ chế gây nghiện quá tay (mất chuỗi ngày gây áp lực, tiền ảo).
- **[Đoán]** Không làm bản "chơi hết mình rồi trả tiền để thắng": gói tháng chỉ mở thêm thời gian, không bán lợi thế.

## 3. Ý tưởng sản phẩm

- **[Bạn]** Có phòng thi đua cho hai hoặc nhiều bé, cả hai trường hợp: ngồi cùng một chỗ (có thể chung một thiết bị) và ở nhà khác nhau chơi qua mạng. Chơi xong thì được chơi tiếp.
- **[Đoán]** Hai trường hợp dùng chung một luật chơi và một bộ câu hỏi, chỉ khác cách vào phòng. Bé ở xa vào bằng mã ngắn do ba mẹ tạo, chỉ có biểu tượng cảm xúc có sẵn, không có chat gõ chữ.
- **[Đoán]** Có thêm kiểu hợp tác ("cả phòng gom đủ sao") bên cạnh đối kháng, để bé thua không khóc. Người thua vẫn nhận phần thưởng nhỏ.
- **[Đoán]** Vòng thưởng hằng ngày: một linh vật đồng hành, nhiệm vụ ngắn, sao hoặc phần thưởng ba mẹ đặt.

## 4. Thời gian chơi và tiền

- **[Bạn]** Giới hạn tối đa **180 phút/ngày**.
- **[Bạn]** Phòng thi đấu: bản miễn phí chỉ **30 phút/ngày**. Muốn hơn thì ba mẹ mua gói **1 tháng**, được tối đa **90 phút/ngày** cho thi đấu.
- **[Đoán]** 180 phút là trần cho cả app. Phần học và chơi một mình miễn phí, chỉ thi đấu bị tính giờ riêng. Cần xác nhận.
- **[Đoán]** Mặc định ba mẹ đặt giới hạn thấp hơn nhiều so với 180 phút (khuyến nghị y tế cho lứa tuổi này khoảng 1 giờ/ngày), 180 chỉ là mức trần tối đa.
- **[Đoán]** Chỉ ba mẹ mua được, qua cổng xác nhận người lớn.
- Ràng buộc: trên iOS/Android, gói tháng phải mua qua Apple và Google (họ giữ khoảng 15–30%), không dùng được thanh toán riêng. Cần tính vào giá.

## 5. Tài khoản và vai trò

- **[Bạn]** Một web, ba mẹ đăng nhập theo vai trò thì thấy giao diện khác giao diện của bé.
- **[Bạn đồng ý]** Tài khoản gia đình do ba mẹ đăng ký. Bé không có tài khoản riêng và không có mật khẩu, chỉ chạm vào hồ sơ của mình (tên gọi ở nhà + hình đại diện). Vào góc ba mẹ phải qua cổng xác nhận người lớn.
- **[Mở]** Vai trò thầy cô (tạo lớp, giao bài) có cần ở giai đoạn đầu không. Hiện coi như để sau.

## 6. Nội dung

- **[Bạn]** Chưa biết nội dung gì, muốn backend tự tạo.
- **[Đoán]** Backend dùng AI sinh bộ câu hỏi theo lô và lưu thành bản nháp, không sinh ngay khi bé đang chơi. Người duyệt trên trang quản trị trước khi đăng, vì với trẻ nhỏ sai kiến thức hay hình không phù hợp là lỗi nặng.
- **[Bạn đồng ý]** Lúc ra mắt chỉ gồm 3 môn: **Toán, Tiếng Việt (chữ cái), Tiếng Anh (từ vựng cơ bản)**, cho bé 3–6 tuổi. Mở rộng sau.
- **[Đoán]** Cộng đồng chia sẻ bộ câu hỏi (kiểu StarJar) là chức năng sau.

## 7. Công nghệ

| Phần | Chọn | Nguồn |
|---|---|---|
| App di động | Flutter, giữ để cập nhật bản đang có trên store | **[Bạn]** |
| Chuyển native nếu mượt hơn | Chỉ khi có chỗ giật thật sự, xử lý riêng chỗ đó | **[Đoán]** Claude khuyên chưa chuyển vì phải viết hai lần |
| Web | Bỏ Flutter web, dùng React hoặc Angular | **[Bạn]** |
| React hay Angular | React (nhiều thư viện, dễ tìm người), nhưng dùng Angular nếu bạn quen hơn | **[Đoán]** |
| Backend | Java, viết mới | **[Bạn]** |
| Framework và thời gian thực | Spring Boot, WebSocket cho phòng chơi | **[Đoán]** |
| Hạ tầng | Máy chủ Oracle 24GB RAM, 100GB SSD đã có | **[Bạn]** |

Cần lưu ý với Oracle free: máy có thể bị thu hồi nếu quá rảnh, và một máy là điểm chết duy nhất, nên phải có sao lưu ra chỗ khác **[Đoán]**.

## 8. Chia dự án và thứ tự (đề xuất, chưa được xác nhận)

Đây là bốn dự án độc lập, mỗi dự án sẽ có bản thiết kế và kế hoạch riêng:

1. **Backend (Java):** tài khoản gia đình, hồ sơ bé, kho câu hỏi, giới hạn giờ, phòng thi đấu thời gian thực, gói tháng.
2. **App di động (Flutter):** giao diện bé, góc ba mẹ, trò chơi.
3. **Web (React/Angular):** giao diện ba mẹ và trang bé chơi.
4. **Công cụ tạo và duyệt nội dung.**

Thứ tự đề xuất **[Đoán]**:
- Bước 1: backend lõi + app di động bản nhỏ nhất chơi được (tài khoản gia đình, hồ sơ bé, môn Toán, một trò chơi, vòng thưởng sao hằng ngày, cổng ba mẹ).
- Bước 2: công cụ tạo nội dung, thêm Tiếng Việt và Tiếng Anh.
- Bước 3: phòng thi đấu và gói tháng.
- Bước 4: bản web.

## 9. Việc còn mở

1. **[Mở]** Có đồng ý chia và xếp thứ tự như mục 8 không?
2. **[Mở]** Xác nhận cách hiểu mốc 180 phút so với 30/90 phút.
3. **[Mở]** Chọn React hay Angular.
4. **[Mở]** Phong cách hình ảnh và linh vật (chưa bàn kỹ; bản phác hai giao diện bé/ba mẹ mới chỉ để bàn bố cục).
5. **[Mở]** Những phần nào của app cũ còn giữ (ví dụ game Dino Run, Sweep, nhận diện số viết tay) và những phần nào bỏ.
6. **[Mở]** Giá gói tháng, và việc bạn có chịu phí 15–30% của store.
7. **[Mở]** Ai duyệt nội dung AI sinh ra.
8. **[Mở]** Cách đo thành công (số bé quay lại mỗi ngày, số gói bán được...).
9. **[Mở]** Rà lại khóa OpenAI đã bị commit trong `env.g.dart`.
10. **[Mở]** Chiến lược cho app đang có trên store: cập nhật lên cùng gói hay đăng mới, và dữ liệu người dùng cũ xử lý ra sao.

## 10. Chưa làm

Chưa có mã nguồn mới, chưa dựng dự án nào. Bản này chưa được rà soát bởi người xây thử (bước kiểm tra "builder check" của quy trình), và sẽ chỉ làm khi bản thiết kế chính thức được bạn duyệt.
