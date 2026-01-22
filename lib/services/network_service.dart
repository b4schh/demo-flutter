import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../models/post_manual.dart';
import '../models/user_auto.dart';

// Class này demo SỰ KHÁC BIỆT giữa 2 thư viện networking:
// 1. http - Thư viện HTTP cơ bản từ Dart team
// 2. Dio - Thư viện HTTP mạnh mẽ, feature-rich cho production

class NetworkService {
  // Base URL của JSONPlaceholder API (fake REST API for testing)
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  // PHẦN 1: SỬ DỤNG THƯ VIỆN 'http' 
  Future<List<Post>> fetchPostsWithHttp() async {
    try {
      // Phải tự viết full URL, không có baseUrl config
      final response = await http.get(
        Uri.parse('$baseUrl/posts'),
        // Không có cách nào set timeout global, phải set cho từng request
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - Quá thời gian chờ');
        },
      );

      // Phải tự kiểm tra status code
      // Nếu quên check này -> app crash khi API trả về lỗi
      if (response.statusCode == 200) {
        // Parse JSON thành List
        final List<dynamic> jsonList = json.decode(response.body);
        
        // Convert từng item thành Post object (dùng manual fromJson)
        return jsonList.map((json) => Post.fromJson(json)).toList();
      } else {
        // Phải tự viết error handling
        throw Exception(
          'Failed to load posts. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Error handling đơn giản
      // Không có chi tiết về request/response để debug
      print('❌ Error fetching posts with http: $e');
      rethrow;
    }
  }

  // PHẦN 2: SỬ DỤNG THƯ VIỆN 'Dio'

  // Tạo Dio instance với GLOBAL CONFIGURATION
  // Instance này có thể reuse cho tất cả API calls
  late final Dio _dio = Dio(
    BaseOptions(
      // Ưu điểm 1: BASE URL - Chỉ cần khai báo 1 lần
      baseUrl: baseUrl,
      
      // Ưu điểm 2: TIMEOUT - Set một lần, áp dụng cho tất cả requests
      connectTimeout: const Duration(seconds: 10), // Timeout khi kết nối
      receiveTimeout: const Duration(seconds: 10), // Timeout khi nhận data
      sendTimeout: const Duration(seconds: 10),    // Timeout khi gửi data
      
      // Ưu điểm 3: HEADERS - Set headers chung cho tất cả requests
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Có thể thêm auth token ở đây: 'Authorization': 'Bearer $token'
      },
      
      // Ưu điểm 4: Response Type
      responseType: ResponseType.json,
    ),
  )..interceptors.add(
      // Ưu điểm 5: INTERCEPTORS - Log tự động mọi request/response
      LogInterceptor(
        request: true,          // Log request details
        requestHeader: true,    // Log request headers
        requestBody: true,      // Log request body
        responseHeader: true,   // Log response headers
        responseBody: true,     // Log response body
        error: true,            // Log errors
        logPrint: (log) {
          // Custom log output - dễ debug
          print('🌐 DIO LOG: $log');
        },
      ),
    );

  Future<List<User>> fetchUsersWithDio() async {
    try {
      // Code ngắn gọn hơn nhiều so với 'http'
      // - Không cần viết full URL (đã có baseUrl)
      // - Không cần check statusCode (Dio tự động throw error nếu != 2xx)
      // - Không cần parse JSON thủ công (Dio tự động parse)
      final response = await _dio.get('/users');

      // response.data đã được parse thành List tự động
      // Không cần json.decode() như 'http'
      final List<dynamic> jsonList = response.data;

      // Convert JSON thành User objects (dùng auto-generated fromJson)
      return jsonList.map((json) => User.fromJson(json)).toList();
      
    } on DioException catch (e) {
      // DioException cung cấp nhiều thông tin để debug
      print('❌ Dio Error Details:');
      print('   - Type: ${e.type}'); // Loại lỗi (timeout, cancel, response...)
      print('   - Message: ${e.message}');
      print('   - Status Code: ${e.response?.statusCode}');
      print('   - Response Data: ${e.response?.data}');
      print('   - Request URL: ${e.requestOptions.uri}');
      
      // Có thể xử lý từng loại lỗi cụ thể
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          throw Exception('Kết nối timeout - Kiểm tra mạng');
        case DioExceptionType.receiveTimeout:
          throw Exception('Nhận dữ liệu timeout - Server phản hồi chậm');
        case DioExceptionType.badResponse:
          throw Exception('Server lỗi: ${e.response?.statusCode}');
        case DioExceptionType.cancel:
          throw Exception('Request bị hủy');
        default:
          throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
      rethrow;
    }
  }
}
