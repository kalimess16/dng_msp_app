# Hướng Dẫn Dự Án DNG MSP / IOT

Tài liệu này tổng hợp từ source Flutter trong project `dngmsp`. Nội dung tập trung vào tính năng hiện có, cách sử dụng ứng dụng, cách quản lý source, API, cấu hình Android/iOS và các điểm cần lưu ý khi bảo trì.

## 1. Tổng Quan

- Tên Flutter package: `dngmsp`.
- Ứng dụng hiển thị: `IOT`.
- Mục đích chính: ứng dụng nội bộ cho VBSP Đà Nẵng, phục vụ xem báo cáo, thông tin nội bộ MSP, văn bản eOffice, thông báo định kỳ và theo dõi phòng máy/PMC.
- Nền tảng: Android và iOS.
- Kiến trúc chính:
  - `view`: màn hình và widget UI.
  - `viewmodel`: điều phối state, stream, provider, xử lý dữ liệu trước khi đưa lên UI.
  - `service`: gọi backend HTTP/Firebase.
  - `model`: mapping dữ liệu JSON.
  - `resource`: route, màu, font, icon, chuỗi, emoji.
  - `utility`: helper chung.

## 2. Công Nghệ Và Thư Viện Chính

Project sử dụng Flutter/Dart với SDK constraint:

```yaml
sdk: ">=2.12.0 <3.0.0"
```

Các dependency quan trọng:

- `http`: gọi REST API backend.
- `provider`: quản lý state cho danh sách tin nhắn, báo cáo tự động, tìm kiếm.
- `shared_preferences`: lưu token, tên, email, username sau đăng nhập.
- `firebase_core`, `firebase_auth`, `firebase_messaging`, `firebase_analytics`: Firebase, xác thực, FCM.
- `google_sign_in`, `sign_in_with_apple`: đăng nhập Google/Apple.
- `flutter_local_notifications`: hiển thị local notification từ FCM.
- `device_info_plus`: lấy mã thiết bị Android/iOS khi đăng nhập.
- `connectivity`: kiểm tra kết nối internet.
- `path_provider`, `open_file`, `mime`: tải, ghi file tạm và mở file đính kèm.
- `lazy_data_table`: hiển thị bảng báo cáo lớn.
- `flutter_screenutil`: scale giao diện theo kích thước thiết kế.
- `wakelock`: giữ màn hình không tắt ở trang home.
- `url_launcher`: mở link và trang cập nhật ứng dụng.

## 3. Cấu Trúc Thư Mục

```text
lib/
  main.dart
  app/
    model/        Model dữ liệu nhận từ API.
    service/      Gọi backend/Firebase, xử lý lỗi HTTP.
    viewmodel/    Stream, provider, điều phối dữ liệu cho UI.
    view/         Các màn hình Flutter.
    resource/     Routes, màu, font, icon, chuỗi, emoji.
    utility/      Helper kiểm tra mạng, format thời gian, chọn ngày.
    provider/     Khai báo MultiProvider.
android/          Project Android native.
ios/              Project iOS native.
assets/           Ảnh, icon, font custom.
test/             Test mặc định của Flutter, hiện chưa khớp với app thật.
```

Các thư mục/file sinh ra bởi build hoặc dependency như `build/`, `.dart_tool/`, `ios/Pods/` không nên sửa thủ công khi bảo trì tính năng.

## 4. Luồng Khởi Động Ứng Dụng

File vào chính: `lib/main.dart`.

Luồng chạy:

1. `WidgetsFlutterBinding.ensureInitialized()`.
2. `Firebase.initializeApp()`.
3. Đọc session từ `IotSharedPreferences`.
4. Cấu hình `HttpOverrides.global = IotHttpOverrides()`.
5. Bọc app bằng `MultiProvider`.
6. Nếu chưa có token thì vào `/login`, nếu đã có token thì vào `/home`.

Lưu ý quan trọng: `IotHttpOverrides` đang chấp nhận mọi SSL certificate:

```dart
badCertificateCallback = (X509Certificate cert, String host, int port) => true;
```

Cấu hình này giúp gọi backend HTTPS có certificate tự ký, nhưng không nên dùng cho môi trường public nếu không kiểm soát được hạ tầng.

## 5. Cấu Hình Chung

File chính: `lib/app/resource/string/app_strings.dart`.

Các biến quan trọng:

