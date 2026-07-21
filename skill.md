# Kinh nghiệm xử lý form báo cáo động Flutter

## Lỗi mất giá trị dropdown khi giao diện rebuild

- Hiện tượng: chọn CMT/CIF ở trường `Tìm theo`, sau đó chạm ô nhập liệu làm mở bàn phím thì lựa chọn bị xóa.
- Nguyên nhân: tạo `Future` gọi API ngay trong `build()` và khởi tạo lại map tham số mỗi lần `FutureBuilder` rebuild.
- Khắc phục:
  - Khởi tạo và lưu `Future` một lần trong `initState()`.
  - Chỉ khởi tạo map tham số báo cáo một lần; không ghi đè dữ liệu người dùng ở các lần rebuild sau.
  - Lưu mã nghiệp vụ (`CMT`, `MAKH`) để gửi API, nhưng hiển thị nhãn thân thiện (`Số CMT`, `Mã số KH (CIF)`).
  - Dùng generic rõ ràng cho `PopupMenuButton<String>` và `PopupMenuItem<String>`.
- Kiểm thử hồi quy: sau khi chọn dropdown, gọi lại bước khởi tạo form và xác nhận giá trị đã chọn vẫn được giữ nguyên.

## Quy tắc áp dụng

Không tạo Future thực hiện HTTP trực tiếp trong `build()` nếu kết quả chỉ cần tải một lần theo vòng đời màn hình. Mọi hàm khởi tạo state từ dữ liệu API phải có tính idempotent để rebuild không làm mất dữ liệu đang nhập.

## Badge số liệu định kỳ trên thanh điều hướng

- Chỉ hiển thị một chấm đỏ khi có số liệu định kỳ mới, không hiển thị số lượng chưa đọc.
- Giữ nguyên điều kiện `countUnreadAutoReports() > 0`; khi không có dữ liệu mới thì ẩn chấm đỏ.
- Badge tin nhắn nội bộ vẫn hiển thị số lượng, không dùng chung kiểu chấm đỏ này.

## Bảng báo cáo bị cắt chữ trên màn hình nhỏ

- Hiện tượng: các tiêu chí dài từ 3 dòng trở lên bị cắt phần cuối; tiêu đề cột bị xuống dòng từng ký tự trên thiết bị hẹp hoặc khi tăng cỡ chữ hệ thống.
- Nguyên nhân:
  - Dùng một chiều cao cố định bằng `7.5%` chiều cao màn hình cho mọi hàng, không phụ thuộc số dòng thực tế.
  - Chiều rộng cột được quy đổi sang pixel một lần sau khi tải API nên không tính lại khi xoay màn hình hoặc thay đổi kích thước cửa sổ.
- Khắc phục:
  - Dùng `LayoutBuilder` để tính kích thước từ viewport hiện tại ở mỗi lần layout.
  - Đo nội dung bằng `TextPainter` cùng `TextScaler` của thiết bị, sau đó truyền chiều cao riêng cho từng hàng qua `customCellHeight`.
  - Giới hạn min/max cho font, cột tiêu chí và cột dữ liệu; giữ cột tiêu chí cố định và cho vùng số liệu cuộn ngang.
  - Cache Future tải báo cáo trong `initState()` để resize/xoay màn hình không gọi lại API.
- Kiểm thử bắt buộc: màn rộng 320px, viewport tablet và cỡ chữ hệ thống 200%; nội dung dài phải làm hàng cao hơn thay vì tạo overflow hoặc bị cắt.

## Menu báo cáo con quá lớn khi xoay ngang

- Hiện tượng: sau khi xoay thiết bị sang ngang, các mục trong danh sách báo cáo Tín dụng/Kế toán/Truy vấn vẫn dùng chữ và khoảng đệm lớn, chỉ hiển thị được ít mục.
- Nguyên nhân: `flutter_screenutil.sp` lấy chiều rộng màn hình ngang để scale theo thiết kế dọc `1080x1920`, khiến font tăng gần gấp đôi sau khi đổi orientation.
- Khắc phục:
  - Tính font theo cạnh ngắn của viewport và giới hạn `14-16` logical pixel ở màn hình ngang.
  - Thu gọn padding, icon, khoảng cách giữa các thẻ khi màn hình ngang; giữ kích thước chạm đủ rõ ràng.
  - Cache `Future` tải danh sách trong `initState()` để xoay màn hình chỉ layout lại, không gọi API lần nữa.
- Kiểm thử hồi quy: so sánh viewport dọc/ngang cùng cạnh ngắn; font ngang không vượt quá `16`, padding và icon ngang phải nhỏ hơn dọc.

## Bảo vệ token đăng nhập và kết nối TLS

- Không lưu bearer token, email hoặc định danh người dùng bằng `shared_preferences` vì dữ liệu được ghi dạng plaintext.
- Dùng bridge nội bộ tới Android Keystore (AES-256-GCM, IV ngẫu nhiên, AAD theo tên key) và iOS Keychain (`WhenUnlockedThisDeviceOnly`); không thêm plugin lưu trữ từ bên ngoài.
- Khi nâng cấp, chỉ xóa dữ liệu `flutter.*` cũ sau khi đã mã hóa/ghi Keychain thành công. Dữ liệu thiếu hoặc không giải mã được phải fail closed và yêu cầu đăng nhập lại.
- Không đặt `badCertificateCallback` trả về `true` cho mọi kết nối. Với máy chủ IP tự ký chưa thể thay ngay, chỉ cho phép pin toàn bộ DER đúng host/cổng, kiểm tra thời hạn và từ chối mọi chứng chỉ khác; thay pin khi server đổi chứng chỉ.
- Tắt cleartext traffic và backup dữ liệu ứng dụng trên Android; bật ATS nghiêm ngặt trên iOS. Nếu máy chủ dùng CA nội bộ, triển khai CA/certificate hợp lệ có SAN đúng hostname thay vì bỏ qua kiểm tra TLS.
