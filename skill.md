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
