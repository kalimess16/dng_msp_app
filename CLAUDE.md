# DNG MSP / IOT (`dngmsp`)

Ứng dụng di động nội bộ VBSP Đà Nẵng (tên hiển thị `IOT`) cho Android và iOS: báo cáo tín dụng/kế toán/
truy vấn, số liệu định kỳ, thông tin nội bộ MSP, văn bản eOffice, phòng máy PMC/WAN, thi nghiệp vụ.
Flutter 3.38 / Dart SDK `>=3.10.0 <4.0.0`, state bằng `provider` (`ChangeNotifier`), gọi REST bằng
`http`, Firebase (Auth, Messaging, Analytics), `flutter_test` cho kiểm thử.
Tài liệu nghiệp vụ, API và cấu hình native: `HUONG_DAN_DU_AN.md`. Bài học kỹ thuật đã gặp: `skill.md`.

> ⚠️ **Hệ thống nội bộ ngân hàng — không gọi tài nguyên qua mạng ngoài ngoài các kênh đã có**
> (backend `IOT_REQUEST_URL`, Firebase, trang nâng cấp `IOT_UPGRADE_APP_URL`). Không thêm font/ảnh/icon tải
> từ Internet (`google_fonts`, `Image.network` tới CDN...), không thêm SDK analytics/quảng cáo/crash bên
> thứ ba. Font, icon, ảnh, chứng chỉ phải nằm trong `assets/` và khai báo ở `pubspec.yaml`.

**Lưu ý: `HUONG_DAN_DU_AN.md` có phần đã lỗi thời**: SDK constraint, `shared_preferences` (nay là
Keystore/Keychain qua `IotSecureStore`) và `IotHttpOverrides` chấp nhận mọi chứng chỉ (nay là
`IotPinnedHttpOverrides`). Khi mâu thuẫn, tin code hiện tại và file này.

## 1. Quy ước US và AUS

- `US-*` là **mã User Story nghiệp vụ** của dự án, ví dụ `US-1`, `US-6`.
- `AUS-*` là **mức thực thi dành cho AI**, quyết định độ sâu phân tích, tài liệu, kiểm thử,
  review và mức sử dụng Superpowers.
- Hai loại mã độc lập. Ví dụ: `AUS-1 thực hiện US-6`.
- Viết chuẩn bằng chữ hoa: `US-*`, `AUS-*`. Không dùng `BUS-*` hoặc biến thể khác để tránh nhầm.
- Mã `US-*` trong `skill.md` có tiền tố `IotApp` (ví dụ `IotApp US-5`) là story của project IotApp khác,
  không phải story của project này.

## 2. Thứ tự ưu tiên chỉ dẫn

Khi có xung đột, áp dụng theo thứ tự:

1. Ràng buộc bảo mật, dữ liệu khách hàng/ngân hàng và tài nguyên nội bộ của dự án.
2. Yêu cầu trực tiếp mới nhất của người dùng.
3. Mức `AUS-*` được người dùng chỉ định.
4. Quy tắc kiến trúc, coding standard và bài học trong `skill.md`.
5. Quy trình mặc định trong file này.

Yêu cầu của người dùng không được vô hiệu hóa ràng buộc bảo mật hoặc an toàn dữ liệu.
Không được dùng quy trình Superpowers nặng hơn chỉ vì skill có sẵn.
Mức ceremony phải tương xứng với rủi ro thực tế.

## 3. Bước bắt buộc trước mọi task code

Trước khi đọc rộng hoặc sửa code:

1. Đọc mục liên quan trong `skill.md` (bài học đã gặp với màn hình/tính năng đó).
2. Xác định User Story liên quan, nếu có.
3. Xác định mức `AUS-*`.
4. Nêu ngắn gọn một dòng: `AUS-x — lý do phân loại`.
5. Chỉ đọc các tài liệu và file cần thiết cho phạm vi đã xác định.

Nếu người dùng đã ghi rõ `AUS-*`, dùng mức đó làm workflow mặc định. Chỉ nâng lên mức an toàn
tối thiểu khi phát hiện rủi ro kỹ thuật cụ thể như bảo mật, token/session, TLS, lưu trữ trên thiết bị,
mất dữ liệu hoặc ảnh hưởng kiến trúc. Khi nâng mức, nêu lý do trong đúng một câu và chỉ bổ sung các
bước thật sự cần. Không tự nâng mức chỉ vì task cần đọc thêm vài file.