- `IOT_REQUEST_URL`: URL backend API, hiện là `https://117.2.155.59:2024/`.
- `IOT_UPGRADE_APP_URL`: URL tải/cập nhật app, hiện là `http://117.2.155.59:2025/index.html`.
- `IOT_APP_VERSION`: vendor/app version gửi lên backend qua header `Vendor`, hiện là `trops.5.2.9`.
- `IOT_APP_VERSION_LABEL`: nhãn version hiển thị, hiện là `1.1.1`.

Mỗi request API thường gửi:

- Header `Authorization: Bearer <wsToken>`.
- Header `Vendor: base64(IOT_APP_VERSION)`.
- Body JSON hoặc multipart tùy API.

Session lưu bằng `SharedPreferences` trong `lib/app/model/shared_preferences.dart`:

- `dngWsToken`
- `dngFullName`
- `dngEmail`
- `dngUsername`

## 6. Điều Hướng Và Menu

File route: `lib/app/resource/routes.dart`.

Route chính:

| Route | Màn hình | Chức năng |
|---|---|---|
| `/login` | `IotLoginPage` | Đăng nhập |
| `/home` | `IotHomePage` | Trang chủ |
| `/credit_report` | `IotListManualReportsPage(type: credit)` | Báo cáo tín dụng |
| `/account_report` | `IotListManualReportsPage(type: accountant)` | Báo cáo kế toán |
| `/query_report` | `IotListManualReportsPage(type: query)` | Truy vấn thông tin khách hàng |
| `/auto_report` | `IotListAutoReportPage` | Số liệu định kỳ |
| `/room` | `IotServerRoomPage` | Nhiệt độ PMC và WAN |
| `/msp` | `IotListInternalMessagesPage` | Thông tin nội bộ MSP |
| `/compose_msp` | `IotComposeInternalMessagePage` | Soạn thông tin từ trang chủ |
| `/compose_msp_in_list` | `IotComposeInternalMessagePage` | Soạn thông tin từ danh sách MSP |
| `/search_msp` | `IotSearchInternalMessagesPage` | Tìm tin nhắn nội bộ |
| `/account` | `IotAccountPage` | Tài khoản |
| `/search_documents` | `SearchDocumentPage` | Tìm văn bản |

Menu trang chủ nằm trong `IotRoutes.iotListApps`. Muốn thêm/bớt icon trên home thì sửa map này và bổ sung route tương ứng trong `routes()`.

Bottom navigation nằm trong `lib/app/view/widget/bottom_navigator_bar.dart`, gồm:

- `IOT`: về home.
- `Số liệu định kỳ`: vào báo cáo tự động.
- `Thông tin`: vào MSP/tin nhắn nội bộ.

Badge `N` hiển thị khi có tin chưa đọc hoặc báo cáo tự động chưa đọc.

## 7. Tính Năng Chi Tiết

### 7.1. Đăng Nhập Và Tài Khoản

Màn hình:

- `lib/app/view/main/login_page.dart`
- `lib/app/view/account/account_page.dart`
- `lib/app/view/account/log_page.dart`

ViewModel/service:

- `IotAccountStream`
- `IotAccountService`
- `IotAccountLogStream`
- `IotAccountLogService`

Chức năng:

- Đăng nhập bằng Google.
- Đăng nhập bằng Apple chỉ hiển thị trên iOS.
- Lấy thông tin thiết bị:
  - Android: `androidId`.
  - iOS: `identifierForVendor`.
- Lấy FCM token và gửi lên backend khi login.
- Backend trả về `wstoken`, `fullname`, `username`.
- Lưu session bằng `SharedPreferences`.
- Logout gọi API `logout_iot`, sau đó clear session và quay về login.
- Nếu backend trả `INVALID_VENDOR`, app hiển thị nút nâng cấp phiên bản.
- Nếu gặp lỗi 403, app yêu cầu đăng nhập lại hoặc cập nhật app tùy header `iot-upgrade`.

API liên quan:

- `loginWithGmail`
- `logout_iot`
- `listUserLogs`

Ghi chú sửa lỗi đăng nhập ngày 2026-05-22:

