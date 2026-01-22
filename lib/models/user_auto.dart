import 'package:json_annotation/json_annotation.dart';

// Đây là ví dụ về AUTOMATED JSON SERIALIZATION
// Sử dụng thư viện json_serializable để TỰ ĐỘNG generate code

// Quan trọng: Dòng này link tới file generated (.g.dart)
// File này sẽ được tạo tự động bởi build_runner
part 'user_auto.g.dart';

/// Model User sử dụng Automated Serialization với json_serializable
/// 
/// Ưu điểm của cách này:
/// 1. An toàn kiểu dữ liệu: Compiler kiểm tra kiểu dữ liệu lúc compile-time
/// 2. Tự động generate code: Không cần viết tay fromJson/toJson
/// 3. Giảm lỗi: Code được generate tự động, giảm thiểu lỗi chính tả
/// 4. Dễ bảo trì: Thêm field mới chỉ cần khai báo, chạy build_runner là xong
/// 5. Chuẩn hóa: Code generation đảm bảo pattern nhất quán trong toàn project
/// 
/// Hướng dẫn sử dụng:
/// Sau khi tạo file này, chạy lệnh sau trong terminal để generate code:
/// 
/// ```bash
/// dart run build_runner build --delete-conflicting-outputs
/// ```
/// 
/// Hoặc để watch và tự động rebuild khi có thay đổi:
/// ```bash
/// dart run build_runner watch --delete-conflicting-outputs
/// ```
@JsonSerializable() // Annotation báo với build_runner: generate code cho class này
class User {
  final int id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  // Factory constructor để parse JSON
  // Lưu ý: Hàm _$UserFromJson được generate tự động trong file user_auto.g.dart
  // Chúng ta chỉ cần gọi nó, không cần viết implementation
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  // Method để convert object sang JSON
  // Tương tự, _$UserToJson cũng được generate tự động
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // Helper method để hiển thị thông tin User
  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email}';
  }
}

