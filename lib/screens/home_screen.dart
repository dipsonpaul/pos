import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/pos/pos_bloc.dart';
import '../bloc/sales/sales_bloc.dart';
import '../bloc/attendance/attendance_bloc.dart';
import '../models/user.dart';
import '../services/hive_service.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import 'pos_screen.dart';
import 'sales_list_screen.dart';
import 'attendance_screen.dart';
import 'auth/login_screen.dart';
import 'product_management_screen.dart';
import 'staff_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final SyncService _syncService = SyncService();

  @override
  void initState() {
    super.initState();
    _syncService.init();
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = HiveService.getCurrentUser();
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: isMobile ? 48 : 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No user logged in',
                style: TextStyle(fontSize: isMobile ? 16 : 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Please log in to continue',
                style: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final bool isAdmin = currentUser.role == UserRole.admin;

    return MultiBlocProvider(
      providers: [
        BlocProvider<PosBloc>(
          create: (context) => PosBloc(),
        ),
        BlocProvider<SalesBloc>(
          create: (context) => SalesBloc(),
        ),
        BlocProvider<AttendanceBloc>(
          create: (context) => AttendanceBloc(),
        ),
      ],
      child: Scaffold(
        appBar: _buildAppBar(context, currentUser, isMobile),
        body: IndexedStack(
          index: _currentIndex,
          children: isAdmin
              ? const [
                  // Admin: Staff, Products, Revenue, Attendance
                  StaffManagementScreen(),
                  ProductManagementScreen(),
                  SalesListScreen(),
                  AttendanceScreen(),
                ]
              : const [
                  // Staff: POS, Sales history, Attendance
                  PosScreen(),
                  SalesListScreen(),
                  AttendanceScreen(),
                ],
        ),
        bottomNavigationBar: _buildBottomNavigation(context, isMobile, isAdmin),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, User currentUser, bool isMobile) {
    return AppBar(
      title: Text(
        _getAppBarTitle(),
        style: TextStyle(fontSize: isMobile ? 16 : 18),
      ),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currentUser.name,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentUser.role.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: isMobile ? 8 : 10,
                    color: currentUser.role == UserRole.admin ? Colors.blue : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
        StreamBuilder<bool>(
          stream: _syncService.connectionStream,
          builder: (context, snapshot) {
            final isOnline = snapshot.data ?? false;
            return Icon(
              isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: isOnline ? Colors.green : Colors.orange,
              size: isMobile ? 20 : 24,
            );
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'logout') {
              await _handleLogout(context);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: isMobile ? 20 : 24),
                  const SizedBox(width: 8),
                  Text('Logout', style: TextStyle(fontSize: isMobile ? 12 : 14)),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 4.0 : 8.0),
            child: Icon(Icons.more_vert, size: isMobile ? 20 : 24),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 16),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context, bool isMobile, bool isAdmin) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      selectedFontSize: isMobile ? 12 : 14,
      unselectedFontSize: isMobile ? 10 : 12,
      items: isAdmin
          ? const [
              BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: 'Staff',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2),
                label: 'Products',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Revenue',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_time),
                label: 'Attendance',
              ),
            ]
          : const [
              BottomNavigationBarItem(
                icon: Icon(Icons.point_of_sale),
                label: 'POS',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: 'Sales',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_time),
                label: 'Attendance',
              ),
            ],
    );
  }

  String _getAppBarTitle() {
    return 'Ice Cream POS';
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await AuthService.signOut();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}