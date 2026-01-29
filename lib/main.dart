import 'package:flutter/material.dart';
import 'services/theme_service.dart';
import 'screens/home_screen.dart';

// Đây là entry point của Flutter application
// main() function là điểm khởi đầu của mọi Dart program

/// 
/// Tại sao dùng async main()?
/// - Cần await loadTheme() trước khi chạy app
/// - Đảm bảo theme được load từ SharedPreferences trước khi build UI
/// - Nếu không dùng async -> theme sẽ bị delay, flash màn hình
void main() async {
  // Bước 1: Khởi tạo các ràng buộc của Flutter
  
  // Lưu ý khi dùng async trong main()
  // ensureInitialized() đảm bảo Flutter framework đã sẵn sàng
  // Bắt buộc gọi trước khi dùng:
  // - SharedPreferences
  // - Firebase
  // - Sqflite
  // - Path Provider
  // ... và các plugin khác cần native code
  // ensureInitialized() đảm bảo Flutter engine và plugin system sẵn sàng trước khi sử dụng các API phụ thuộc platform.
  WidgetsFlutterBinding.ensureInitialized();

  // Bước 2: Khởi tạo các dịch vụ
  
  // Load theme từ SharedPreferences
  // AWAIT để đợi load theme xong trước khi chạy app
  // Nếu không await -> app sẽ chạy với default theme (Light)
  // -> Sau đó mới load saved theme -> gây flash/flicker UI
  final isDarkMode = await ThemeService.loadThemePreference();
  
  print('✅ App initialized successfully');

  // Bước 3: Chạy ứng dụng
  
  // runApp() là function bắt buộc của Flutter
  // Nhận một Widget làm root của app
  // Truyền isDarkMode xuống MyApp để khởi tạo theme
  runApp(MyApp(isDarkMode: isDarkMode));
}

// MyApp - Root Widget của application
class MyApp extends StatefulWidget {
  final bool isDarkMode;
  
  const MyApp({super.key, required this.isDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // State variable để lưu theme hiện tại
  late bool _isDarkMode;
  
  @override
  void initState() {
    super.initState();
    // Khởi tạo theme từ value được truyền vào
    _isDarkMode = widget.isDarkMode;
  }
  
  // Hàm để toggle theme
  // Được gọi từ HomeScreen khi user bấm nút
  Future<void> _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    // Lưu vào SharedPreferences với await để đảm bảo được save
    // Rất quan trọng trên Web và Desktop!
    await ThemeService.saveThemePreference(_isDarkMode);
    print('🔄 Theme toggled and saved: ${_isDarkMode ? "Dark" : "Light"}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo: Local Data & REST API',
      theme: ThemeService.getTheme(_isDarkMode),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(
        isDarkMode: _isDarkMode,
        onThemeToggle: _toggleTheme, 
      ),
    );
  }
}