Nếu không có `AUS-*`, tự phân loại theo mục 4 và 5. Số lượng file chỉ là tín hiệu tham khảo;
rủi ro nghiệp vụ và mức ảnh hưởng mới là yếu tố quyết định.

## 4. Phân cấp thực thi AUS

### AUS-0 — PATCH

Dùng cho thay đổi rất nhỏ, rõ ràng, cô lập và rủi ro thấp, ví dụ:

- Sửa typo, label, thông báo, màu (`app_colors.dart`), padding/kích thước widget.
- Sửa chuỗi trong `app_strings.dart`/`login_strings.dart` (không phải URL hay version).
- Sửa cấu hình nhỏ không làm thay đổi kiến trúc.
- Sửa bug cục bộ trong một widget với expected behavior đã rõ.

Quy trình:

1. Đọc đúng file trực tiếp liên quan.
2. Sửa tối thiểu, không refactor ngoài phạm vi.
3. Chạy `flutter analyze` cho file đã sửa (và test liên quan nếu có).
4. Ghi `tracking/progress-log.md` một lần khi hoàn thành nếu có thay đổi code.

Không làm ở AUS-0:

- Không dùng `brainstorming`, `writing-plans`, `executing-plans`.
- Không tạo spec hoặc plan mới.
- Không tạo worktree, subagent hoặc review nhiều tầng.
- Không quét toàn repository.
- Không bắt buộc tạo test mới cho thay đổi chỉ liên quan text, style hoặc tài liệu.

Nếu sửa hành vi và có thể tái hiện bug bằng widget/unit test hợp lý, ưu tiên thêm regression test nhỏ.

### AUS-1 — FAST

Dùng cho thay đổi nhỏ đến vừa, yêu cầu rõ, theo đúng pattern hiện có và rủi ro thấp, ví dụ:

- Thêm một field, validation, filter hoặc nút hành động nhỏ trên màn hình có sẵn.
- Sửa một luồng hiện có trong một module (`report`, `im`, `eoffice`, `room`, `account`, `conduct`).
- Thêm một method service gọi endpoint mới theo đúng kiểu service hiện có.
- Sửa layout/responsive của một màn hình (xoay ngang, màn hẹp, cỡ chữ hệ thống).

Quy trình:

1. Đọc spec hiện có của US/module nếu có.
2. Đưa outline ngay trong hội thoại, tối đa 3 bước; không tạo plan file riêng.
3. Với thay đổi hành vi, viết hoặc cập nhật test mục tiêu trước khi sửa implementation khi khả thi.
4. Sửa theo kiến trúc hiện tại (view → viewmodel → service → model).
5. Chạy test liên quan, `flutter analyze` và xác minh trực tiếp.
6. Ghi `tracking/progress-log.md` một lần khi hoàn thành.

Không làm ở AUS-1:

- Không dùng `brainstorming` nếu yêu cầu đã rõ.
- Không tạo spec/plan mới chỉ để hoàn thành ceremony.
- Không dùng worktree hoặc subagent.
- Không refactor module khác và không mở rộng phạm vi ngoài yêu cầu.

Chỉ cập nhật spec hiện có khi acceptance criteria hoặc hành vi nghiệp vụ thật sự thay đổi.

### AUS-2 — STANDARD

Dùng cho tính năng chuẩn có thay đổi nghiệp vụ đáng kể hoặc đi qua nhiều layer, ví dụ:

- Màn hình/module mới trên home (route + icon `IotRoutes.iotListApps` + view + viewmodel + service + model).
- Tính năng đi qua view, viewmodel/provider, service, model và test.
- Thêm loại báo cáo, loại notification FCM mới (`messageType`), hoặc nhiều API có liên quan.
- Xử lý nền mới (hàng đợi tải file, tạo ảnh xem trước, cache file tạm).
- Thay đổi nhiều thành phần nhưng vẫn dùng kiến trúc hiện tại.

Quy trình:

1. Đọc mục module trong `HUONG_DAN_DU_AN.md`, `skill.md` và code liên quan.
2. Dùng `brainstorming` chỉ khi yêu cầu còn mơ hồ hoặc có nhiều phương án thiết kế đáng kể.
3. Tạo hoặc cập nhật spec tại `docs/modules/<module>/<feature>.md`.
4. Tạo plan ngắn, có thể thực thi tại `plans/<module>/<feature>-plan.md`.
5. Thực hiện theo TDD: red → green → refactor, áp dụng tương xứng với loại thay đổi.
6. Chạy test mục tiêu, toàn bộ `flutter test` và `flutter analyze`.
7. Rà checklist bảo mật (mục 10) khi có input người dùng, upload/tải file, ghi file, token/session,
   deep link hoặc payload FCM.
8. Dùng `verification-before-completion` trước khi đánh dấu hoàn thành.
9. Ghi tiến độ theo các mốc chính vào `tracking/progress-log.md`.

Không dùng agent song song hoặc worktree nếu task vẫn có thể xử lý an toàn theo một luồng.

### AUS-3 — DEEP

Dùng cho task rủi ro cao hoặc ảnh hưởng hệ thống, ví dụ:

- Đăng nhập Google/Apple, Firebase Auth, `wsToken`, session, đăng xuất, xử lý 403/`INVALID_VENDOR`.
- Lưu trữ an toàn (`IotSecureStore`, bridge Android Keystore/iOS Keychain, migration dữ liệu cũ).
- TLS/pin chứng chỉ (`IotPinnedHttpOverrides`, `assets/certificates/*.pem`), `IOT_REQUEST_URL`.
- Số liệu báo cáo tài chính/tín dụng hiển thị sai có thể gây hiểu nhầm nghiệp vụ ngân hàng
  (parse `~`/`^` trong `IotDetailContentReportsStream`, căn cột, làm tròn số).
- Nâng/ghi đè dependency nền tảng (Flutter SDK, Firebase, `pdfrx`/`pdfium_flutter`, các bản fork
  trong `third_party/`), cấu hình native Android/iOS (Manifest, Gradle, Info.plist, entitlements,
  ProGuard, signing `*.jks`).
- Build/phát hành, đổi `IOT_APP_VERSION`/`version` hoặc thay đổi khó rollback.

Quy trình đầy đủ:

1. `brainstorming` và làm rõ acceptance criteria, ràng buộc, failure modes.
2. Viết/cập nhật spec chi tiết.
3. `writing-plans` để tạo kế hoạch theo bước, có rollback và verification.
4. Tạo worktree/branch riêng khi phù hợp.
5. TDD đầy đủ cho logic có thể kiểm thử (dùng fake `IotSecureStore`, fake HTTP, không gọi server thật).
6. Dùng subagent chỉ khi có các phần việc độc lập, thực sự chạy song song được.
7. Review code và security review.
8. Chạy test mục tiêu, toàn bộ `flutter test`, `flutter analyze`, build `flutter build apk --release`
   khi đụng native/dependency và kiểm tra regression.
9. `verification-before-completion` với bằng chứng lệnh đã chạy và kết quả.
10. Cập nhật `tracking/progress-log.md` sau từng mốc chính.
11. Dùng `finishing-a-development-branch` khi đóng nhánh feature.

## 5. Quy tắc tự phân loại khi người dùng không ghi AUS

Ưu tiên mức nhẹ nhất vẫn đảm bảo an toàn:

- `AUS-0`: chỉnh sửa cô lập, expected behavior rõ, không đổi cấu trúc hoặc luồng nghiệp vụ.
- `AUS-1`: thay đổi giới hạn trong một module, dùng pattern có sẵn, rủi ro regression thấp.
- `AUS-2`: tính năng mới, cơ chế nền mới hoặc thay đổi đi qua nhiều layer nhưng không đổi kiến trúc.
- `AUS-3`: có auth/token, lưu trữ an toàn, TLS, native/dependency nền tảng, số liệu tài chính
  hoặc rủi ro dữ liệu.

Ví dụ phân loại:

- Đổi chữ trên nút `Thực hiện` của báo cáo thủ công → `AUS-0`.
- Giữ giá trị dropdown khi bàn phím mở làm rebuild form → `AUS-1`.
- Sửa ảnh xem trước văn bản bị nhòe trong một widget → `AUS-1`.
- Tạo lại ảnh xem trước PDF ở nền bằng PDFium, có hàng đợi và cache → `AUS-2`.
- Thêm module mới trên home kèm API và màn hình → `AUS-2`.
- Chuyển token từ `shared_preferences` sang Keystore/Keychain, hoặc thay pin chứng chỉ → `AUS-3`.

