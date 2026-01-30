import 'package:dio/dio.dart';
import 'token_service.dart';

/// Dio Interceptor để TỰ ĐỘNG THÊM TOKEN vào mọi request
/// 
/// CÁCH HOẠT ĐỘNG:
/// 1. TRƯỚC MỖI REQUEST (onRequest):
///    - Lấy token từ TokenService
///    - Thêm "Authorization: Bearer <token>" vào header
///    - Cho phép request tiếp tục
/// 
/// 2. KHI NHẬN RESPONSE (onResponse):
///    - Log status code để debug
///    - Có thể xử lý response trước khi trả về app
/// 
/// 3. KHI CÓ LỖI (onError):
///    - Xử lý 401 Unauthorized (token hết hạn)
///    - Tự động xóa token không hợp lệ
///    - Có thể thử refresh token và retry request
/// 
/// LỢI ÍCH:
/// - Không cần thêm token thủ công cho từng request
/// - Tự động handle token hết hạn
/// - Code app đơn giản, chỉ gọi API bình thường
/// - Centralized authentication logic
class AuthInterceptor extends Interceptor {
  final TokenService _tokenService;

  /// Constructor nhận TokenService instance
  /// 
  /// VÍ DỤ:
  /// ```dart
  /// final tokenService = TokenService();
  /// final authInterceptor = AuthInterceptor(tokenService);
  /// 
  /// final dio = Dio()..interceptors.add(authInterceptor);
  /// ```
  AuthInterceptor(this._tokenService);

  /// Được gọi TRƯỚC MỖI REQUEST
  /// 
  /// NHIỆM VỤ:
  /// - Lấy token từ storage
  /// - Thêm vào Authorization header
  /// - Log để debug
  /// 
  /// LƯU Ý:
  /// - Hàm này ASYNC vì phải đọc từ SharedPreferences
  /// - Không block main thread
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    print('');
    print('📤 [AuthInterceptor] REQUEST bắt đầu');
    print('   🌐 URL: ${options.uri}');
    print('   🔧 Method: ${options.method}');

    // Lấy token từ TokenService
    final token = await _tokenService.getToken();

    if (token != null && token.isNotEmpty) {
      // Thêm token vào Authorization header với format "Bearer <token>"
      // Đây là format chuẩn mà hầu hết API yêu cầu
      options.headers['Authorization'] = 'Bearer $token';
      
      print('   🔐 Token đã thêm vào header');
      print('   📋 Authorization: Bearer ${token.substring(0, token.length > 15 ? 15 : token.length)}...');
    } else {
      print('   ⚠️ Không có token - Request không có authentication');
    }

    print('');
    
    // Cho phép request tiếp tục
    // PHẢI gọi handler.next() nếu không request sẽ bị treo
    handler.next(options);
  }

  /// Được gọi KHI NHẬN RESPONSE THÀNH CÔNG
  /// 
  /// NHIỆM VỤ:
  /// - Log response để debug
  /// - Có thể modify response data nếu cần
  /// - Có thể lưu token mới nếu server trả về
  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    print('');
    print('📥 [AuthInterceptor] RESPONSE nhận được');
    print('   ✅ Status: ${response.statusCode}');
    print('   🌐 URL: ${response.requestOptions.uri}');
    print('');

    // Nếu server trả token mới trong response (ví dụ: refresh token)
    // có thể lưu lại ở đây
    // Example:
    // if (response.data['new_token'] != null) {
    //   _tokenService.saveToken(response.data['new_token']);
    // }

    // Cho phép response được trả về app
    handler.next(response);
  }

  /// Được gọi KHI REQUEST GẶP LỖI
  /// 
  /// NHIỆM VỤ:
  /// - Xử lý lỗi 401 Unauthorized (token hết hạn)
  /// - Xóa token không hợp lệ
  /// - Có thể thử refresh token
  /// - Có thể retry request với token mới
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    print('');
    print('❌ [AuthInterceptor] ERROR xảy ra');
    print('   🌐 URL: ${err.requestOptions.uri}');
    print('   🔢 Status Code: ${err.response?.statusCode}');
    print('   💬 Message: ${err.message}');

    // Xử lý đặc biệt cho lỗi 401 Unauthorized
    if (err.response?.statusCode == 401) {
      print('   🔒 401 UNAUTHORIZED - Token không hợp lệ hoặc hết hạn');
      print('');
      
      // Xóa token cũ không còn hợp lệ
      await _tokenService.clearToken();
      print('   🗑️ Token đã bị xóa');
      
      // ============================================================
      // TÙY CHỌN: Thử refresh token và retry request
      // ============================================================
      // 
      // Nếu app có refresh token, có thể làm như sau:
      // 
      // 1. Lấy refresh token
      // final refreshToken = await _tokenService.getRefreshToken();
      // 
      // 2. Gọi API refresh để lấy token mới
      // try {
      //   final dio = Dio();
      //   final response = await dio.post(
      //     'https://api.example.com/auth/refresh',
      //     data: {'refresh_token': refreshToken},
      //   );
      //   
      //   // 3. Lưu token mới
      //   final newToken = response.data['access_token'];
      //   await _tokenService.saveToken(newToken);
      //   
      //   // 4. Retry request ban đầu với token mới
      //   final options = err.requestOptions;
      //   options.headers['Authorization'] = 'Bearer $newToken';
      //   
      //   final retryResponse = await Dio().fetch(options);
      //   return handler.resolve(retryResponse);
      // } catch (e) {
      //   print('❌ Refresh token thất bại: $e');
      //   // Redirect về login screen
      // }
      // ============================================================
      
      print('   🚪 App nên redirect user về màn hình login');
    }

    print('');
    
    // Cho phép error được xử lý tiếp ở app
    handler.next(err);
  }
}
