# Gõ Tiếng Việt - HarmonyOS Keyboard

Dự án **Gõ Tiếng Việt** là một ứng dụng bàn phím (Input Method) dành cho hệ điều hành HarmonyOS / OpenHarmony, hỗ trợ gõ tiếng Việt (ví dụ: kiểu gõ Telex) với giao diện tùy chỉnh và tích hợp nhiều tiện ích.
App được upload trên cửa hàng AppGallery  [tại](https://appgallery.huawei.com/app/detail?id=com.example.gotiengviet&channelId=SHARE&source=appshare)
[img](download.jpeg)
## 🌟 Tính năng chính

- **Bàn phím Tiếng Việt:** Hỗ trợ nhập liệu tiếng Việt với kiểu gõ Telex mượt mà và chính xác.
- **Tùy chỉnh giao diện:** Hỗ trợ cấu hình màu sắc, bố cục bàn phím và giao diện.
- **Quản lý Clipboard:** Tích hợp đọc/dán nhanh nội dung từ bộ nhớ tạm (Pasteboard).
- **Hỗ trợ Microphone:** (Dự kiến/Tích hợp) nhập liệu bằng giọng nói.
- **Auto-patching scripts:** Đi kèm với hệ thống script Python để hỗ trợ tự động hóa, patch mã nguồn (.ets) và chỉnh sửa giao diện bàn phím linh hoạt trong quá trình phát triển.

## 📁 Cấu trúc dự án

Dự án được xây dựng theo cấu trúc của một ứng dụng HarmonyOS tiêu chuẩn sử dụng model Stage:

- `AppScope/`: Chứa các cấu hình toàn cục của ứng dụng (`app.json5`), tài nguyên logo, tên ứng dụng.
- `Stage/`: Module chính (Entry module) của ứng dụng.
  - `src/main/ets/`: Chứa mã nguồn TypeScript / ArkTS (.ets).
    - `pages/`: Các màn hình giao diện ứng dụng chính và giao diện cấu hình.
    - `telex/`: Các thành phần cốt lõi của bàn phím, bao gồm `GoTiengVietService` (Input Method Service), xử lý gõ phím, và UI của bàn phím.
  - `src/main/module.json5`: Khai báo thông tin module, phân quyền và extension ability cho bàn phím.
- `*.py`: Các script Python để tự động hoá, vá lỗi và tạo mã tự động cho bàn phím (VD: `patch_keyboard_page.py`, `patch_index.py`, `patch_keyboard_colors.py`...).
- `build-profile.json5`, `hvigorfile.ts`, `oh-package.json5`: Các tập tin cấu hình build của công cụ Hvigor và Ohpm.

## ⚙️ Yêu cầu hệ thống

- **IDE:** [DevEco Studio](https://developer.harmonyos.com/en/develop/deveco-studio) (phiên bản mới nhất hỗ trợ ArkTS/Stage model).
- **Ngôn ngữ:** ArkTS / TypeScript.
- **Môi trường Python:** Cần cài đặt Python 3.x để chạy các script automation (nếu cần patch file).

## 🚀 Hướng dẫn cài đặt và chạy

1. **Mở dự án:** Clone / Tải dự án về và mở bằng **DevEco Studio**.
2. **Cập nhật Dependency:** Đợi DevEco Studio tự động đồng bộ dự án và tải về các dependency qua `ohpm`.
3. **Cấu hình chữ ký (Signature):** Vào `File > Project Structure > Signing Configs` và thiết lập chữ ký cho dự án (hoặc sử dụng file `keystore.p12`, `App_Release_ProfileRelease.p7b` đã có sẵn).
4. **Chạy ứng dụng:** Kết nối thiết bị thực hoặc khởi động Emulator, sau đó nhấn **Run** (Shift + F10) để build và cài đặt ứng dụng lên thiết bị.
5. **Kích hoạt bàn phím:** Trên thiết bị, vào *Cài đặt > Hệ thống > Ngôn ngữ & Phương thức nhập* để bật bàn phím "Gõ Tiếng Việt" và đặt làm bàn phím mặc định.

## 🛡️ Quyền truy cập (Permissions)

Ứng dụng yêu cầu một số quyền cơ bản trong quá trình sử dụng:
- `ohos.permission.INTERNET`: Yêu cầu cho các tính năng trực tuyến.
- `ohos.permission.MICROPHONE`: Dùng để nhận diện giọng nói (Voice Input).
- `ohos.permission.READ_PASTEBOARD`: Hỗ trợ tính năng đọc nhanh và dán nội dung từ bộ nhớ tạm.

---
*Dự án phát triển nội bộ - Vui lòng không chia sẻ mã nguồn khi chưa được phép.*
