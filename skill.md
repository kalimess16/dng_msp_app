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

## Ảnh xem trước văn bản (tiêu đề VB) bị nhòe trên điện thoại

- Hiện tượng: ảnh xem trước văn bản PDF trong tin nhắn bị nhòe/méo, nhất là văn bản scan bằng máy photo RICOH.
- Nguyên nhân: `Image.memory(..., fit: BoxFit.fill)` ép ảnh vào khung rộng hết màn hình x cao tối đa `0.2.sh`. Ảnh server 715x463 bị kéo ngang; ảnh cũ dạng dải dọc 328x1010 (server cắt sai trang `/Rotate 270`, xem IotApp US-5) bị bóp dẹt nhiều lần. Ảnh còn bị `base64Decode` lại mỗi lần rebuild.
- Khắc phục (`reply_download_file_widget.dart`): đọc kích thước ảnh bằng `ui.ImageDescriptor`, tính khung bằng `iotPreviewBoxSize` (giữ tỉ lệ, cao tối đa `0.32.sh`), `BoxFit.contain` + `FilterQuality.high` + `gaplessPlayback`; cache bytes đã giải mã trong State.
- Kiểm thử: `test/document_preview_size_test.dart` (715x463, 328x1010, 1100x733 và widget thật ở màn 360x780).
- Không dùng `BoxFit.fill` cho ảnh tài liệu; tỉ lệ ảnh luôn phải lấy từ chính ảnh.

## Ảnh xem trước văn bản phải có "Sao gửi … Lưu VT" (bút phê) như IotApp

- Ảnh server chỉ cắt góc trên-trái (rộng 48%, cao 22%) nên mất bút phê; ảnh cũ máy photo còn là dải dọc sai.
- App tạo lại ảnh giống IotApp `PdfPreviewService` (US-7/9/10): `lib/app/service/im/pdf_preview_service.dart`.
  Ảnh server có nhãn xám "VB:" (eOffice) hoặc dạng dọc → tải PDF ở nền (lần lượt), render trang đầu 180 dpi
  bằng PDFium (`pdfrx`, đúng cả trang `/Rotate 270`), dò mực xanh → render riêng vùng "tiêu đề + Sao gửi … Lưu VT"
  ~1100 px, nhãn "VB: <số hiệu>" trên dải trắng. Cache PNG `tmp/IOT/<messageId>/<file>.preview-eoffice-v3.png`.
- Số hiệu nhãn: dòng tiêu đề `- VB <số hiệu> :` thứ k ứng với file thứ k (`extractDocumentNumbers`).
- Build Android trên Windows: `pdfium_flutter` gốc tạo symlink trong CMake (cần Developer Mode) → dùng bản
  `third_party/pdfium_flutter` (chép thay symlink) qua `dependency_overrides`. Khi nâng pdfrx phải đồng bộ bản này.
- Kiểm thử với PDF thật: `IOT_PDF_SAMPLES=<thư mục PDF> PDFIUM_PATH=<pdfium.dll> flutter test test/pdf_preview_service_test.dart`
  (pdfium.dll do `pdfrxInitialize()` tải về `%LOCALAPPDATA%\pdfrx`). 75 PDF thật: 61 phóng vùng bút phê, còn lại cắt như cũ.
- Lỗi đã gặp: ảnh không bao giờ được thay vì `future.whenComplete(() => _pending.remove(key))` — `remove` trả về
  chính Future đó, `whenComplete` đợi Future trả về → tự đợi chính mình, treo mãi. Callback của `whenComplete`
  phải dùng thân `{ ...; }`, không trả về Future. Mỗi tác vụ trong hàng đợi có timeout 90 s để một lần tải treo
  không chặn ảnh của văn bản khác.
- Kiểm thử phải đi qua đúng hàm app gọi (`regenerate`, chạy trên bản release), không chỉ hàm render bên trong.
  Test `regenerate` để file riêng (`test/pdf_preview_regenerate_test.dart`), không chạy chung với `testWidgets`.

## Mở tin thông báo văn bản ở tiêu đề (US-2)

- Màn xem tin nhắn dùng `SingleChildScrollView(reverse: true)` nên luôn mở ở cuối; tin văn bản có nhiều ảnh xem trước bị đẩy tiêu đề ra ngoài màn hình.
- Với vùng cuộn `reverse`, `Scrollable.ensureVisible(alignment: 0.0)` căn **mép dưới** item; muốn mép trên lên đầu màn hình phải dùng `alignment: 1.0` (`iotRevealTopOfScrollItem` tự chọn theo `axisDirection`).
- Ảnh xem trước tải/tạo lại muộn làm tin cao thêm → căn lại khi nhận `ScrollMetricsNotification`; ngừng tự căn khi người dùng kéo (`ScrollStartNotification.dragDetails != null`) hoặc chạm ô soạn tin.