- Log trên emulator cho thấy Google/Firebase Auth đã xác thực được user, sau đó API `loginWithGmail` cũng trả JSON user. Vì vậy lỗi hiển thị chung `Lỗi xác thực` không đủ để phân biệt Firebase, backend hay lưu session.
- `IotAccountService.loginIot()` đã đổi FCM token thành tùy chọn. Nếu `FirebaseMessaging.instance.getToken()` lỗi hoặc trả `null`, app vẫn gửi request login với `fcmtoken` rỗng thay vì làm hỏng toàn bộ đăng nhập.
- `IotSharedPreferences.set()` đã đổi sang `Future<bool>` và luồng login chờ lưu đủ `wstoken`, `fullname`, `email`, `username` trước khi phát `LOGIN_SUCCESS_KEY`.
- `IotAccountStream` tách trạng thái lỗi: `FIREBASE_ERROR`, `BACKEND_ERROR`, `TOKEN_SAVE_ERROR`, `NETWORK_ERROR`, `INVALID_VENDOR`. Màn login dùng các trạng thái này để hiển thị thông báo đúng nguyên nhân hơn.
- Khi debug login trên Android, dùng `adb logcat` lọc các từ khóa `FirebaseAuth`, `GoogleSignIn`, `IOT login`, `loginWithGmail`, `ApiException`. Nếu Firebase thành công nhưng server trả non-200, cần kiểm tra tài khoản đã được cấp quyền ở backend IOT.
- Nếu log báo `HandshakeException: Handshake error in client (OS Error: WRONG_VERSION_NUMBER)`, app đang gọi HTTPS vào cổng chỉ phục vụ HTTP. Cổng `2025` hiện là trang upgrade/web, không phải API login. Cấu hình đúng cho API hiện tại là `IOT_REQUEST_URL = 'https://117.2.155.59:2024/'`; nếu gọi `http://117.2.155.59:2024/`, server trả `This combination of host and port requires TLS`.

### 7.2. Trang Chủ

Màn hình: `lib/app/view/main/home_page.dart`.

Chức năng:

- Hiển thị logo, tên ứng dụng, tên người dùng đang đăng nhập.
- Chạm tên người dùng để vào trang tài khoản.
- Hiển thị grid các module nghiệp vụ.
- Cấu hình FCM/local notification khi vào home.
- Xóa toàn bộ notification đang hiển thị trên tray khi home render.
- Bật `Wakelock.enable()` để màn hình không tự tắt khi ở home.

### 7.3. Báo Cáo Thủ Công

Màn hình:

- `list_manual_report_page.dart`
- `manual_report_page.dart`
- `detail_manual_report_page.dart`
- `content_report_page.dart`

Service/viewmodel:

- `IotListManualReportService`
- `IotManualReportService`
- `IotDetailManualReportService`
- `IotManualReportStream`
- `IotDetailManualReportStream`

Nhóm báo cáo hiện có:

- Tín dụng: route `/credit_report`, type `credit`.
- Kế toán: route `/account_report`, type `accountant`.
- Truy vấn thông tin khách hàng: route `/query_report`, type `query`.

Luồng sử dụng:

1. Người dùng chọn nhóm báo cáo trên home.
2. App gọi `listCompactReports?type=<type>` để lấy danh sách báo cáo.
3. Chọn một báo cáo.
4. App gọi `specCompactReports` để lấy danh sách tham số.
5. Người dùng nhập tham số và bấm `Thực hiện`.
6. App gọi `detailCompactReports`.
7. Kết quả hiển thị bằng `LazyDataTable`.

Loại tham số:

- `D`: ngày.
- `S`: dropdown.
- `N`: số.
- Loại còn lại: text.

Report detail được backend trả dạng title/content có delimiter `~` và `^`; `IotDetailContentReportsStream` parse thành sticky column, header, body table, width và alignment.

API liên quan:

- `listCompactReports?type=<type>`
- `specCompactReports`
- `detailCompactReports`

### 7.4. Báo Cáo Tự Động / Số Liệu Định Kỳ

Màn hình:

- `list_auto_report_page.dart`
- `auto_report_page.dart`
- `check_box_messages.dart`

Service/viewmodel:

- `IotListAutoReportService`
- `IotAutoReportService`
- `IotListAutoReportStream`
- `IotAutoReportStream`
- `IotNavigatorAutoReportPage`

Chức năng:

- Xem danh sách báo cáo định kỳ.
- Phân biệt chưa đọc/đã đọc bằng `status`.
- Load thêm khi kéo tới cuối danh sách.
- Nhận FCM message type `AR` để cập nhật danh sách realtime.
- Chạm báo cáo để đánh dấu đã đọc và mở bảng số liệu.
- Hiển thị badge chưa đọc ở bottom navigation.

