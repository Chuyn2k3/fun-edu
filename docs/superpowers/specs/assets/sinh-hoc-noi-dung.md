# Đảo Sinh học — bảng duyệt chữ

Chủ dự án đọc từng dòng, sửa nếu cần (báo lại để AI cập nhật `lib/explore/biology_level.dart`), rồi đánh `x` vào cột **Duyệt**. Chỉ khi duyệt hết và có ảnh thật mới đổi `ready` của Sinh học thành `true`.

- Câu kể: Chíp đọc sau khi bé chọn đúng (≤ 15 từ, không chữ số, không nhắc tên đáp án, không săn mồi/ăn thịt/chết/máu).
- Gợi ý: câu đố cho dạng "nghe kể rồi chọn" (cấp 4, 7, 8, 9).
- Ghép đôi (cấp 5–6): bé nhìn ảnh đề, chọn ảnh đáp. Cột "Cũng đúng" là ảnh không bao giờ được đưa ra làm lựa chọn sai.

Bảng sinh từ code; sửa code thì sinh lại.

## Chọn ảnh / nghe đố

| Cấp | id | Tên | Câu kể | Gợi ý | Duyệt |
|---|---|---|---|---|---|
| Con vật trong nhà | `cho` | Chó | Biết giữ nhà, vẫy đuôi mừng khi em về. | Con vật biết giữ nhà. |  |
| Con vật trong nhà | `meo` | Mèo | Kêu meo meo, thích nằm sưởi nắng. | Con vật hay rửa mặt bằng chân. |  |
| Con vật trong nhà | `ga` | Gà | Gáy ò ó o mỗi sáng gọi mọi người dậy. | Con vật gáy mỗi sáng. |  |
| Con vật trong nhà | `vit` | Vịt | Bơi giỏi dưới ao, kêu cạp cạp. | Con vật bơi dưới ao, kêu cạp cạp. |  |
| Con vật trong nhà | `lon` | Lợn | Kêu ụt ịt, thích ăn no rồi ngủ. | Con vật kêu ụt ịt. |  |
| Con vật trong nhà | `trau` | Trâu | Giúp bác nông dân cày ruộng. | Con vật có sừng cong, giúp cày ruộng. |  |
| Con vật hoang dã | `voi` | Voi | Có cái vòi thật dài và đôi tai to. | Con vật to lớn có vòi dài. |  |
| Con vật hoang dã | `ho` | Hổ | Lông vàng có sọc đen, là chúa sơn lâm. | Con vật lông vàng sọc đen. |  |
| Con vật hoang dã | `khi` | Khỉ | Leo trèo thật giỏi, thích đu cành cây. | Con vật leo cây giỏi nhất rừng. |  |
| Con vật hoang dã | `gau` | Gấu | Lông dày, rất thích mật ong. | Con vật lông dày, thích mật ong. |  |
| Con vật hoang dã | `huou-cao-co` | Hươu cao cổ | Cổ thật dài, ăn lá trên ngọn cây. | Con vật cổ dài nhất rừng. |  |
| Dưới nước | `ca` | Cá | Bơi bằng vây và đuôi, thở dưới nước. | Con vật bơi bằng vây. |  |
| Dưới nước | `cua` | Cua | Có hai cái càng, bò ngang trên cát. | Con vật bò ngang, có hai càng. |  |
| Dưới nước | `tom` | Tôm | Có râu dài, bơi lùi rất nhanh. | Con vật có râu dài, bơi lùi. |  |
| Dưới nước | `ca-heo` | Cá heo | Rất thông minh, thích nhảy lên khỏi mặt nước. | Con vật thông minh, thích nhảy khỏi mặt nước. |  |
| Dưới nước | `rua-bien` | Rùa biển | Mang mai cứng, bơi chậm rãi khắp đại dương. | Con vật mang mai, bơi ngoài khơi. |  |
| Trên bầu trời | `chim-se` | Chim sẻ | Nhỏ xíu, nhảy lách chách trên cành cây. | Con chim nhỏ hay nhảy trên cành. |  |
| Trên bầu trời | `buom` | Bướm | Có đôi cánh nhiều màu sặc sỡ. | Con vật có đôi cánh nhiều màu. |  |
| Trên bầu trời | `ong` | Ong | Bay vo ve, làm ra mật thật ngọt. | Con vật bay vo ve, làm ra mật. |  |
| Trên bầu trời | `chuon-chuon` | Chuồn chuồn | Mắt to tròn, đuôi dài, bay lượn trên mặt ao. | Con vật mắt to, đuôi dài, hay bay trên mặt ao. |  |
| Trên bầu trời | `co` | Cò | Chân dài, lội ruộng lúa tìm thức ăn. | Con chim chân dài, lông trắng muốt. |  |
| Cây và hoa | `re-cay` | Rễ cây | Nằm dưới đất, hút nước nuôi cả cái cây. | Phần của cây nằm dưới đất. |  |
| Cây và hoa | `la-cay` | Lá cây | Màu xanh, đón nắng giúp cây khỏe mạnh. | Phần màu xanh, đón ánh nắng. |  |
| Cây và hoa | `hoa` | Hoa | Nở thật đẹp, có mùi thơm, ong bướm rất thích. | Phần đẹp nhất của cây, có mùi thơm. |  |
| Cây và hoa | `qua` | Quả | Lớn lên từ bông hoa, bên trong có hạt. | Phần ăn được, mọc ra sau khi hoa tàn. |  |
| Cây và hoa | `hat` | Hạt | Gieo xuống đất, tưới nước là nảy mầm. | Nhỏ xíu, gieo xuống đất sẽ mọc cây. |  |
| Rau củ quả | `ca-rot` | Cà rốt | Củ màu cam, ăn giòn ngọt, tốt cho mắt. | Củ màu cam, thỏ rất thích gặm. |  |
| Rau củ quả | `bap-cai` | Bắp cải | Nhiều lá cuộn tròn, nấu canh rất ngon. | Rau có nhiều lá cuộn tròn. |  |
| Rau củ quả | `ca-chua` | Cà chua | Đỏ mọng, nấu canh chua thật ngon. | Quả đỏ mọng, dùng nấu canh. |  |
| Rau củ quả | `xoai` | Xoài | Chín vàng, thơm và ngọt lịm. | Quả chín vàng, thơm ngọt. |  |
| Rau củ quả | `dua-hau` | Dưa hấu | Vỏ xanh, ruột đỏ, ăn mát lạnh ngày hè. | Quả vỏ xanh, ruột đỏ. |  |
| Rau củ quả | `bi-ngo` | Bí ngô | To tròn màu cam, nấu canh rất bổ. | Quả to tròn màu cam. |  |
| Cơ thể em làm gì? | `mat` | Mắt | Giúp em nhìn thấy mọi thứ xung quanh. | Bộ phận giúp em nhìn. |  |
| Cơ thể em làm gì? | `tai` | Tai | Giúp em nghe tiếng chim hót, tiếng mẹ gọi. | Bộ phận giúp em nghe tiếng chim hót. |  |
| Cơ thể em làm gì? | `mui` | Mũi | Giúp em ngửi thấy mùi hoa thơm. | Bộ phận giúp em ngửi mùi thơm. |  |
| Cơ thể em làm gì? | `mieng` | Miệng | Giúp em ăn cơm và nói chuyện. | Bộ phận giúp em ăn và nói. |  |
| Cơ thể em làm gì? | `tay` | Bàn tay | Giúp em cầm bút, vẽ tranh, vỗ tay. | Bộ phận giúp em cầm bút. |  |
| Cơ thể em làm gì? | `chan` | Bàn chân | Giúp em đi, chạy và nhảy thật xa. | Bộ phận giúp em đi và chạy. |  |

