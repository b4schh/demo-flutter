// Đây là ví dụ về MANUAL JSON SERIALIZATION
// Cách này yêu cầu chúng ta tự viết tay các hàm fromJson và toJson

/// Model Post sử dụng Manual Serialization
///
/// Nhược điểm của cách này:
/// 1. Dễ gặp lỗi chính tả: Nếu viết sai tên key như 'titel' thay vì 'title', chỉ phát hiện lỗi khi runtime, không phát hiện lúc compile
/// 2. Tốn công bảo trì: Khi thêm/xóa field, phải nhớ cập nhật cả fromJson và toJson
/// 3. Code dài dòng: Với model có nhiều field (10-20 fields), code rất dài
/// 4. Không type-safe: Compiler không kiểm tra được kiểu dữ liệu khi parse JSON
/// 5. Khó debug: Lỗi thường chỉ xuất hiện khi chạy app, không có cảnh báo trước
class Post {
  final int id;
  final String title;
  final String body;

  Post({
    required this.id,
    required this.title,
    required this.body,
  });

  // Hàm fromJson - Chuyển từ JSON (Map) sang Object
  // Lưu ý: Phải tự viết tay và dễ sai lỗi chính tả tên key
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      // Nếu viết sai 'id' thành 'idd' -> lỗi runtime, không báo lỗi compile
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      // Nếu quên một field -> lỗi runtime
    );
  }

  // Hàm toJson - Chuyển từ Object sang JSON (Map)
  // Cũng phải viết tay, rất dễ quên field hoặc viết sai key name
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      // Phải đảm bảo key name khớp với API response
    };
  }

  // Helper method để hiển thị thông tin Post
  @override
  String toString() {
    return 'Post{id: $id, title: $title}';
  }
}