API liên quan:

- `listAutoReports?startTime=<timestamp>`
- `readAutoReport`
- `countUnreadAutoReports`
- Endpoint report detail động theo `reportType`.

Payload FCM loại `AR` cần các field chính:

- `messageType = AR`
- `id`
- `title`
- `status`
- `creator`
- `time`
- `reportDate`
- `reportType`

### 7.5. Phòng Máy PMC / WAN

Màn hình: `lib/app/view/room/room_page.dart`.

Service/viewmodel:

- `IotServerRoomService`
- `IotServerRoomStream`

Chức năng:

- Gọi API `1~IPCAM`.
- Hiển thị danh sách thông tin phòng máy/PMC/WAN.
- Nếu `code` bắt đầu bằng `TEMPE-`, `content` được xem là ảnh base64 và render bằng `Image.memory`.
- Các dòng khác hiển thị text thường.

API liên quan:

- `1~IPCAM`

### 7.6. Thông Tin Nội Bộ MSP

Màn hình:

- `list_internal_messages_page.dart`
- `reply_internal_message_page.dart`
- `compose_internal_message_page.dart`
- `forward_message_page.dart`
- `search_internal_messages_page.dart`
- `result_internal_messages_page.dart`
- `reply_download_file_widget.dart`
- `emotion_user_page.dart`
- `confirm_button.dart`

Service/viewmodel:

- `IotListInternalMessagesService`
- `IotReplyInternalMessagesService`
- `IotComposeMessageService`
- `IotForwardMessageService`
- `IotSearchInternalMessagesService`
- `IotPositionService`
- `IotListInternalMessageStream`
- `IotReplyInternalMessageStream`
- `IotComposeMessageStream`
- `IotForwardMessageStream`
- `IotSearchInternalMessageStream`
- `IotPositionStream`

Chức năng danh sách:

- Xem danh sách thread/thông tin nội bộ.
- Hiển thị người/nhóm, thời gian, tiêu đề.
- Phân biệt chưa đọc/đã đọc bằng `status`.
- Load thêm theo `startTime`.
- Badge chưa đọc ở bottom navigation.
- Chạm item để gọi `readInternalMessage` và mở màn hình trả lời.

Chức năng soạn thông tin:

- Chọn người nhận hoặc nhóm nhận.
- Có lựa chọn `ALL` cho toàn chi nhánh.
- Tìm kiếm người nhận không dấu.
- Nhập nội dung.
- Chèn emoji từ danh sách nội bộ.
- Gửi bằng multipart API.
- Source hiện truyền danh sách file rỗng khi soạn/trả lời, nhưng service đã hỗ trợ upload file multipart nếu UI bổ sung chọn file.

Chức năng trả lời:

- Xem chuỗi tin gốc và tin mới đến.
- Trả lời nội dung text.
- Link trong nội dung được tự nhận diện và mở bằng `url_launcher`.
- Search word được highlight trong nội dung/file name khi mở từ kết quả tìm kiếm.
- Có nút xác nhận đã xem.
- Xem danh sách người đã nhận/đã xác nhận.
- Chuyển tiếp tin cho người/nhóm khác.

Chức năng file:

- Liệt kê file đính kèm của từng tin.
- Preview ảnh/PDF dạng base64 trực tiếp trong thread.
- Tải file base64, ghi vào thư mục tạm rồi mở bằng app ngoài qua `open_file`.
- Nếu máy không có app đọc định dạng đó, app hiển thị cảnh báo.
- Với file PDF, có nút phân loại văn bản eOffice.

Chức năng tìm kiếm:

- Lọc theo thời gian.
- Lọc theo người gửi/người nhận.
- Tìm theo nội dung.
- Load thêm kết quả theo `startTime`.

API liên quan:

- `listInternalMessages?startTime=<timestamp>`
- `readInternalMessage`
- `countUnreadInternalMessages`
- `listReplyInternalMessages`
- `listReplyDownloadFiles`
- `listReplyDownloadDataFile`
- `uploadReplyDocumentFiles`
- `incomingReplyInternalMessages`
- `emotionInternalMessage`
- `listEmotionUsers`
- `listPositions`
- `groupMembers`
- `uploadDocumentFiles`
- `uploadDocumentFilesInList`
- `uploadForwardMessage`
- `searchInternalMessages`

