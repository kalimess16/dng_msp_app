# Progress log

## 2026-11-12

### US-1 — AUS-1
- Viết `CLAUDE.md` theo bộ chuẩn `Claude-skill-php` (phân cấp AUS-0..3), chuyển sang Flutter.

### US-2 — AUS-1: thông báo văn bản mở ở tiêu đề
- `reply_internal_message_page.dart`: gắn `GlobalKey` vào thông báo văn bản mới nhất, cuộn bằng
  `iotRevealTopOfScrollItem` (vùng cuộn `reverse` → `alignment: 1.0`); căn lại khi ảnh xem trước làm tin
  cao thêm (`ScrollMetricsNotification`), ngừng khi người dùng kéo hoặc chạm ô soạn tin.
- `reply_internal_message_stream.dart`: `isDocumentNotification`, `latestDocumentNotificationIndex`.
- Test: `test/document_title_scroll_test.dart` (4 test) — pass.

### US-3 — AUS-1: tìm kiếm theo văn bản
- `search_internal_message_stream.dart`: tách dòng `- VB <số hiệu> : <trích yếu>`, chỉ giữ văn bản khớp
  (không dấu, không phân biệt hoa thường); tự đọc tối đa 5 trang nếu trang chưa có văn bản khớp.
- `result_internal_messages_page.dart`: mỗi dòng là một văn bản; chạm → tải và mở file; nút "Xem tin nhắn".
- `search_internal_messages_page.dart`: tiêu đề "Tìm văn bản", gợi ý "Tên hoặc số hiệu văn bản".
- Test: `test/document_search_test.dart` (9 test) — pass.

### Kiểm tra
- `flutter analyze` (7 file đã sửa/thêm): No issues found.
- `flutter test`: +47 ~5 (skip test cần PDF mẫu), All tests passed.
- `flutter run` trên emulator `Pixel_API_36`: build + cài đặt thành công. Chưa thử với dữ liệu thật (cần đăng nhập).

### US-4 — AUS-1: tìm kiếm chỉ ra văn bản ở dòng đầu tin
- Nguyên nhân (suy từ code, chưa xem được server): US-3 tách văn bản từ `title` của `searchInternalMessages`,
  trường này không chứa đủ các dòng `- VB`; màn xem tin dùng `listReplyInternalMessages` mới có nội dung đầy đủ.
- `search_internal_message_stream.dart`: mỗi tin tìm được lấy `title` đầy đủ của đúng tin (khớp `id` + `creator`)
  qua `listReplyInternalMessages`, cache theo chuỗi, song song tối đa 4; lỗi → giữ `title` tìm kiếm.
- Test: `test/document_search_test.dart` +3 test US-4 (12/12 pass). `flutter analyze`: No issues.
  `flutter test`: +50 ~5 All tests passed. App chạy lại trên emulator thành công.

### US-5 — AUS-1: giao diện khi quay ngang
- Nguyên nhân: `ScreenUtilInit` cố định khung dọc 1080x1920 → quay ngang `.sp`/`.w` tính theo chiều rộng (gấp ~2,2 lần),
  `.h`/`.sh` theo chiều cao (bóp còn ~0,46) → chữ/icon to như dọc phóng lớn, dòng chữ có `maxHeight: x.sh` bị cắt.
- `lib/app/resource/var/iot_screen.dart`: `IotScreenUtilInit` (khung đổi chiều 1920x1080 khi ngang), `iotFontSizeResolver`
  (chữ theo cạnh ngắn — dọc giữ nguyên, ngang bằng dọc), extension `.longSide`/`.shortSide` (bằng `.sh`/`.sw` khi dọc).
- `main.dart` dùng `IotScreenUtilInit`. Đổi kích thước item `.sh`/`.sw` → `.longSide`/`.shortSide` ở: log_page, mark/result/
  search eOffice, position_button, reply_download_file_widget, note_report_widget, short_name_circular_widget (giữ `.sh`
  cho giới hạn hộp thoại).
- `bottom_navigator_bar.dart`: bỏ `removeBottom` + chiều cao 56 khi ngang → thanh cử chỉ không còn đè nhãn.
- Test: `test/landscape_screen_util_test.dart` (4 test, gồm xoay khi đang chạy) — pass. `flutter test`: +54 ~5 All passed.
  `flutter analyze` các file sửa: No issues.
- Emulator (đã đăng nhập): chụp home, danh sách MSP, Tìm văn bản, xem tin văn bản ở chế độ ngang — chữ bằng cỡ dọc,
  nhãn thanh điều hướng không bị che; tin văn bản mở đúng ở tiêu đề (xác nhận US-2 với dữ liệu thật).

