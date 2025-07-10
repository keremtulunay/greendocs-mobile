import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_screen.dart';
import 'physical_archive_menu_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_MenuItem> menuItems = [
      _MenuItem(
        icon: Icons.search,
        label: 'Arama',
        onTap: () {
          // TODO: Navigate to Search screen
        },
      ),
      _MenuItem(
        icon: Icons.archive,
        label: 'Fiziksel Arşiv',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PhysicalArchiveMenuScreen()),
          );
        },
      ),
      _MenuItem(
        icon: Icons.upload_file,
        label: 'Belge Tara / Yükle',
        onTap: () {
          // TODO: Navigate to Scan/Upload screen
        },
      ),
      _MenuItem(
        icon: Icons.folder_open,
        label: 'EBYS (Yakında)',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('EBYS modülü henüz hazır değil.')),
          );
        },
      ),
      _MenuItem(
        icon: Icons.help_outline,
        label: 'Yardım',
        onTap: () {
          // TODO: Navigate to Help screen
        },
      ),
      _MenuItem(
        icon: Icons.logout,
        label: 'Çıkış Yap',
        isLogout: true,
        onTapWithContext: (context) {
          final screen = context.findAncestorWidgetOfExactType<MainMenuScreen>();
          screen?._logout(context);
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Menü'),
        backgroundColor: Colors.green,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: menuItems.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => _buildMenuItemTile(context, menuItems[index]),
      ),
    );
  }

  Widget _buildMenuItemTile(BuildContext context, _MenuItem item) {
    final isLogout = item.isLogout;

    return ListTile(
      leading: Icon(
        item.icon,
        color: isLogout ? Colors.red : Colors.green,
      ),
      title: Text(
        item.label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red : null,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (isLogout && item.onTapWithContext != null) {
          item.onTapWithContext!(context);
        } else if (item.onTap != null) {
          item.onTap!();
        }
      },
    );
  }
}

typedef MenuTapCallback = void Function();
typedef MenuTapWithContext = void Function(BuildContext);

class _MenuItem {
  final IconData icon;
  final String label;
  final MenuTapCallback? onTap;
  final MenuTapWithContext? onTapWithContext;
  final bool isLogout;

  _MenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.onTapWithContext,
    this.isLogout = false,
  });
}
