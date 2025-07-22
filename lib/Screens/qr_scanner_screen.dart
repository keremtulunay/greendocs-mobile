import 'package:flutter/material.dart';
import 'package:greendocs_mobile/Screens/parent_scan_screen.dart';
import 'package:greendocs_mobile/Services/container_type_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:greendocs_mobile/Services/container_service.dart';
import 'package:greendocs_mobile/Services/auth_service.dart';
import 'package:collection/collection.dart';

import '../Models/container_item.dart';
import '../Models/container_type.dart';
import 'MoveSummaryScreen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  String? _parentBarcode;
  final List<String> _childBarcodes = [];
  final ContainerService containerService = ContainerService(); // place this at the top of the class
  final ContainerTypeService containerTypeService = ContainerTypeService('https://greendocsweb.koda.com.tr:444');
  Future<void> _openCameraAndScan(Function(String result) onScanned) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ParentScanScreen()),
    );

    if (result != null && result is String) {
      onScanned(result);
    }
  }

  void _scanParent() {
    _openCameraAndScan((code) {
      setState(() {
        _parentBarcode = code;
        _childBarcodes.clear(); // Optional: reset children if new parent
      });
    });
  }

  void _scanChild() {
    _openCameraAndScan((code) {
      if (code != _parentBarcode && !_childBarcodes.contains(code)) {
        setState(() {
          _childBarcodes.add(code);
        });
      }
    });
  }

  Future<void> _submit() async {
    if (_parentBarcode == null || _childBarcodes.isEmpty) return;

    final containers = await containerService.getContainers(AuthService.authToken!);
    final containerTypes = await containerTypeService.getContainerTypes(AuthService.authToken!);
    ContainerItem? parent;

    try {
      parent = containers.firstWhere((c) => c.code == _parentBarcode);
    } catch (e) {
      // Handle parent not found error
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parent container not found.')));
      return;
    }

    List<MoveResult> moveResults = [];

    for (final code in _childBarcodes) {
      ContainerItem? child;
      try {
        child = containers.firstWhere((c) => c.code == code);

        final canMove = canMoveContainer(
          parent: parent!,
          child: child,
          allContainers: containers,
          containerTypes: containerTypes, // pass your container types list here
        );

        if (!canMove) {
          moveResults.add(MoveResult(
            code: child.code,
            success: false,
            message: 'Boyut veya kapasite sınırı aşıldı',
          ));
          continue;
        }

        final updatedChild = ContainerItem(
          locationId: child.locationId,
          code: child.code,
          containerTypeId: child.containerTypeId,
          parentId: parent.locationId,
          description: child.description,
        );

        final success = await ContainerService().saveContainer(updatedChild, AuthService.authToken!);

        if (success) {
          moveResults.add(MoveResult(code: child.code, success: true));
        } else {
          moveResults.add(MoveResult(code: child.code, success: false, message: 'Failed to save changes'));
        }
      } catch (e) {
        moveResults.add(MoveResult(code: code, success: false, message: 'Container not found'));
      }
    }

    // Navigate to summary screen with results
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MoveSummaryScreen(
            parentCode: parent!.code,
            results: moveResults,
          ),
        ),
      );
    }
  }




  bool canMoveContainer({
    required ContainerItem parent,
    required ContainerItem child,
    required List<ContainerItem> allContainers,
    required List<ContainerType> containerTypes,
  }) {
    // Find container types for parent and child
    final parentType = containerTypes.firstWhere((t) => t.id == parent.containerTypeId);
    final childType = containerTypes.firstWhere((t) => t.id == child.containerTypeId);

    // Check height and depth
    if ((childType.height ?? 0) >= (parentType.height ?? double.infinity)) {
      print('Cannot move: child height too large');
      return false;
    }
    if ((childType.depth ?? 0) >= (parentType.depth ?? double.infinity)) {
      print('Cannot move: child depth too large');
      return false;
    }

    // Calculate fullness (sum widths of siblings + child)
    final siblings = allContainers.where((c) => c.parentId == parent.locationId).toList();
    int usedWidth = 0;
    for (var sibling in siblings) {
      final siblingType = containerTypes.firstWhere((t) => t.id == sibling.containerTypeId);
      usedWidth += siblingType.width ?? 0;
    }
    usedWidth += childType.width ?? 0;

    if (usedWidth > (parentType.width ?? double.infinity)) {
      print('Cannot move: parent capacity exceeded');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Scan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: _scanParent,
                child: const Text('Ana saklama elemanını tara'),
              ),
              const SizedBox(height: 16),
            if (_parentBarcode != null) ...[
              Text('Parent: $_parentBarcode'),
              ],
              ElevatedButton(
                onPressed: _childBarcodes.isNotEmpty ? _submit : null,
                child: const Text('Tamam'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _parentBarcode != null ? _scanChild : null,
                child: const Text('Taşınacak saklama elemanını tara'),
              ),
              if (_parentBarcode != null) ...[
                const SizedBox(height: 16),
                const Text('Taşınan elemanlar:'),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _childBarcodes.length,
                  itemBuilder: (_, index) => ListTile(
                    title: Text(_childBarcodes[index]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
