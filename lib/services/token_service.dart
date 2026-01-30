import 'package:shared_preferences/shared_preferences.dart';

/// Service quản lý TOKEN AUTHENTICATION
/// 
/// NHIỆM VỤ:
/// - Lưu token vào local storage (SharedPreferences)
/// - Đọc token từ local storage
/// - Xóa token khi logout
/// - Kiểm tra xem user đã login chưa
/// 
/// SỬ DỤNG:
/// ```dart
/// final tokenService = TokenService();
/// 
/// // Sau khi login thành công
/// await tokenService.saveToken('abc123xyz');
/// 
/// // Lấy token để gửi request
/// final token = await tokenService.getToken();
/// 
/// // Kiểm tra đã login chưa
/// final isLoggedIn = await tokenService.hasToken();
/// 
/// // Logout
/// await tokenService.clearToken();
/// ```
class TokenService {
  // Key để lưu token trong SharedPreferences
  // Static const để tránh typo và dễ maintain
  static const String _tokenKey = 'auth_token';

  /// Lấy token từ SharedPreferences
  /// 
  /// TRƯỜNG HỢP SỬ DỤNG:
  /// - Khi cần gửi authenticated request
  /// - Khi check user đã login chưa
  /// - Trong Interceptor để tự động thêm vào header
  /// 
  /// TRẢ VỀ:
  /// - String token nếu tồn tại
  /// - null nếu không có token (chưa login)
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      
      if (token != null && token.isNotEmpty) {
        print('✅ [TokenService] Token tìm thấy');
        // Log một phần token để bảo mật (chỉ 20 ký tự đầu)
        print('📂 [TokenService] Token: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      } else {
        print('⚠️ [TokenService] Không tìm thấy token');
      }
      
      return token;
    } catch (e) {
      print('❌ [TokenService] Lỗi khi đọc token: $e');
      return null;
    }
  }

  /// Lưu token vào SharedPreferences
  /// 
  /// GỌI HÀM NÀY SAU KHI:
  /// - Login thành công từ API
  /// - Refresh token thành công
  /// - Social login thành công (Google, Facebook...)
  /// 
  /// THAM SỐ:
  /// - token: Chuỗi token nhận được từ server
  /// 
  /// TRẢ VỀ:
  /// - true nếu lưu thành công
  /// - false nếu thất bại
  /// 
  /// VÍ DỤ TOKEN:
  /// - JWT: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  /// - Bearer token: "abc123def456xyz789"
  /// - OAuth token: "ya29.a0AfH6SMBx..."
  Future<bool> saveToken(String token) async {
    try {
      if (token.isEmpty) {
        print('⚠️ [TokenService] Token rỗng - không lưu');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(_tokenKey, token);
      
      if (result) {
        print('✅ [TokenService] Lưu token thành công');
        print('📂 [TokenService] Key: $_tokenKey');
        print('🔐 [TokenService] Token: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      } else {
        print('⚠️ [TokenService] setString trả về false');
      }
      
      return result;
    } catch (e) {
      print('❌ [TokenService] Lỗi khi lưu token: $e');
      return false;
    }
  }

  /// Xóa token khỏi SharedPreferences
  /// 
  /// GỌI HÀM NÀY KHI:
  /// - User nhấn nút Logout
  /// - Token hết hạn (401 Unauthorized)
  /// - Server trả về lỗi authentication
  /// - Force logout từ server
  /// - Chuyển tài khoản
  /// 
  /// SAU KHI XÓA:
  /// - User bị coi là chưa login
  /// - Mọi request không có Authorization header
  /// - App nên redirect về màn hình login
  /// 
  /// TRẢ VỀ:
  /// - true nếu xóa thành công
  /// - false nếu thất bại
  Future<bool> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.remove(_tokenKey);
      
      if (result) {
        print('✅ [TokenService] Token đã được xóa');
        print('🚪 [TokenService] User cần login lại');
      } else {
        print('⚠️ [TokenService] remove trả về false');
      }
      
      return result;
    } catch (e) {
      print('❌ [TokenService] Lỗi khi xóa token: $e');
      return false;
    }
  }

  /// Kiểm tra xem có token hay không
  /// 
  /// CÁCH SỬ DỤNG:
  /// - Check user đã login chưa
  /// - Quyết định có cho vào app hay redirect về login
  /// - Show/hide các tính năng cần authentication
  /// 
  /// VÍ DỤ:
  /// ```dart
  /// if (await tokenService.hasToken()) {
  ///   // User đã login - cho vào home screen
  ///   Navigator.pushReplacementNamed(context, '/home');
  /// } else {
  ///   // Chưa login - về login screen
  ///   Navigator.pushReplacementNamed(context, '/login');
  /// }
  /// ```
  /// 
  /// TRẢ VỀ:
  /// - true nếu có token (user đã login)
  /// - false nếu không có token (chưa login)
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// [DEMO/TEST ONLY] Lưu token giả để test
  /// 
  /// ⚠️ CHỈ DÙNG ĐỂ TEST - KHÔNG dùng trong production
  /// 
  /// Hàm này tạo một JWT token giả với format hợp lệ
  /// để test authentication flow mà không cần API thật
  /// 
  /// CÁCH DÙNG:
  /// ```dart
  /// // Lưu token giả
  /// await tokenService.saveDemoToken();
  /// 
  /// // Test API calls với token
  /// await networkService.fetchUsers();
  /// 
  /// // Xóa token khi test xong
  /// await tokenService.clearToken();
  /// ```
  Future<void> saveDemoToken() async {
    // JWT token giả với format chuẩn (header.payload.signature)
    const demoToken = 
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkRlbW8gVXNlciIsImVtYWlsIjoiZGVtb0BleGFtcGxlLmNvbSIsInJvbGUiOiJ1c2VyIiwiaWF0IjoxNTE2MjM5MDIyfQ.'
        'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
    
    await saveToken(demoToken);
    
    print('');
    print('🎭 ═══════════════════════════════════════════');
    print('🎭 [DEMO MODE] Token giả đã được lưu');
    print('📝 Payload giải mã:');
    print('   - sub: "1234567890"');
    print('   - name: "Demo User"');
    print('   - email: "demo@example.com"');
    print('   - role: "user"');
    print('🧪 Token này CHỈ để test local');
    print('🚫 Trong production: Token từ API login thật');
    print('🎭 ═══════════════════════════════════════════');
    print('');
  }
}
