# Flutter Demo: Xử lý Dữ liệu Cục bộ & Tích hợp REST API

## Nội dung cốt lõi

### 1. **Manual vs Automated JSON Serialization**
- Manual: `Post` model - Viết tay `fromJson`/`toJson`
- Automated: `User` model - Dùng `json_serializable`

### 2. **http vs Dio**
- `http`: Thư viện cơ bản, đơn giản
- `Dio`: Thư viện mạnh mẽ với Interceptors, Global Config

### 3. **Local Storage với SharedPreferences**
- Lưu theme preference (Dark/Light mode)
- Persistent data (không mất khi tắt app)

---

## Tech Stack

```yaml
Dependencies:
  - dio: ^5.4.2+1              # HTTP client mạnh mẽ
  - http: ^1.2.1               # HTTP client cơ bản
  - shared_preferences: ^2.2.3 # Local storage
  - json_annotation: ^4.9.0    # JSON codegen

Dev Dependencies:
  - build_runner: ^2.4.9       # Code generation
  - json_serializable: ^6.8.0  # JSON codegen
```

---

## Hướng dẫn Chạy Dự án

### Bước 1: Install Dependencies
```bash
flutter pub get
```

### Bước 2: Generate Code cho User Model
**QUAN TRỌNG**: Model `User` sử dụng `json_serializable`, cần generate code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Giải thích**:
- Lệnh này tạo file `lib/models/user_auto.g.dart`
- File này chứa implementation của `_$UserFromJson` và `_$UserToJson`
- `--delete-conflicting-outputs`: Xóa file cũ nếu có conflict

**Lưu ý**: Nếu thấy lỗi "Missing part" khi compile, nghĩa là bạn chưa chạy lệnh này!

### Bước 3: Run App
```bash
flutter run
```

Hoặc nhấn **F5** trong VS Code (với Flutter extension đã cài).

---

## Cấu trúc Dự án

```
lib/
├── main.dart                          # Entry point, Provider setup
├── models/
│   ├── post_manual.dart              # Manual JSON serialization
│   ├── user_auto.dart                # Automated với json_serializable
│   └── user_auto.g.dart              # Generated code (tự động)
├── services/
│   ├── network_service.dart          # So sánh http vs Dio
│   └── theme_service.dart            # SharedPreferences
└── screens/
    └── home_screen.dart              # UI với 2 tabs
```

---

## UI Features

### Tab 1: Posts (Manual + http)
- Hiển thị danh sách Posts từ JSONPlaceholder
- Badge màu cam: "Manual"
- Demo FutureBuilder với loading/error states

### Tab 2: Users (Auto + Dio)
- Hiển thị danh sách Users từ JSONPlaceholder
- Badge màu xanh: "Auto"
- Xem Dio logs trong console

### Theme Toggle
- Icon 🌙 (Light mode) hoặc ☀️ (Dark mode)
- Chuyển đổi mượt mà
- Lưu vào SharedPreferences

---

## 📚 Tài liệu Tham khảo

### Official Documentation
- [Flutter JSON Serialization](https://docs.flutter.dev/data-and-backend/json)
- [Dio Package](https://pub.dev/packages/dio)
- [SharedPreferences](https://pub.dev/packages/shared_preferences)
- [Provider](https://pub.dev/packages/provider)

### API Endpoint
- [JSONPlaceholder](https://jsonplaceholder.typicode.com/) - Fake REST API for testing

---