## Tìm kiếm theo văn bản (US-3)

- API `searchInternalMessages` trả cả tin nhắn; app tách dòng `- VB <số hiệu> : <trích yếu>` và chỉ hiển thị văn bản khớp. Dòng `- VB` thứ k ứng với file thứ k (chạm mở thẳng file).
- So khớp bỏ dấu tiếng Việt cả dạng dựng sẵn và tổ hợp (U+0300–U+036F). Server vẫn lọc tin trước theo `content`, nên nếu server so khớp có dấu thì gõ không dấu có thể không ra kết quả.
- Một trang tin có thể không chứa văn bản khớp → tự đọc tiếp tối đa `maxPagesPerLoad` trang; dừng khi server trả lại cùng `startTime` để tránh lặp vô hạn.
- (US-4) `title` của `searchInternalMessages` không đủ các dòng `- VB` → chỉ ra văn bản dòng đầu. Luôn lấy nội dung đầy đủ của tin qua `listReplyInternalMessages` (khớp `id` + `creator`, cache theo chuỗi) trước khi tách văn bản. Nếu từ khóa nằm ở dòng sau mà tin vẫn không được trả về thì do server chỉ lọc dòng đầu → phải sửa ở server.

## Giao diện khi quay ngang (US-5)

- Gốc lỗi: `ScreenUtilInit(designSize: 1080x1920)` cố định → ngang `.sp`/`.w` theo chiều rộng (~2,2 lần), `.h`/`.sh` theo chiều cao (~0,46 lần).
- Dùng `IotScreenUtilInit` (`lib/app/resource/var/iot_screen.dart`): khung đổi chiều khi ngang + `fontSizeResolver` theo cạnh ngắn → dọc giữ nguyên, ngang chữ bằng dọc. `MediaQuery` có sẵn trên `MaterialApp` (do `View` cung cấp) nên đổi `designSize` theo hướng được.
- Kích thước item (chiều cao dòng, avatar, icon) dùng `.longSide`/`.shortSide` thay `.sh`/`.sw`; chỉ giữ `.sh`/`.sw` cho giới hạn phải nằm trong màn hình (hộp thoại).
- Không `MediaQuery.removePadding(removeBottom: true)` cho thanh điều hướng dưới: thanh cử chỉ Android đè lên nhãn.
- (US-6) Chiều cao app bar đặt chung ở `AppBarTheme.toolbarHeight` theo hướng (`iotToolbarHeight`); thanh điều hướng dưới tự dựng với `iotBottomBarHeight` + `viewPadding.bottom`. Người dùng chọn giữ thanh trạng thái/thanh cử chỉ, chỉ thu gọn — không dùng immersive mode.
- Khi rà `.sh`/`.sw` phải tìm cả biểu thức (`(x ?? 0.06).sh`), không chỉ số viết thẳng: `grep -E "\)\.s[hw]\b|[a-zA-Z_]\.s[hw]\b"`.
- (US-7) Thanh điều hướng dưới phải căn giữa cả phần xanh (gồm vùng thanh cử chỉ), không để nội dung sát trên. Dùng `iotBottomBarLayout`: lề trên = lề dưới ≥ 18dp (vạch cử chỉ ~10–14dp từ đáy). Thanh 3 nút (inset > 32dp) thì nút hệ thống chiếm cả vùng → không được lấn xuống.

## Ảnh xem trước văn bản khi quay ngang (US-8)

- Không giới hạn chiều cao ảnh bằng `.sh` (ngang chỉ ~130dp → ảnh lọt giữa khung). Dùng `iotPreviewMaxHeight` (max của 0,32 × cạnh dài và rộng khung ÷ 4/3).
- Ngang: xếp ảnh 2 cột bằng `iotFileColumns` (người dùng chọn) — 1 cột rộng hết khung thì mỗi ảnh cao hơn vùng nhìn. Lưới phải giữ thứ tự file để khớp dòng `- VB` thứ k.

## Xoay màn hình làm nhảy nội dung (US-9)

- Vùng cuộn `reverse` giữ khoảng cách từ đáy; nội dung đổi chiều cao khi xoay → vùng nhìn trôi sang chỗ khác. Ghi nhớ mốc đọc (tin ở mép trên + tỉ lệ đã đọc, `iotFindReadingAnchor`) khi cuộn xong và khôi phục sau khi đổi hướng.
- Màn xem tin từng tạo `Future` trong `build()` → xoay là tải lại cả chuỗi tin. Luôn cache `Future` trong `initState` (đúng quy tắc chung ở trên).
- Không dựa vào biến `static` gán trong `build()` để biết trang đang xem: khi xoay mọi route trong ngăn xếp build lại theo thứ tự bất kỳ. Thanh dưới dùng `IotBottomNavigatorBar.selectedFor(context)` (ghi nhận theo route).
