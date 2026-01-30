import 'package:dio/dio.dart';

/// Helper class để XỬ LÝ DioException một cách TẬP TRUNG
/// 
/// TRÁNH VIỆC:
/// - Viết lại code xử lý lỗi cho mỗi API
/// - Copy-paste try-catch code nhiều lần
/// - Inconsistent error messages
/// 
/// CÁCH DÙNG:
/// ```dart
/// try {
///   final response = await _dio.get('/users');
///   return response.data;
/// } catch (e) {
///   throw DioErrorHandler.handle(e);
/// }
/// ```
class DioErrorHandler {
  /// Xử lý exception và trả về Exception với message rõ ràng
  /// 
  /// TỰ ĐỘNG PHÂN LOẠI LỖI:
  /// - Network errors (no internet, connection failed)
  /// - Timeout errors (connect, send, receive)
  /// - Server errors (4xx, 5xx)
  /// - Parse errors (invalid JSON)
  /// - Cancel errors (request bị hủy)
  /// 
  /// THAM SỐ:
  /// - error: Exception bắt được (có thể là DioException hoặc Exception khác)
  /// - customMessage: Message tùy chỉnh (optional)
  /// 
  /// TRẢ VỀ:
  /// - Exception với message rõ ràng, dễ hiểu cho user
  static Exception handle(dynamic error, {String? customMessage}) {
    // Log chi tiết để debug
    _logError(error);

    // Nếu là DioException, xử lý chi tiết
    if (error is DioException) {
      return _handleDioException(error, customMessage);
    }

    // Nếu là exception khác, trả về message generic
    return Exception(customMessage ?? 'Đã xảy ra lỗi không xác định: ${error.toString()}');
  }

  /// Xử lý DioException chi tiết theo từng loại
  static Exception _handleDioException(DioException error, String? customMessage) {
    switch (error.type) {
      // ========== CONNECTION ERRORS ==========
      
      case DioExceptionType.connectionTimeout:
        return Exception(
          customMessage ?? 
          'Kết nối quá lâu, vui lòng kiểm tra mạng và thử lại'
        );

      case DioExceptionType.sendTimeout:
        return Exception(
          customMessage ?? 
          'Gửi dữ liệu quá lâu, vui lòng thử lại'
        );

      case DioExceptionType.receiveTimeout:
        return Exception(
          customMessage ?? 
          'Server phản hồi quá chậm, vui lòng thử lại sau'
        );

      case DioExceptionType.connectionError:
        return Exception(
          customMessage ?? 
          'Không thể kết nối đến server. Kiểm tra kết nối mạng của bạn'
        );

      // ========== SERVER RESPONSE ERRORS ==========
      
      case DioExceptionType.badResponse:
        return _handleBadResponse(error, customMessage);

      // ========== REQUEST CANCELLED ==========
      
      case DioExceptionType.cancel:
        return Exception(
          customMessage ?? 
          'Yêu cầu đã bị hủy'
        );

      // ========== OTHER ERRORS ==========
      
      case DioExceptionType.badCertificate:
        return Exception(
          customMessage ?? 
          'Chứng chỉ SSL không hợp lệ'
        );

      case DioExceptionType.unknown:
      default:
        // Có thể là lỗi network, parse JSON, v.v.
        if (error.message?.contains('SocketException') ?? false) {
          return Exception(
            customMessage ?? 
            'Không có kết nối mạng'
          );
        }
        return Exception(
          customMessage ?? 
          'Lỗi không xác định: ${error.message}'
        );
    }
  }

  /// Xử lý lỗi từ server response (4xx, 5xx)
  static Exception _handleBadResponse(DioException error, String? customMessage) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    // Thử lấy error message từ response body nếu có
    String? serverMessage;
    if (responseData is Map<String, dynamic>) {
      // Thử các key thường dùng cho error message
      serverMessage = responseData['message'] ?? 
                     responseData['error'] ?? 
                     responseData['msg'];
    }