Payload FCM loại `IM` cần các field chính:

- `messageType = IM`
- `originalId`
- `originalCreator`
- `id`
- `creator`
- `creatorName`
- `title`
- `time`
- `status`
- `groupName`
- `notificationId`
- `emotion`

Nếu payload IM không có `title`, app hiểu đó là message cập nhật trạng thái và gọi `updateIotFirebaseMessage`.

### 7.7. Văn Bản eOffice

Màn hình:

- `search_document_page.dart`
- `search_eoffice_page.dart`
- `result_eoffice_page.dart`
- `search_mark_eoffice_page.dart`
- `result_mark_eoffice_page.dart`
- `mark_eoffice_page.dart`

Service/viewmodel:

- `SearchEofficeService`
- `MarkEofficeService`
- `SearchEofficeStream`
- `MarkEofficeStream`

Nhánh `Văn bản chung`:

- Chọn loại văn bản: tất cả, văn bản đến, văn bản đi.
- Chọn cơ quan ban hành.
- Có thể lọc theo khoảng ngày.
- Nhập từ khóa.
- Xem danh sách kết quả.
- Chạm kết quả để tải file và mở bằng app ngoài.
- Load thêm theo `startId`.

API:

- `fetchEofficeAgency?type=<type>`
- `searchEofficeApproval`
- `downloadEofficeApprovalFile`

Nhánh `Văn bản tự phân loại`:

- Tìm văn bản đã được người dùng phân loại từ file PDF trong MSP.
- Lọc theo thời gian, từ khóa, tìm thêm trong ghi chú, cơ quan.
- Xem ghi chú nếu có.
- Chạm kết quả để tải file đã phân loại.
- Load thêm theo `startId`.

API:

- `fetchMarkEofficeAgency`
- `searchSelfMarkEoffice`
- `downloadMarkEofficeFile`

Phân loại văn bản từ file MSP:

- Trong thread MSP, với file PDF có icon phân loại.
- Mở `MarkEofficePage`.
- Nhập/sửa tiêu đề, cơ quan ban hành, ngày ban hành, ghi chú.
- Lưu về backend.

API:

- `fetchMarkEoffice`
- `saveMarkEoffice`

### 7.8. Thi Nghiệp Vụ

Màn hình:

- `common_conduct_page.dart`
- `common_answer_widget.dart`
- `stream_builder_page.dart`

Tính năng này đang tồn tại trong source nhưng route `CONDUCT_PAGE` đang bị comment trong `routes.dart` và item menu cũng đang bị comment.

Chức năng nếu bật lại:

- Lấy danh sách lĩnh vực và số câu hỏi.
- Chọn lĩnh vực.
- Sinh câu hỏi ngẫu nhiên.
- Đếm thời gian trả lời.
- Chấm đúng/sai và hiển thị đáp án.

API:

- `common_conduct_info`
- `common_conduct?fieldNum=<fieldNum>&num=<num>`

### 7.9. Xử Lý Lỗi Chung

Widget: `IotExceptionPage`.

Mã lỗi chính:

- `-2`: không có số liệu.
- `403`: token không hợp lệ, tài khoản đăng nhập ở thiết bị khác hoặc cần cập nhật app.
- `408`: timeout/kết nối không ổn định.
- `101` hoặc `-1`: không kết nối được máy chủ.
- Khác: lỗi phát sinh chung.

Hầu hết service bắt lỗi:

- Mất mạng hoặc lỗi socket chứa `errno = 101`.
- Timeout.
- HTTP status khác 200.
- Header `iot-upgrade` để xác định cần cập nhật phiên bản.

## 8. Quản Lý State

File provider: `lib/app/provider/provider.dart`.

Provider hiện khai báo:

- `IotListInternalMessageStream`
- `IotReplyInternalMessageStream`
- `IotListAutoReportStream`
- `IotSearchInternalMessageStream`

Các màn hình dùng `Provider`/`Consumer` cho những dữ liệu cần cập nhật realtime:

- Danh sách MSP.
- Thread trả lời MSP.
- Danh sách báo cáo tự động.
- Kết quả tìm kiếm MSP.
- Badge chưa đọc ở bottom navigation.

Các chức năng ít realtime hơn dùng `FutureBuilder` hoặc `StreamController` local.

