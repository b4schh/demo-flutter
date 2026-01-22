import 'package:flutter/material.dart';
import '../models/post_manual.dart';
import '../models/user_auto.dart';
import '../services/network_service.dart';

// HomeScreen là màn hình chính của app
// Demo đầy đủ các concepts: FutureBuilder, TabBar, Theme switching

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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // TabController để quản lý việc chuyển tab
  late TabController _tabController;

  // Instance của NetworkService để gọi API
  final NetworkService _networkService = NetworkService();

  @override
  void initState() {
    super.initState();
    // Khởi tạo TabController với 2 tabs
    // length: 2 -> có 2 tabs
    // vsync: this -> cần SingleTickerProviderStateMixin
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    // QUAN TRỌNG - Dispose controller để tránh memory leak
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build method trả về UI của HomeScreen
    // Nhận isDarkMode và onThemeToggle từ widget properties (parent truyền xuống)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Data & REST API Demo'),
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
        // TabBar trong AppBar
        // bottom property cho phép thêm widget dưới AppBar
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            // Tab 1: Manual Serialization + http
            Tab(
              icon: Icon(Icons.article),
              text: 'Posts (Manual + http)',
            ),
            // Tab 2: Auto Serialization + Dio
            Tab(
              icon: Icon(Icons.people),
              text: 'Users (Auto + Dio)',
            ),
          ],
        ),
      ),

      // Body với TabBarView
      // TabBarView hiển thị nội dung của mỗi tab
      // Swipe trái/phải để chuyển tab
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Posts List
          _buildPostsTab(),
          // Tab 2: Users List
          _buildUsersTab(),
        ],
      ),
    );
  }

  // TAB 1: POSTS LIST (Manual Serialization + http)
  Widget _buildPostsTab() {
    return FutureBuilder<List<Post>>(
      // future property - async function để lấy data
      future: _networkService.fetchPostsWithHttp(),
      
      // builder được gọi nhiều lần khi state thay đổi
      // snapshot chứa: connectionState, data, error
      builder: (context, snapshot) {
        // STATE 1: LOADING
        // Khi đang fetch data từ API
        if (snapshot.connectionState == ConnectionState.waiting) {
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
        if (snapshot.hasError) {
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
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Để reload, gọi setState()
                      // FutureBuilder sẽ chạy lại future
                      setState(() {});
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
        if (snapshot.hasData) {
          final posts = snapshot.data!;

          // Trường hợp API trả về empty list
          if (posts.isEmpty) {
            return const Center(
              child: Text('Không có posts nào'),
            );
          }

          // ListView.builder cho performance tốt
          // Chỉ build những items đang hiển thị trên màn hình
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildPostCard(post);
            },
          );
        }

        // STATE 4: NO DATA (không có error, nhưng data null)
        return const Center(
          child: Text('Không có dữ liệu'),
        );
      },
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
  Widget _buildUsersTab() {
    return FutureBuilder<List<User>>(
      future: _networkService.fetchUsersWithDio(),
      builder: (context, snapshot) {
        // STATE 1: LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
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
        if (snapshot.hasError) {
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
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {});
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
        if (snapshot.hasData) {
          final users = snapshot.data!;

          if (users.isEmpty) {
            return const Center(
              child: Text('Không có users nào'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserCard(user);
            },
          );
        }

        // STATE 4: NO DATA 
        return const Center(
          child: Text('Không có dữ liệu'),
        );
      },
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