    switch (statusCode) {
      // ===== CLIENT ERRORS (4xx) =====
      
      case 400:
        return Exception(
          customMessage ?? 
          serverMessage ?? 
          'Yêu cầu không hợp lệ'
        );

      case 401:
        return Exception(
          customMessage ?? 
          serverMessage ?? 
          'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại'
        );

      case 403:
        return Exception(
          customMessage ?? 
          serverMessage ?? 
          'Bạn không có quyền truy cập'
        );

      case 404:
        return Exception(
          customMessage ?? 
          serverMessage ?? 
          'Không tìm thấy dữ liệu'
        );

      case 409:
        return Exception(
          customMessage ?? 
          serverMessage ?? 
          'Dữ liệu bị xung đột'
        );

      case 422:
        return Exception(
          customMessage ?? 
          serverMessage ?? 
          'Dữ liệu không hợp lệ'
        );

      case 429:
        return Exception(
          customMessage ?? 
          serverMessage ?? 
          'Quá nhiều yêu cầu. Vui lòng thử lại sau'
        );

      // ===== SERVER ERRORS (5xx) =====
      
      case 500:
        return Exception(
          customMessage ?? 
          'Lỗi server. Vui lòng thử lại sau'
        );

      case 502:
        return Exception(
          customMessage ?? 
          'Bad Gateway. Server tạm thời không khả dụng'
        );

      case 503:
        return Exception(
          customMessage ?? 
          'Server đang bảo trì. Vui lòng thử lại sau'
        );

      case 504:
        return Exception(
          customMessage ?? 
          'Gateway Timeout. Server phản hồi quá chậm'
        );

      // ===== OTHER STATUS CODES =====
      
      default:
        return Exception(
          customMessage ?? 
          serverMessage ?? 
          'Lỗi server ($statusCode)'
        );
    }
  }

  /// Log chi tiết error để debug (chỉ in ra console)
  static void _logError(dynamic error) {
    print('');
    print('🔴 ═══════════════════════════════════════════');
    print('🔴 [DioErrorHandler] ERROR CAUGHT');
    print('🔴 ═══════════════════════════════════════════');

    if (error is DioException) {
      print('📌 Error Type: ${error.type}');
      print('📌 Message: ${error.message}');
      print('📌 Status Code: ${error.response?.statusCode}');
      print('📌 Request URL: ${error.requestOptions.uri}');
      print('📌 Request Method: ${error.requestOptions.method}');
      
      if (error.response?.data != null) {
        print('📌 Response Data: ${error.response?.data}');
      }
      
      if (error.stackTrace != null) {
        print('📌 Stack Trace: ${error.stackTrace}');
      }
    } else {
      print('📌 Error: $error');
    }
    
    print('🔴 ═══════════════════════════════════════════');
    print('');
  }

  /// Helper method để WRAP API call với error handling
  /// 
  /// CÁCH DÙNG TỐT NHẤT:
  /// ```dart
  /// Future<List<User>> fetchUsers() async {
  ///   return await DioErrorHandler.handleApiCall(
  ///     apiCall: () => _dio.get('/users'),
  ///     parser: (data) => (data as List).map((json) => User.fromJson(json)).toList(),
  ///     customErrorMessage: 'Không thể tải danh sách người dùng',
  ///   );
  /// }
  /// ```
  /// 
  /// LỢI ÍCH:
  /// - Tự động try-catch
  /// - Tự động parse response
  /// - Tự động handle error
  /// - Code ngắn gọn, dễ đọc
  static Future<T> handleApiCall<T>({
    required Future<Response> Function() apiCall,
    required T Function(dynamic data) parser,
    String? customErrorMessage,
  }) async {
    try {
      final response = await apiCall();
      return parser(response.data);
    } catch (e) {
      throw handle(e, customMessage: customErrorMessage);
    }
  }
}