## 9. Firebase Và Notification

File chính:

- `lib/app/viewmodel/init_local_notification.dart`
- `lib/app/view/main/home_page.dart`

Android:

- Channel ID: `msp_channel_id`.
- Channel name: `iot_notification`.
- Icon notification: `ic_stat_name_msp`.
- Background handler: `firebaseMessagingBackgroundHandler`.
- Khi bấm notification, local notification truyền payload dạng chuỗi phân tách bằng `~`.

iOS:

- App lắng nghe `FirebaseMessaging.onMessageOpenedApp`.
- `Info.plist` tắt `FirebaseAppDelegateProxyEnabled`.
- `AppDelegate.swift` gọi `FirebaseApp.configure()`.
- `Runner.entitlements` bật APNs development và Sign in with Apple.

Luồng notification:

1. App nhận FCM.
2. Nếu đang foreground, cập nhật provider trong app.
3. Nếu background, handler tạo local notification.
4. Khi người dùng bấm notification:
   - `IM`: mở thread MSP tương ứng.
   - `AR`: mở báo cáo tự động tương ứng.

## 10. Cấu Hình Android

File quan trọng:

- `android/app/build.gradle`
- `android/build.gradle`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/google-services.json`
- `android/app/src/main/java/org/vbspdng/msp/Application.java`
- `android/app/src/main/java/org/vbspdng/msp/MainActivity.java`

Cấu hình hiện tại:

- `applicationId`: `org.vbspdng.msp`.
- `compileSdkVersion`: lấy từ Flutter (`flutter.compileSdkVersion`), hiện Gradle fallback cho thư viện Android là `36`.
- `minSdkVersion`: lấy từ Flutter (`flutter.minSdkVersion`).
- `targetSdkVersion`: lấy từ Flutter (`flutter.targetSdkVersion`).
- Android Gradle Plugin: `8.11.1`.
- Kotlin Gradle Plugin: `2.2.20`.
- Google services plugin: `4.4.4`.
- Firebase Messaging native dependency: `com.google.firebase:firebase-messaging:20.1.0`.
- App label: `IOT`.

Ghi nhớ lỗi Gradle `compileSdkVersion is not specified`:

- Không sửa trực tiếp package trong `C:\Users\...\Pub\Cache` vì `flutter pub get`/cache repair có thể ghi đè mất.
- Dependency `android_id` đang dùng bản local tại `third_party/android_id` để vá `android/build.gradle`: khi chạy trong Flutter sẽ lấy `flutter.compileSdkVersion`, khi IDE/Gradle mở plugin standalone sẽ fallback `compileSdk = 36` và `minSdk = 23`.
- Nếu nâng cấp hoặc đổi lại `android_id` từ pub.dev, phải kiểm tra lại lỗi root project `android_id` trước khi commit.

Permission:

- `android.permission.INTERNET`
- `android.permission.RECORD_AUDIO`
- `android.permission.WAKE_LOCK`

Notification metadata:

- Default notification channel ID: `msp_channel_id`.
- Default notification icon: `@drawable/ic_stat_name_msp`.
- Default notification color: `@color/colorAccent`.

Release signing:

- `android/app/build.gradle` hiện vẫn dùng `signingConfigs.debug` cho release.
- Repo có file `vbs_dng_msp.jks`, nhưng chưa được cấu hình trong `signingConfigs`.
- Khi phát hành thật, cần cấu hình keystore/password an toàn qua `key.properties` hoặc biến môi trường, không hard-code secret trong git.

Lệnh thường dùng:

```bash
flutter pub get
flutter run -d android
flutter build apk --release
flutter build appbundle --release
```

## 11. Cấu Hình iOS

File quan trọng:

- `ios/Podfile`
- `ios/Runner/Info.plist`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/Runner.entitlements`
- `ios/GoogleService-Info.plist`
- `ios/Runner.xcworkspace`

Cấu hình hiện tại:

- iOS deployment target: `12.0`.
- Firebase iOS SDK pin: `9.6.0`.
- App display name: `IOT`.
- Google Sign-In URL scheme có trong `CFBundleURLTypes`.
- `FirebaseAppDelegateProxyEnabled = false`.
- `FirebaseAutomaticScreenReportingEnabled = false`.
- Background modes:
  - `fetch`
  - `remote-notification`
