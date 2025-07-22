import 'package:flutter/material.dart';

import 'package:greendocs_mobile/Screens/qr_scanner_screen.dart';
import '../Models/container_item.dart';
import '../Models/container_type.dart';
import '../Services/container_service.dart';
import '../Services/container_type_service.dart';
import '../Services/auth_service.dart';
import 'edit_add_container_type_screen.dart';
import 'container_list_screen.dart';
import 'container_type_list_screen.dart';
import 'edit_add_container-screen.dart';

class PhysicalArchiveMenuScreen extends StatelessWidget {
  const PhysicalArchiveMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_MenuItem> menuItems = [
      _MenuItem(
        icon: Icons.list_alt,
        label: 'Saklama Elemanı Tipleri',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ContainerTypeListScreen(),
            ),
          );
        },
      ),
      _MenuItem(
        icon: Icons.add_box_outlined,
        label: 'Yeni Tip Ekle',
        onTap: () async {
          final newContainerType = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EditAddContainerTypeScreen(container: null),
            ),
          );

          if (newContainerType != null && newContainerType is ContainerType) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Yeni tip başarıyla eklendi')),
            );
          }
        },
      ),
      _MenuItem(
        icon: Icons.inventory_2,
        label: 'Saklama Elemanları',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ContainerListScreen(),
            ),
          );
        },
      ),
      _MenuItem(
        icon: Icons.add_circle_outline,
        label: 'Yeni Eleman Ekle',
        onTap: () async {
          final containerTypeService = ContainerTypeService('https://greendocsweb.koda.com.tr:444');
          final containerService = ContainerService();

          final containerTypes = await containerTypeService.getContainerTypes(AuthService.authToken!);
          final allContainers = await containerService.getContainers(AuthService.authToken!);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditAddContainerScreen(
                containerTypes: containerTypes,
                possibleLocations: allContainers,
                container: null,
                allContainers: [],
              ),
            ),
          ).then((result) {
            if (result != null && result is Map && result['container'] is ContainerItem) {
              final ContainerItem newContainer = result['container'];
              debugPrint('New container added: ${newContainer.code}');
            }
          });
        },
      ),
      _MenuItem(
        icon: Icons.qr_code_scanner,
        label: 'QR ile Tara',
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QRScannerScreen()),
          );
          if (result != null) {
            // TODO: Use `result` (barcode) to find matching container
          }
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiziksel Arşiv'),
        backgroundColor: Colors.green,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: menuItems.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return ListTile(
            leading: Icon(item.icon, color: Colors.green),
            title: Text(
              item.label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: item.onTap,
          );
        },
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _MenuItem({required this.icon, required this.label, required this.onTap});
}