### US-6 — AUS-1: thu gọn phần dư trên/dưới (giữ thanh hệ thống — người dùng chọn "Chỉ thu gọn, không ẩn")
- Phần dư là thanh trạng thái (24dp) + toolbar 56/46 ở trên, và vùng thanh cử chỉ (24dp) + `BottomNavigationBar` 56 ở dưới.
- `iot_screen.dart`: `iotToolbarHeight` (dọc 48 / ngang 40), `iotBottomBarHeight` (dọc 52 / ngang 40).
- `main.dart`: `AppBarTheme.toolbarHeight` theo hướng → áp cho mọi AppBar (kể cả AppBar riêng của danh sách MSP,
  chọn cán bộ, ôn thi). `app_bar.dart` dùng cùng giá trị.
- `bottom_navigator_bar.dart`: thanh tự dựng gọn thay `BottomNavigationBar`; ngang icon + nhãn cùng hàng; vẫn chừa
  `viewPadding.bottom` để thanh cử chỉ không đè nhãn (US-5); giữ badge số tin / chấm đỏ số liệu định kỳ.
- Sửa thêm: avatar chữ viết tắt (`short_name_circular_widget.dart`) dùng `(x ?? 0.06).sh` bị sót ở US-5 → ngang vỡ chữ
  ("DN Lin"); đổi sang `.longSide`.
- Emulator: ngang app bar 70→64dp, thanh dưới 80→64dp; dọc app bar 80→72dp, thanh dưới 80→76dp; avatar hiện đúng.
- Test: `test/compact_bars_test.dart` (2 test) — pass. `flutter test`: +56 ~5 All passed. `flutter analyze` file sửa: No issues.

### US-7 — AUS-1: icon thanh điều hướng dưới căn giữa phần xanh
- Sau US-6 khối icon + nhãn nằm sát trên, vùng thanh cử chỉ (24dp) trống phía dưới → trông lệch lên.
- `iot_screen.dart`: `iotBottomBarLayout(orientation, bottomInset)` — thanh cử chỉ (inset ≤ 32dp): lề trên = lề dưới
  = max(18, inset·2/3) → căn giữa cả phần xanh, cách vạch cử chỉ ~4dp (đo Pixel: vạch ~10–14dp từ đáy). Thanh 3 nút /
  không có inset: nội dung nằm trên vùng nút, lề 8dp. Khối nội dung dọc 40 / ngang 24; icon 22.
- `bottom_navigator_bar.dart`: dùng bố cục trên; `FittedBox(scaleDown)` để chữ hệ thống phóng to không tràn.
- Emulator: dọc thanh dưới 76dp, ngang 60dp; nội dung giữa, không chạm vạch cử chỉ.
- Test: `test/compact_bars_test.dart` 5 test (căn giữa dọc/ngang, thanh 3 nút, chữ 200%, bố cục) — pass.
  `flutter test`: All passed. `flutter analyze`: No issues.

### US-8 — AUS-1: ảnh xem trước văn bản khi quay ngang
- Nguyên nhân: chiều cao tối đa ảnh = 0,32 × chiều cao màn (`.sh`) → ngang chỉ ~130dp, ảnh co lại nằm lọt giữa khung
  rộng ~700dp (vẫn "theo khung dọc").
- `reply_download_file_widget.dart`: `iotPreviewMaxHeight` = max(0,32 × cạnh dài, rộng khung ÷ 4/3) → dọc giữ nguyên,
  ảnh văn bản (tỉ lệ ≥ 4:3) luôn rộng hết khung; ảnh dải dọc vẫn bị giới hạn chiều cao.
- Rộng hết khung ngang thì mỗi ảnh cao ~450dp > vùng nhìn ~220dp → hỏi người dùng, chọn **2 cột khi ngang**.
- `reply_internal_message_page.dart`: `iotFileColumns` xếp file thành lưới (ngang 2 cột, dọc 1 cột), giữ thứ tự
  trái→phải, trên→dưới để file thứ k vẫn ứng với dòng `- VB` thứ k.
- Emulator (ngang, dữ liệu thật): 2 ảnh/hàng, xem trọn mỗi ảnh (VB 73, 74), không trống hai bên.
- Test: `test/document_preview_size_test.dart` +4 test US-8 (13/13 pass). `flutter test`: +63 ~5 All passed.
  `flutter analyze` file sửa: No issues.

### US-9 — AUS-1: xoay màn hình bị nhảy sang đoạn văn bản khác
- Nguyên nhân:
  1. Màn xem tin cuộn `reverse` (giữ khoảng cách từ đáy). Xoay → chiều cao nội dung đổi (2 cột ảnh, chữ dàn rộng) →
     vùng nhìn trôi sang tin/đoạn khác (cả loạt dòng `- VB` của tin khác).
  2. `build()` tạo `Future` mới (session + `listReplyInternalMessages`) → mỗi lần xoay tải lại chuỗi tin, danh sách bị
     xoá tạm trong lúc tải → nội dung co/giãn, vị trí xáo trộn.
  3. (phát hiện thêm) Thanh dưới đánh dấu "IOT" sau khi xoay: các trang gán `selectedIotBottomNavigatorBar` (static) trong
     `build()`, khi xoay trang home bên dưới build lại sau cùng → ghi đè 0.