- Entitlement:
  - `aps-environment = development`
  - `com.apple.developer.applesignin = Default`

Lệnh thường dùng trên macOS:

```bash
flutter pub get
cd ios
pod install
cd ..
flutter run -d ios
flutter build ios --release
```

Khi release iOS:

- Mở `ios/Runner.xcworkspace` bằng Xcode.
- Kiểm tra Bundle Identifier, Team, Signing Certificate, Provisioning Profile.
- Chuyển APNs entitlement sang môi trường phù hợp khi release.
- Đảm bảo Sign in with Apple và Push Notification được bật trong Apple Developer.

## 12. Cách Sử Dụng Ứng Dụng

### Người dùng cuối

1. Mở app `IOT`.
2. Đăng nhập bằng Google hoặc Apple.
3. Tại trang chủ:
   - Chọn `Tín dụng`, `Kế toán`, `Truy vấn` để xem báo cáo thủ công.
   - Chọn `PMC` để xem nhiệt độ/phòng máy/WAN.
   - Chọn `Soạn thông tin` để gửi thông tin nội bộ.
   - Chọn `Tìm văn bản` để tìm eOffice.
4. Dùng bottom navigation:
   - `IOT`: quay về trang chủ.
   - `Số liệu định kỳ`: xem báo cáo tự động.
   - `Thông tin`: xem MSP/thông tin nội bộ.
5. Trong MSP:
   - Bấm icon tìm kiếm để tìm tin.
   - Bấm icon thêm để soạn tin.
   - Chạm một tin để xem thread, trả lời, xác nhận đã xem, chuyển tiếp, mở file.
6. Trong file PDF đính kèm MSP:
   - Bấm icon phân loại để lưu thông tin văn bản eOffice.
7. Chạm tên tài khoản ở home để xem thông tin và đăng xuất.

### Lập trình viên

1. Cài Flutter SDK tương thích Dart `<3.0.0`.
2. Chạy `flutter pub get`.
3. Kiểm tra file Firebase:
   - Android: `android/app/google-services.json`.
   - iOS: `ios/GoogleService-Info.plist`.
4. Kiểm tra backend trong `IOT_REQUEST_URL`.
5. Chạy app:
   - Android: `flutter run -d android`.
   - iOS: `flutter run -d ios` trên macOS.
6. Khi sửa API, kiểm tra header `Authorization` và `Vendor`.
7. Khi thêm state realtime, cân nhắc thêm `ChangeNotifierProvider` trong `provider.dart`.
8. Khi thêm màn hình, cập nhật `routes.dart` và menu nếu cần.

## 13. Cách Quản Lý Và Mở Rộng Tính Năng

### Thêm module mới trên home

1. Tạo màn hình trong `lib/app/view/<module>/`.
2. Tạo model/service/viewmodel nếu có API.
3. Thêm constant route vào `IotRoutes`.
4. Thêm case trong `IotRoutes.routes()`.
5. Thêm item vào `IotRoutes.iotListApps`.
6. Nếu cần state realtime, thêm provider trong `iotMultiProvider`.

### Thêm API mới

1. Tạo model mapping JSON trong `lib/app/model`.
2. Tạo service trong `lib/app/service`.
3. Trong service:
   - Lấy `wsToken` từ `IotSharedPreferences`.
   - Gửi `Authorization` và `Vendor`.
   - Timeout hợp lý.
   - Throw `IotException` theo pattern hiện có.
4. Tạo viewmodel để UI không gọi service trực tiếp.
5. UI dùng `FutureBuilder`, `StreamBuilder` hoặc `Provider` tùy nhu cầu cập nhật.

### Thêm loại notification mới

1. Thống nhất `messageType` mới với backend.
2. Cập nhật `firebaseMessagingBackgroundHandler`.
3. Cập nhật `configIotFirebaseMessage()` trong home.
4. Cập nhật `selectNotification()` cho Android.
5. Cập nhật `onMessageOpenedApp` cho iOS.
6. Nếu cần badge, thêm logic ở bottom navigation.

### Quản lý version

Cần đồng bộ các nơi:

- `pubspec.yaml`: `version`.
- `android/local.properties`: `flutter.versionName`, `flutter.versionCode` nếu build đang dùng file này.
- `IOT_APP_VERSION`: backend dùng để kiểm tra vendor/app version.
- `IOT_APP_VERSION_LABEL`: nhãn version hiển thị nếu dùng trong UI.
- Backend có thể trả `INVALID_VENDOR` hoặc header `iot-upgrade` để bắt app cập nhật.

