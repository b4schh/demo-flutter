import 'package:flutter/material.dart';
import '../models/post_manual.dart';
import '../models/user_auto.dart';
import '../services/network_service.dart';

// HomeScreen là màn hình chính của app
class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  
  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Navigation state: 0 = Posts, 1 = Users
  int _selectedScreen = 0;

  // Instance của NetworkService để gọi API
  final NetworkService _networkService = NetworkService();

  // STATE MANAGEMENT cho Posts Tab
  bool _isLoadingPosts = false;
  List<Post>? _posts;
  String? _postsError;

  // STATE MANAGEMENT cho Users Tab
  bool _isLoadingUsers = false;
  List<User>? _users;
  String? _usersError;

  @override
  void initState() {
    super.initState();
    // Load dữ liệu Posts ngay khi app khởi động (màn hình đầu tiên)
    _loadPosts();
  }

  /// Chuyển màn hình và load data nếu cần
  void _navigateToScreen(int screenIndex) {
    setState(() {
      _selectedScreen = screenIndex;
    });

    // Load data cho màn hình Users nếu chưa load
    if (screenIndex == 1 && _users == null && !_isLoadingUsers) {
      _loadUsers();
    }
  }

  /// Load Posts từ API bằng thư viện http
  /// Sử dụng async/await
  Future<void> _loadPosts() async {
    // Set state loading = true
    setState(() {
      _isLoadingPosts = true;
      _postsError = null; // Clear error cũ
    });

    try {
      // Gọi API với await
      final posts = await _networkService.fetchPostsWithHttp();
      
      // Nếu thành công, cập nhật data
      setState(() {
        _posts = posts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      // Nếu có lỗi, cập nhật error message
      setState(() {
        _postsError = e.toString();
        _isLoadingPosts = false;
      });
    }
  }

  /// Load Users từ API bằng thư viện Dio
  /// Sử dụng async/await
  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _usersError = null;
    });

    try {
      final users = await _networkService.fetchUsersWithDio();
      
      setState(() {
        _users = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _usersError = e.toString();
        _isLoadingUsers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build method trả về UI của HomeScreen
    // Nhận isDarkMode và onThemeToggle từ widget properties (parent truyền xuống)
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedScreen == 0 
            ? 'Posts (Manual + http)' 
            : 'Users (Auto + Dio)',
        ),
        actions: [
          // IconButton để toggle theme
          // Icon thay đổi theo theme hiện tại
          IconButton(
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode // Icon mặt trời khi đang Dark
                  : Icons.dark_mode, // Icon mặt trăng khi đang Light
            ),
            tooltip: widget.isDarkMode
                ? 'Chuyển sang chế độ sáng'
                : 'Chuyển sang chế độ tối',
            onPressed: () {
              // Gọi callback onThemeToggle
              // -> Parent (MyApp) sẽ gọi setState()
              // -> MyApp rebuild với theme mới
              // -> HomeScreen nhận isDarkMode mới
              widget.onThemeToggle();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      // Body đơn giản: hiển thị màn hình theo _selectedScreen
      // 0 = Posts, 1 = Users
      body: _selectedScreen == 0 ? _buildPostsTab() : _buildUsersTab(),

      // BottomNavigationBar để chuyển giữa 2 màn hình
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedScreen,
        onTap: _navigateToScreen, // Gọi hàm chuyển màn hình
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Posts',
            tooltip: 'Manual Serialization + http',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
            tooltip: 'Auto Serialization + Dio',
          ),
        ],
      ),
    );
  }

  // TAB 1: POSTS LIST (Manual Serialization + http)
  // Sử dụng async/await và setState
  Widget _buildPostsTab() {
    // STATE 1: LOADING
    // Khi đang fetch data từ API
    if (_isLoadingPosts) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải Posts với http...'),
          ],
        ),
      );
    }

    // STATE 2: ERROR 
    // Khi có lỗi (network error, timeout, server error...)
    if (_postsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Lỗi tải dữ liệu!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _postsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Gọi lại hàm load để retry
                  _loadPosts();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    // STATE 3: SUCCESS với DATA
    // Có data -> hiển thị list
    if (_posts != null) {
      // Trường hợp API trả về empty list
      if (_posts!.isEmpty) {
        return const Center(
          child: Text('Không có posts nào'),
        );
      }

      // ListView.builder cho performance tốt
      // Chỉ build những items đang hiển thị trên màn hình
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _posts!.length,
        itemBuilder: (context, index) { // Với mỗi index, Flutter gọi hàm build 1 item và khi cần mới gọi
          final post = _posts![index];
          return _buildPostCard(post);
        },
      );
    }

    // STATE 4: NO DATA (không có error, nhưng data null)
    // Trường hợp này thường không xảy ra vì đã load trong initState
    return const Center(
      child: Text('Không có dữ liệu'),
    );
  }

  /// Build Card để hiển thị một Post
  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        // Leading: Avatar với ID
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            '${post.id}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        // Title: Post title
        title: Text(
          post.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // Subtitle: Post body
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            post.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        // Trailing: Badge hiển thị phương pháp
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange),
          ),
          child: const Text(
            'Manual',
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // TAB 2: USERS LIST (Auto Serialization + Dio)
  // Sử dụng async/await và setState
  Widget _buildUsersTab() {
    // STATE 1: LOADING
    if (_isLoadingUsers) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải Users với Dio...'),
            SizedBox(height: 8),
            Text(
              '(Check console để xem Dio logs)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // STATE 2: ERROR
    if (_usersError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Lỗi tải dữ liệu!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _usersError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Gọi lại hàm load để retry
                  _loadUsers();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    // STATE 3: SUCCESS với DATA
    if (_users != null) {
      if (_users!.isEmpty) {
        return const Center(
          child: Text('Không có users nào'),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _users!.length,
        itemBuilder: (context, index) {
          final user = _users![index];
          return _buildUserCard(user);
        },
      );
    }

    // STATE 4: NO DATA 
    // Trường hợp chưa load (user chưa chuyển sang tab này)
    return const Center(
      child: Text('Chuyển sang tab để tải dữ liệu'),
    );
  }

  /// Build Card để hiển thị một User
  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        // Leading: Avatar với icon
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(
            user.name[0].toUpperCase(), // Chữ cái đầu của tên
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Title: User name
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // Subtitle: Email và ID
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.email, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      user.email,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${user.id}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        // Trailing: Badge hiển thị phương pháp
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: const Text(
            'Auto',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}