Khi không chắc, chọn mức AN TOÀN HƠN (cao hơn), không đoán liều để tiết kiệm token.

## 6. Chính sách tối ưu token và phạm vi

- Đọc từ hẹp đến rộng: file trực tiếp → dependency trực tiếp → tài liệu module → repository rộng.
- Không đọc toàn repository nếu chưa có lý do kỹ thuật cụ thể.
- Không đọc/sửa thư mục sinh ra: `build/`, `.dart_tool/`, `ios/Pods/`, `GeneratedPluginRegistrant.*`,
  `.flutter-plugins*`, `*.log`, `replay_pid*.log`, `hs_err_pid*.log`.
- `third_party/` là bản fork plugin; chỉ đọc khi lỗi nằm trong plugin đó.
- Không lặp lại nội dung đã có trong spec, plan hoặc file vừa đọc; chỉ tóm tắt phần cần quyết định.
- Không tạo tài liệu mới ở AUS-0/AUS-1 trừ khi người dùng yêu cầu.
- Không dùng subagent để làm một task tuần tự hoặc quá nhỏ.
- Không refactor, đổi tên hoặc `dart format` hàng loạt ngoài phạm vi yêu cầu.
- Ưu tiên patch nhỏ, có thể review và rollback dễ dàng.
- Khi đã đủ bằng chứng hoàn thành, dừng; không tự mở rộng sang “cải thiện thêm”.
- Không hy sinh tính đúng đắn hoặc bảo mật chỉ để giảm token.

## 7. Quy tắc TDD và verification theo rủi ro

- Thay đổi text/style/docs: không bắt buộc test mới; phải chạy `flutter analyze` cho file đã sửa.
- Bug có thể tái hiện: ưu tiên viết regression test fail trước khi sửa.
- Logic nghiệp vụ mới (parse dữ liệu, tính toán, hàng đợi): phải có test trước hoặc song song với
  implementation theo red → green → refactor.
- Layout/responsive: widget test với viewport hẹp 320–360px, tablet, xoay ngang và cỡ chữ hệ thống 200%
  (xem `test/report_table_responsive_test.dart`, `test/manual_report_menu_responsive_test.dart`).
- Gọi API/ghi file: kiểm tra timeout, mã lỗi non-200, header `iot-upgrade`, dữ liệu rỗng/biên.
- Auth/token/TLS/lưu trữ an toàn/số liệu tài chính: bắt buộc test positive, negative và boundary case
  (xem `test/secure_storage_test.dart`, `test/pinned_http_overrides_test.dart`).
- Test phải đi qua đúng hàm mà app gọi, không chỉ hàm nội bộ bên trong.
- Không tuyên bố “Done”, “đã pass” hoặc “không lỗi” nếu chưa chạy lệnh kiểm tra tương ứng.
- Nếu không thể chạy test (cần thiết bị thật, PDF mẫu, `pdfium.dll`...), phải nêu rõ test nào chưa chạy
  và lý do.

## 8. Skill Superpowers và phạm vi sử dụng

Superpowers vẫn được bật cho project, nhưng skill phải được gọi theo mức AUS và nhu cầu thực tế.

| Skill | Khi sử dụng |
| --- | --- |
| `brainstorming` | AUS-2 khi yêu cầu mơ hồ; bắt buộc cho AUS-3 |
| `writing-plans` | AUS-2/AUS-3 khi cần plan file |
| `executing-plans` | Khi đang thực thi plan đã có |
| `test-driven-development` | Logic nghiệp vụ mới hoặc bug có thể tái hiện |
| `systematic-debugging` | Bug chưa rõ nguyên nhân; không cần cho lỗi hiển nhiên đã xác định |
| `verification-before-completion` | AUS-1 trở lên; AUS-0 dùng verification mục tiêu tương đương |
| `requesting-code-review` / `receiving-code-review` | AUS-3 hoặc AUS-2 có rủi ro đáng kể |
| `dispatching-parallel-agents` / `subagent-driven-development` | Chỉ AUS-3, khi có phần việc độc lập |
| `finishing-a-development-branch` | Khi thực sự dùng branch/worktree cho feature |