## Ghép đôi

| Cấp | Câu hỏi | Ảnh đề | Ảnh đáp | Câu kể | Cũng đúng | Duyệt |
|---|---|---|---|---|---|---|
| Con gì ăn gì? | Thỏ thích ăn gì? | Thỏ (`tho`) | Cà rốt (`ca-rot`) | Thỏ gặm thật giòn bằng hai chiếc răng cửa. | bo-co |  |
| Con gì ăn gì? | Khỉ thích ăn gì? | Khỉ (`khi`) | Chuối (`chuoi`) | Khỉ bóc lớp vỏ vàng rồi mới ăn. |  |  |
| Con gì ăn gì? | Mèo thích ăn gì? | Mèo (`meo`) | Đĩa cá (`dia-ca`) | Mèo rất thích món này, ăn xong lại rửa mặt. |  |  |
| Con gì ăn gì? | Bò thích ăn gì? | Bò (`bo`) | Bó cỏ (`bo-co`) | Bò nhai thật lâu, nhai cả ngày trên cánh đồng. | ca-rot |  |
| Con gì ăn gì? | Ong bay đến đâu để lấy mật? | Ong (`ong`) | Hoa (`hoa`) | Ong hút mật ngọt rồi bay về tổ. |  |  |
| Lớn lên thế nào? | Quả trứng nở ra con gì? | Quả trứng (`trung`) | Gà con (`ga-con`) | Mẹ gà ấp trứng thật lâu, rồi con non mổ vỏ chui ra. |  |  |
| Lớn lên thế nào? | Nòng nọc lớn lên thành con gì? | Nòng nọc (`nong-noc`) | Ếch (`ech`) | Mọc thêm chân, đuôi ngắn dần, rồi nhảy lên bờ. |  |  |
| Lớn lên thế nào? | Sâu lớn lên thành con gì? | Sâu (`sau`) | Bướm (`buom`) | Sâu ngủ trong kén, tỉnh dậy có đôi cánh đẹp. |  |  |
| Lớn lên thế nào? | Hạt mọc lên thành gì? | Hạt (`hat`) | Cây mầm (`cay-mam`) | Tưới nước mỗi ngày, hạt nhú lên hai lá non. |  |  |
| Lớn lên thế nào? | Bê con lớn lên thành con gì? | Bê con (`be-con`) | Bò (`bo`) | Bê con uống sữa mẹ, lớn dần thật khỏe. |  |  |

**Cần ba mẹ xem kỹ (cấp 5):** câu hỏi là "thích ăn gì", nhưng vài lựa chọn sai vẫn có thể ăn được thật (khỉ có thể ăn cà rốt, thỏ ăn được hoa, mèo hay gặm cỏ). Nếu thấy dễ gây nhầm, sửa câu hỏi thành "thích ăn **nhất**" hoặc báo AI thêm vào cột "Cũng đúng".