### Quản lý backend URL

URL backend đang hard-code trong `app_strings.dart`. Nếu cần nhiều môi trường dev/test/prod, nên tách bằng:

- `--dart-define`
- file config theo flavor
- hoặc build flavor Android/iOS.

Hiện tại chưa có flavor.

## 14. API Endpoint Theo Module

| Module | Endpoint |
|---|---|
| Account | `loginWithGmail`, `logout_iot`, `listUserLogs` |
| Manual report | `listCompactReports`, `specCompactReports`, `detailCompactReports` |
| Auto report | `listAutoReports`, `readAutoReport`, `countUnreadAutoReports`, endpoint detail động theo `reportType` |
| Room/PMC | `1~IPCAM` |
| MSP list | `listInternalMessages`, `readInternalMessage`, `countUnreadInternalMessages` |
| MSP reply | `listReplyInternalMessages`, `incomingReplyInternalMessages`, `uploadReplyDocumentFiles` |
| MSP file | `listReplyDownloadFiles`, `listReplyDownloadDataFile` |
| MSP emotion | `emotionInternalMessage`, `listEmotionUsers` |
| MSP compose/forward | `listPositions`, `groupMembers`, `uploadDocumentFiles`, `uploadDocumentFilesInList`, `uploadForwardMessage` |
| MSP search | `searchInternalMessages` |
| eOffice search | `fetchEofficeAgency`, `searchEofficeApproval`, `downloadEofficeApprovalFile` |
| eOffice mark | `fetchMarkEofficeAgency`, `fetchMarkEoffice`, `saveMarkEoffice`, `searchSelfMarkEoffice`, `downloadMarkEofficeFile` |
| Conduct | `common_conduct_info`, `common_conduct` |

## 15. Lưu Ý Chất Lượng Source

- `test/widget_test.dart` vẫn là test mặc định Flutter và đang gọi `MyApp()`, trong khi app thật dùng `MainApp`. Test này cần viết lại trước khi chạy CI nghiêm túc.
- Một số chuỗi tiếng Việt trong source khi đọc bằng terminal đang hiển thị sai encoding. Khi sửa text UI, nên kiểm tra file ở UTF-8 và test trực tiếp trên thiết bị.
- `pubspec.yaml` có dòng `fireebase_core: 2.15.1` trong khi source import `firebase_core`. Cần kiểm tra lại dependency này trước khi nâng cấp package.
- `android/local.properties` chứa đường dẫn máy cá nhân và thường không nên commit/chia sẻ giữa máy dev.
- `ios/Pods/` và `build/` là thư mục sinh ra, không nên xem là source nghiệp vụ.
- `HttpOverrides` đang bỏ qua kiểm tra SSL certificate. Chỉ nên giữ nếu backend nội bộ bắt buộc dùng certificate tự ký.
- Android release hiện ký bằng debug config. Cần cấu hình signing chuẩn trước khi phát hành.
- Source service đã hỗ trợ multipart file upload cho MSP, nhưng UI hiện truyền `List<File>` rỗng ở các luồng soạn/trả lời. Nếu cần gửi file từ UI, cần thêm file picker và truyền file thật vào service.

## 16. Checklist Bảo Trì Nhanh

Trước khi build:

- Chạy `flutter pub get`.
- Kiểm tra `IOT_REQUEST_URL`.
- Kiểm tra Firebase config Android/iOS.
- Kiểm tra version trong `pubspec.yaml` và `IOT_APP_VERSION`.
- Kiểm tra app chạy được login, home, MSP, auto report.

Trước khi release Android:

- Cấu hình signing release.
- Kiểm tra `applicationId`.
- Build `apk` hoặc `appbundle`.
- Test notification foreground/background/tap.

Trước khi release iOS:

- Chạy `pod install`.
- Kiểm tra signing trong Xcode.
- Kiểm tra Push Notification và Sign in with Apple capability.
- Build archive bằng Xcode hoặc `flutter build ios --release`.

Khi sửa backend/API:

- Giữ response status 200 cho thành công.
- Trả `iot-upgrade` khi cần ép cập nhật.
- Giữ field JSON đúng với model hiện có.
- Với FCM, giữ payload field đúng cho `IM` và `AR`.