Project chưa có skill riêng trong `.claude/skills/`. Quy tắc kiến trúc ở mục 9, checklist bảo mật ở
mục 10 và bài học trong `skill.md` thay thế cho các skill đó.

## 9. Nguyên tắc kiến trúc

Luồng một chiều: `view` → `viewmodel` → `service` → `model`.

- `view/` (màn hình, widget): chỉ dựng UI và gọi viewmodel. Không gọi `http` trực tiếp, không parse JSON.
- `viewmodel/` (`*_stream.dart`, `ChangeNotifier`): giữ state, điều phối gọi service, chuyển dữ liệu
  cho UI. Provider dùng chung khai báo ở `lib/app/provider/provider.dart`.
- `service/` (`*_service.dart`): gọi backend theo pattern hiện có: URL từ `IOT_REQUEST_URL`, header
  `Authorization: Bearer <wsToken>` và `Vendor: base64(IOT_APP_VERSION)`, có `.timeout(...)`, non-200 ném
  `IotException(code, error: headers['iot-upgrade'])`, parse JSON lớn bằng `compute(...)`.
- `model/`: `fromJson`, không chứa logic UI. Session đi qua `IotSharedPreferences` (bọc `IotSecureStore`).
- `resource/`: route (`routes.dart`), màu, font, icon, chuỗi, emoji. Hằng số dùng chung đặt ở đây,
  không hard-code trong view.
- `utility/`: helper chung (mạng, thời gian, chọn ngày).
- Không tạo `Future` gọi API trong `build()`. Tạo và cache `Future` trong `initState()`; hàm khởi tạo state
  từ API phải idempotent để rebuild không xóa dữ liệu người dùng đang nhập.
- Không dùng `BoxFit.fill` cho ảnh tài liệu; tỉ lệ luôn lấy từ chính ảnh.
- Kích thước: `flutter_screenutil` (design `1080x1920`) có thể phóng quá mức khi xoay ngang. Tính theo cạnh
  ngắn của viewport, dùng `LayoutBuilder`/`TextPainter` và giới hạn min/max.
- Callback `whenComplete` dùng thân `{ ...; }`, không trả về Future (tránh tự đợi chính mình).
- Ưu tiên tái sử dụng service/widget hiện có, nhưng không tạo abstraction sớm cho một trường hợp đơn lẻ.
- Project chưa có `analysis_options.yaml`/`flutter_lints`; `flutter analyze` chạy rule mặc định. Dùng
  `dart format` cho code mới hoặc đoạn đang sửa; không format lại file cũ hàng loạt.
- Không thêm package mới nếu chưa chứng minh cần thiết và chưa kiểm tra ràng buộc mạng nội bộ. Plugin đã
  fork trong `third_party/` (qua `path:`/`dependency_overrides`) phải giữ đồng bộ khi nâng bản gốc.

## 10. Checklist bảo mật (bắt buộc rà ở AUS-2/AUS-3 có liên quan)

- Không lưu token, email, định danh người dùng bằng `shared_preferences` hoặc file plaintext; dùng
  `IotSecureStore` (Android Keystore AES-256-GCM, iOS Keychain `WhenUnlockedThisDeviceOnly`).
- Dữ liệu session thiếu hoặc không giải mã được: fail closed, yêu cầu đăng nhập lại.
- Không đặt `badCertificateCallback` trả về `true`. Chỉ pin đúng DER của host/cổng API qua
  `IotPinnedHttpOverrides`; khi server đổi chứng chỉ thì thay file `.pem` trong `assets/certificates/`.
- Giữ tắt cleartext traffic và backup ứng dụng trên Android; giữ ATS nghiêm ngặt trên iOS.
- Không log/`print` token, header `Authorization`, nội dung tin nhắn hoặc số liệu khách hàng.
- File tải về/ảnh cache để trong thư mục tạm của app (`tmp/IOT/<messageId>/...`); làm sạch tên file từ
  server trước khi ghi, không cho phép `..` hoặc đường dẫn tuyệt đối.
- Payload FCM và dữ liệu server là dữ liệu không tin cậy: kiểm tra `messageType` và field trước khi điều
  hướng hoặc hiển thị.