- `reply_internal_message_page.dart`: cache 2 `Future` trong `initState`; mỗi tin gốc có `GlobalKey`; ghi nhớ mốc đọc
  (`iotFindReadingAnchor`: tin chứa mép trên vùng nhìn + tỉ lệ đã đọc) khi cuộn xong; đổi hướng → khôi phục mốc
  (lặp lại 2s trong lúc ảnh tải xong, dừng khi người dùng kéo). US-2 vẫn ưu tiên khi người dùng chưa tự cuộn.
- `bottom_navigator_bar.dart`: `selectedFor(context)` ghi nhận mục được chọn theo từng route (Expando) ở lần dựng đầu.
- Emulator (dữ liệu thật, tin "+6 KHÁC"): dọc kéo tới VB 223…5065 → xoay ngang vẫn đúng đoạn đó → xoay dọc lại trùng
  khớp ảnh ban đầu; thanh dưới giữ "Thông tin".
- Test: +3 test mốc đọc (`document_title_scroll_test.dart`), +1 test thanh dưới khi xoay (`compact_bars_test.dart`).
  `flutter test`: +67 ~5 All passed. `flutter analyze` file sửa: No issues.

### US-10 — AUS-1: tìm văn bản chỉ tải 20 văn bản, nhấn "Xem thêm" tải tiếp
- Nguyên nhân "load ra hết": màn kết quả (`result_internal_messages_page.dart`) có listener cuộn tự gọi tải thêm mỗi khi
  gần đáy → cuộn xuống là tải liên tục tới hết.
- `search_internal_message_stream.dart`: `pageSize = 20`; mỗi lần tải gom đủ 20 văn bản (đọc tối đa `maxPagesPerLoad = 10`
  trang tin), văn bản dư của trang server giữ ở bộ đệm cho lần sau (không gọi lại server, không trùng). `hasMore` = còn bộ
  đệm hoặc server còn trang. `loadNextDocuments` lỗi → trả văn bản về bộ đệm, danh sách giữ nguyên để thử lại.
- Màn kết quả: bỏ tự tải khi cuộn; cuối danh sách có nút "Xem thêm" (ẩn khi hết). Áp dụng cho mọi điều kiện lọc của
  màn "Tìm văn bản" (thời gian, người gửi/nhận, từ khóa).
- Test: `document_search_test.dart` +5 test US-10, sửa 1 test US-3 (nay đọc tiếp tới đủ 20 thay vì dừng ở kết quả đầu);
  mới `document_search_paging_test.dart` (widget: 20 → cuộn đáy không tự tải → Xem thêm 40 → 50 rồi ẩn nút).
  `flutter test`: +73 ~5 All passed. `flutter analyze` file sửa: No issues.

### US-11 — AUS-3: đối chiếu cấu hình iOS, build APK phát hành
- iOS (rà tĩnh, không build được trên Windows): bundle `org.vbspdng.msp` khớp `GoogleService-Info.plist`, URL scheme =
  `REVERSED_CLIENT_ID`; entitlements Sign in with Apple + push; `FirebaseAppDelegateProxyEnabled=false` và AppDelegate tự
  gán `apnsToken`; bridge Keychain cùng tên channel với Dart; ATS nghiêm ngặt; plugin qua SPM + CocoaPods (Podfile.lock
  khớp); fork `pdfium_flutter` có `Package.swift`; deployment target 15.6; Dart dùng `identifierForVendor` trên iOS.
- Rủi ro iOS chưa xử lý: Firebase iOS SDK 10.12 chưa có privacy manifest (App Store có thể từ chối ITMS-91061); chưa kiểm
  với Xcode mới; `aps-environment=development` (Xcode đổi khi archive bằng profile phân phối).
- Android: APK đang phát hành (`IOT_1.0.2_Android.apk`) ký bằng debug key máy này (SHA-1 9640f2…), `versionCode=2`.
  `pubspec.yaml` `1.1.1+1` → `1.1.1+3` để cài đè được. Giữ cấu hình ký hiện tại (cùng khoá với bản đang phát hành).
- `flutter analyze`: No issues. `flutter test`: +73 ~5 All passed. `flutter build apk --release`: app-release.apk 70.3MB,
  versionCode 3 / 1.1.1, arm64-v8a/armeabi-v7a/x86_64. Emulator: `adb install -r` đè lên bản cũ → Success, mở app OK.
