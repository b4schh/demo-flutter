import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Class này demo LOCAL DATA STORAGE với SharedPreferences

class ThemeService {
  // Key để lưu trong SharedPreferences
  // Nên định nghĩa constant để tránh typo
  static const String _themeKey = 'isDarkMode';

  // Light Theme - Giao diện sáng
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 219, 224, 228),
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  // Dark Theme - Giao diện tối
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );


  /// Load theme preference từ local storage
  /// 
  /// Hàm này được gọi KHI APP KHỞI ĐỘNG
  /// 
  /// TẠI SAO QUAN TRỌNG:
  /// - User đã chọn Dark Mode lần trước
  /// - Tắt app và mở lại
  /// - App phải NHỚ và hiển thị đúng theme đã chọn
  /// 
  /// QUY TRÌNH:
  /// 1. Lấy instance của SharedPreferences (async operation)
  /// 2. Đọc giá trị boolean với key 'isDarkMode'
  /// 3. Nếu không tồn tại -> dùng giá trị mặc định (false = Light Mode)
  /// 4. Trả về giá trị
  static Future<bool> loadThemePreference() async {
    try {
      // getInstance() là singleton, chỉ tạo 1 lần
      final prefs = await SharedPreferences.getInstance();

      // Đọc boolean, nếu không tồn tại trả về false (default)
      final isDarkMode = prefs.getBool(_themeKey) ?? false;

      print('✅ Theme được tải từ storage: ${isDarkMode ? "Dark" : "Light"} Mode');
      print('📂 Storage key: $_themeKey, Value: $isDarkMode');
      
      return isDarkMode;
    } catch (e) {
      print('❌ Lỗi khi tải theme: $e');
      return false;
    }
  }

  // SAVE THEME - Lưu vào SharedPreferences

  /// QUY TRÌNH:
  /// 1. Lấy SharedPreferences instance
  /// 2. Lưu giá trị boolean mới vào disk
  /// 3. Log để debug
  static Future<void> saveThemePreference(bool isDarkMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setBool(_themeKey, isDarkMode);

      if (result) {
        print('✅ Lưu theme thành công: ${isDarkMode ? "Dark" : "Light"} Mode');
        print('📂 Storage key: $_themeKey, Value: $isDarkMode');
        
      } else {
        print('⚠️ Result = false (theme có thể không được lưu)');
      }
    } catch (e) {
      print('❌ Lỗi khi lưu theme: $e');
    }
  }

  // HELPER - Lấy ThemeData từ boolean
  static ThemeData getTheme(bool isDarkMode) {
    return isDarkMode ? darkTheme : lightTheme;
  }
}