- Không commit secret mới (keystore, mật khẩu ký, API key). `vbs_dng_msp.jks`,
  `GoogleService-Info*.plist`, `google-services.json` là file nhạy cảm; không sửa hay di chuyển khi
  chưa được yêu cầu.

## 11. Cấu trúc thư mục chính

Xem đầy đủ tại `HUONG_DAN_DU_AN.md` §3 và §6. Tóm tắt:

- `lib/main.dart` — khởi tạo: `IotPinnedHttpOverrides`, `pdfrxFlutterInitialize`, Firebase, đọc session,
  `MultiProvider`, chọn `/login` hoặc `/home`.
- `lib/app/view|viewmodel|service|model|resource|utility|provider` — code ứng dụng theo module
  `account`, `report`, `im`, `eoffice`, `room`, `conduct`, `main`, `widget`.
- `lib/US.MD` — danh sách User Story chính thức.
- `assets/images|fonts|certificates` — tài nguyên nội bộ đóng gói cùng app.
- `android/` (`org.vbspdng.msp`), `ios/Runner/` — native, gồm bridge `secure_storage`.
- `third_party/` — plugin fork: `android_id`, `device_info_plus`, `firebase_auth`, `firebase_messaging`,
  `pdfium_flutter`.
- `test/` — test `flutter_test`.
- `docs/modules/` — đặc tả tính năng theo module (tạo khi có AUS-2/AUS-3 đầu tiên).
- `plans/` — kế hoạch triển khai tương ứng với spec.
- `tracking/progress-log.md` — nhật ký code, test và commit (tạo khi có thay đổi code đầu tiên).
- `skill.md` — bài học kỹ thuật; bổ sung khi gặp lỗi khó hoặc lặp lại.

## 12. Trạng thái hiện tại

- Các module báo cáo thủ công, số liệu định kỳ, PMC/WAN, MSP, eOffice, thi nghiệp vụ, tài khoản đã chạy
  thực tế — xem `HUONG_DAN_DU_AN.md` §7.
- Bảo mật đã làm: session lưu Keystore/Keychain (`lib/app/model/secure_storage.dart`), pin chứng chỉ API
  (`lib/app/viewmodel/pinned_http_overrides.dart` + `assets/certificates/iot_server_2024.pem`).
- Responsive: bảng báo cáo tự tính chiều cao hàng/độ rộng cột; menu báo cáo con thu gọn khi xoay ngang.
- Ảnh xem trước văn bản trong tin nhắn: giữ tỉ lệ (`reply_download_file_widget.dart`) và tạo lại vùng
  “tiêu đề + Sao gửi … Lưu VT” bằng PDFium (`lib/app/service/im/pdf_preview_service.dart`).
- Build Android trên Windows dùng `third_party/pdfium_flutter` (chép thay symlink) qua
  `dependency_overrides`; khi nâng `pdfrx` phải đồng bộ bản này.
- `intl` đang bị ghim `0.17.0` qua `dependency_overrides`; không nâng khi chưa kiểm tra toàn bộ format ngày.
- Backend: `IOT_REQUEST_URL = https://117.2.155.59:2024/` (chỉ HTTPS). Cổng `2025` là trang nâng cấp HTTP,
  không phải API.

Khi nhận US mới, xử lý trong một lượt theo workflow AUS tương ứng. Không dừng chờ xác nhận giữa
PLAN và CODE trừ khi người dùng yêu cầu dừng hoặc có mơ hồ ảnh hưởng trực tiếp đến tính đúng đắn,
bảo mật hay dữ liệu.

## 13. Cách giao và nhận task theo US/AUS

Format khuyến nghị khi người dùng giao việc:

```text
AUS-1 | US-7
Mục tiêu: Thêm bộ lọc trạng thái đã đọc/chưa đọc cho danh sách số liệu định kỳ.
Phạm vi: Chỉ module report/auto_report, dùng pattern hiện có.
Hoàn thành khi: Lọc đúng, test liên quan pass, badge bottom navigation không đổi.
```

Có thể dùng format ngắn khi yêu cầu đã rõ:

```text
AUS-0 thực hiện US-6: đổi nội dung thông báo khi mất kết nối mạng.
```

Khi nhận task:

- Nếu có cả `AUS-*` và `US-*`: dùng AUS để chọn workflow, dùng US để xác định nghiệp vụ.
- Nếu chỉ có `US-*`: tìm đúng story trong `lib/US.MD`, tự phân loại AUS rồi thực hiện.
- Nếu chỉ có `AUS-*`: thực hiện yêu cầu trực tiếp theo mức đó; không tự suy đoán một US khác.
- Chỉ đọc story được yêu cầu và dependency trực tiếp; không xử lý các US kế tiếp trong cùng file.
- Nếu một US có nhiều phần, chỉ thực hiện phần được yêu cầu, trừ khi người dùng nói làm toàn bộ US.
- Nếu acceptance criteria đã đủ rõ, tiếp tục xuyên suốt workflow; không dừng giữa PLAN và CODE.
- Chỉ hỏi lại khi thiếu thông tin có thể làm sai nghiệp vụ, gây mất dữ liệu hoặc tạo lỗ hổng bảo mật.

## 14. Quy tắc báo cáo hoàn thành

Báo cáo ngắn gọn theo cấu trúc:

1. Mức AUS đã dùng.
2. File đã thay đổi.
3. Hành vi đã hoàn thành.
4. Lệnh kiểm tra/test đã chạy và kết quả.
5. Rủi ro hoặc việc chưa xác minh (ví dụ chưa chạy trên thiết bị iOS thật), nếu có.

Không trình bày lại toàn bộ quá trình suy nghĩ. Không tuyên bố thành công nếu thiếu bằng chứng.

## 15. Lệnh thường dùng

Flutter có sẵn tại `C:\flutter\bin` (Flutter 3.38.9 stable).

```bash
flutter pub get
flutter analyze
flutter analyze lib/app/view/im/reply/reply_download_file_widget.dart   # chỉ file đã sửa
flutter test
flutter test test/report_table_responsive_test.dart                     # một file test
flutter run
flutter build apk --release
flutter build ios --release        # chỉ trên macOS
```

Test ảnh xem trước với PDF thật (không chạy mặc định, cần thư mục PDF mẫu và `pdfium.dll` mà
`pdfrxInitialize()` tải về `%LOCALAPPDATA%\pdfrx`):

```bash
IOT_PDF_SAMPLES=<thư mục PDF> PDFIUM_PATH=<pdfium.dll> flutter test test/pdf_preview_service_test.dart
flutter test test/pdf_preview_regenerate_test.dart   # chạy riêng, không chung với testWidgets
```

Debug đăng nhập Android: `adb logcat` lọc `FirebaseAuth`, `GoogleSignIn`, `IOT login`, `loginWithGmail`,
`ApiException`.

## User Story (`lib/US.MD`)

Người dùng thêm user-story mới vào `lib/US.MD` — hoặc gửi thẳng nội dung US-xxx trong chat.
**Nếu người dùng gửi nội dung chi tiết của một US-xxx trong chat (không phải chỉ nói tắt "làm US-xxx"),
luôn ghi/append vào `lib/US.MD` TRƯỚC (giữ nguyên văn, đúng định dạng `US-xxx:\n<nội dung>` như các US
trước), rồi mới bắt đầu xử lý.** `lib/US.MD` là hồ sơ chính thức lâu dài của dự án, không được chỉ tồn
tại trong lịch sử chat.

Khi có US mới:

1. Đọc kỹ US, brainstorm/hỏi lại nếu chưa rõ nghiệp vụ hoặc phạm vi bảo mật (**vẫn hỏi** dù đã được uỷ
   quyền "toàn quyền" — chỉ tự quyết theo khuyến nghị cho các điểm KHÔNG phải nghiệp vụ/bảo mật cốt lõi).
2. Tự phân loại AUS (mục 5), nêu 1 dòng lý do.
3. Làm theo đúng quy trình của mức AUS đó.
4. Code theo TDD tương xứng, track theo mốc, commit khi xong.

## Khi thiếu thông tin

Nếu thông tin không đủ để tiếp tục an toàn — đặc biệt bất cứ điều gì liên quan tới bảo mật, token/session
hoặc số liệu nghiệp vụ ngân hàng — dừng lại và hỏi người dùng, không tự suy đoán, bất kể mức AUS nào.
