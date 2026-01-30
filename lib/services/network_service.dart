import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../models/post_manual.dart';
import '../models/user_auto.dart';
import 'token_service.dart';
import 'auth_interceptor.dart';
import 'dio_error_handler.dart';

// Class này demo SỰ KHÁC BIỆT giữa 2 thư viện networking:
// 1. http - Thư viện HTTP cơ bản từ Dart team
// 2. Dio - Thư viện HTTP mạnh mẽ, feature-rich cho production
// 3. Cách tích hợp TOKEN AUTHENTICATION với Dio (dùng TokenService + AuthInterceptor)
// 4. Cách xử lý ERROR tập trung với DioErrorHandler (không cần viết lại try-catch)

class NetworkService {
  // Base URL của JSONPlaceholder API (fake REST API for testing)
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  
  // TokenService instance để quản lý token
  final TokenService tokenService = TokenService();

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
        // Token sẽ được thêm động qua AuthInterceptor
      },
      
      // Ưu điểm 4: Response Type
      responseType: ResponseType.json,
    ),
  )..interceptors.addAll([
      // INTERCEPTOR 1: Tự động thêm TOKEN vào header (từ file riêng)
      AuthInterceptor(tokenService),
      
      // INTERCEPTOR 2: Log tự động mọi request/response
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
    ]);

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
      
    } catch (e) {
      // SỬ DỤNG DioErrorHandler - Không cần viết lại logic xử lý lỗi
      throw DioErrorHandler.handle(
        e,
        customMessage: 'Không thể tải danh sách người dùng',
      );
    }
  }

  // ============================================================================
  // CÁCH VIẾT TỐT HƠN: Dùng handleApiCall helper (không cần try-catch)
  // ============================================================================

  /// Ví dụ API với handleApiCall - Code ngắn gọn nhất
  /// 
  /// LỢI ÍCH:
  /// - Không cần try-catch
  /// - Không cần check response
  /// - Chỉ focus vào logic parse data
  /// - Error handling tự động
  Future<List<User>> fetchUsersSimplified() async {
    return await DioErrorHandler.handleApiCall(
      apiCall: () => _dio.get('/users'),
      parser: (data) {
        final List<dynamic> jsonList = data;
        return jsonList.map((json) => User.fromJson(json)).toList();
      },
      customErrorMessage: 'Không thể tải danh sách người dùng',
    );
  }

  /// Ví dụ GET một user theo ID
  Future<User> getUserById(int id) async {
    return await DioErrorHandler.handleApiCall(
      apiCall: () => _dio.get('/users/$id'),
      parser: (data) => User.fromJson(data),
      customErrorMessage: 'Không thể tải thông tin người dùng',
    );
  }

  /// Ví dụ POST - Tạo user mới
  Future<User> createUser({
    required String name,
    required String email,
  }) async {
    return await DioErrorHandler.handleApiCall(
      apiCall: () => _dio.post(
        '/users',
        data: {
          'name': name,
          'email': email,
        },
      ),
      parser: (data) => User.fromJson(data),
      customErrorMessage: 'Không thể tạo người dùng mới',
    );
  }

  /// Ví dụ PUT - Update user
  Future<User> updateUser({
    required int id,
    required String name,
    required String email,
  }) async {
    return await DioErrorHandler.handleApiCall(
      apiCall: () => _dio.put(
        '/users/$id',
        data: {
          'name': name,
          'email': email,
        },
      ),
      parser: (data) => User.fromJson(data),
      customErrorMessage: 'Không thể cập nhật người dùng',
    );
  }

  /// Ví dụ DELETE - Xóa user
  Future<void> deleteUser(int id) async {
    return await DioErrorHandler.handleApiCall(
      apiCall: () => _dio.delete('/users/$id'),
      parser: (_) {}, // DELETE thường không trả về data
      customErrorMessage: 'Không thể xóa người dùng',
    );
  }

  /// Ví dụ với query parameters
  Future<List<Post>> getPostsByUserId(int userId) async {
    return await DioErrorHandler.handleApiCall(
      apiCall: () => _dio.get(
        '/posts',
        queryParameters: {'userId': userId},
      ),
      parser: (data) {
        final List<dynamic> jsonList = data;
        return jsonList.map((json) => Post.fromJson(json)).toList();
      },
      customErrorMessage: 'Không thể tải bài viết của người dùng',
    );
  }

  // ============================================================================
  // PHẦN 3: UPLOAD FILE với Dio
  // ============================================================================

  /// Ví dụ 1: Upload 1 FILE đơn giản
  /// 
  /// CÁCH DÙNG:
  /// ```dart
  /// import 'package:image_picker/image_picker.dart';
  /// 
  /// final picker = ImagePicker();
  /// final image = await picker.pickImage(source: ImageSource.gallery);
  /// 
  /// if (image != null) {
  ///   await networkService.uploadSingleFile(image.path);
  /// }
  /// ```
  /// 
  /// API ENDPOINT (ví dụ):
  /// POST https://api.example.com/upload
  /// Content-Type: multipart/form-data
  Future<Map<String, dynamic>> uploadSingleFile(String filePath) async {
    return await DioErrorHandler.handleApiCall(
      apiCall: () async {
        // Tạo FormData - Dio sẽ tự động set Content-Type: multipart/form-data
        final formData = FormData.fromMap({
          // 'file' là tên field mà server mong đợi
          // Có thể thay đổi theo API của bạn (ví dụ: 'image', 'avatar', 'document')
          'file': await MultipartFile.fromFile(
            filePath,
            // Tùy chọn: Chỉ định tên file hiển thị
            filename: filePath.split('/').last,
          ),
        });

        // Gửi POST request với FormData
        return _dio.post(
          '/upload', // Thay bằng endpoint thật của bạn
          data: formData,
        );
      },
      parser: (data) => data as Map<String, dynamic>,
      customErrorMessage: 'Không thể upload file',
    );
  }

  
}
