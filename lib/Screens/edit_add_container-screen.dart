import 'package:flutter/material.dart';
import '../Models/container_item.dart';
import '../Models/container_type.dart';
import '../Services/container_service.dart';
import '../auth_service.dart';

class EditAddContainerScreen extends StatefulWidget {
  final ContainerItem? container; // null if adding new
  final List<ContainerType> containerTypes; // list of available types
  final List<ContainerItem> possibleLocations; // containers to choose as parent (optional)
  final List<ContainerItem> allContainers;
  const EditAddContainerScreen({
    super.key,
    this.container,
    required this.containerTypes,
    required this.possibleLocations,
    required this.allContainers,
  });

  @override
  State<EditAddContainerScreen> createState() => _EditAddContainerScreenState();
}

class _EditAddContainerScreenState extends State<EditAddContainerScreen> {
  List<ContainerType> _cachedValidTypes = [];
  int? _lastParentIdForTypes;
  late final Map<int, List<ContainerItem>> childMap;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _barcodeController;
  late bool _isEditing;
  ContainerType? _selectedType;
  ContainerItem? _selectedLocation; // parent container, optional
  final _containerService = ContainerService();
  @override
  @override
  void initState() {
    super.initState();
    _isEditing = widget.container != null;
    _barcodeController = TextEditingController(text: widget.container?.code ?? '');
    // ✅ Build the child map for all containers
    childMap = {};
    for (var c in widget.possibleLocations) {
      if (c.parentId != null) {
        childMap.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }
    if (widget.containerTypes.isNotEmpty) {
      _selectedType = widget.containerTypes.firstWhere(
            (type) => type.id == widget.container?.containerTypeId,
        orElse: () => widget.containerTypes[0],
      );
    } else {
      _selectedType = null;
    }

    if (_isEditing) {
      final currentId = widget.container!.locationId;
      final descendants = getDescendants(currentId);

      final filteredLocations = widget.possibleLocations
          .where((c) => c.locationId != currentId && !descendants.contains(c.locationId))
          .toList();

      // 🔧 Ensure current parent is re-included if missing
      final parentId = widget.container!.parentId;
      if (parentId != null &&
          !filteredLocations.any((c) => c.locationId == parentId)) {
        final parent = widget.possibleLocations
            .firstWhere((c) => c.locationId == parentId, orElse: () => ContainerItem(
          locationId: parentId,
          code: '⛔️ Mevcut ebeveyn bulunamadı',
          containerTypeId: 0,
        ));
        filteredLocations.add(parent);
      }
      print('👀 parentId: $parentId');
      print('filteredLocations: ${filteredLocations.map((c) => c.locationId).toList()}');

      try {
        _selectedLocation = filteredLocations.firstWhere(
              (c) => c.locationId == parentId,
        );
        print('kerem1');
      } catch (_) {
        _selectedLocation = null;
        print('kerem2');
      }

      widget.possibleLocations.clear();
      widget.possibleLocations.addAll(filteredLocations);
    } else {
      _selectedLocation = null;
      _selectedType = null; // force user to pick
    }
  }
  Set<int> getDescendants(int id) {
    Set<int> result = {};
    void collect(int currentId) {
      if (childMap.containsKey(currentId)) {
        for (var child in childMap[currentId]!) {
          result.add(child.locationId);
          collect(child.locationId);
        }
      }
    }
    collect(id);
    return result;
  }
  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  List<ContainerType> getValidTypes() {
    final currentParentId = _selectedLocation?.locationId;

    // Return cached version if same parent
    if (currentParentId == _lastParentIdForTypes && _cachedValidTypes.isNotEmpty) {
      return _cachedValidTypes;
    }

    print('📦 getValidTypes CALLED!');
    print('  ➤ _selectedLocation: ${_selectedLocation?.code ?? "none"}');
    print('  ➤ isEditing: $_isEditing');

    final currentContainer = widget.container;
    final currentId = currentContainer?.locationId ?? -1;

    final children = widget.allContainers.where((c) => c.parentId == currentId).toList();

    print('  ➤ Children of current container ($currentId): ${children.map((c) => c.code).join(', ')}');

    final parentTypeId = _selectedLocation?.containerTypeId;
    final childTypeIds = children.map((c) => c.containerTypeId).toSet();

    final result = widget.containerTypes.where((type) {
      final typeDepth = type.depth ?? 0;
      final typeHeight = type.height ?? 0;
      final typeWidth = type.width ?? 0;

      if (_selectedLocation != null && type.id == parentTypeId) {
        print('❌ ${type.name}: same as parent');
        return false;
      }
      if (childTypeIds.contains(type.id)) return false;

      for (final child in children) {
        final childType = widget.containerTypes.firstWhere(
              (t) => t.id == child.containerTypeId,
          orElse: () => ContainerType(id: 0, name: 'Unknown'),
        );
        if ((type.depth != null && childType.depth != null && type.depth! <= childType.depth!) ||
            (type.height != null && childType.height != null && type.height! <= childType.height!)) {
          print('❌ ${type.name}: too small to contain ${child.code}');
          return false;
        }
      }

      if (_selectedLocation != null) {
        final parentType = widget.containerTypes.firstWhere(
              (t) => t.id == _selectedLocation!.containerTypeId,
          orElse: () => ContainerType(id: 0, name: 'Unknown'),
        );
        final parentDepth = parentType.depth;
        final parentHeight = parentType.height;

        if ((parentDepth != null && type.depth != null && type.depth! > parentDepth) ||
            (parentHeight != null && type.height != null && type.height! > parentHeight)) {
          print('❌ ${type.name}: too big for parent ${_selectedLocation!.code}');
          return false;
        }

        final siblings = widget.allContainers.where((c) =>
        c.parentId == _selectedLocation!.locationId &&
            (!_isEditing || c.locationId != currentId));

        final usedWidth = siblings.fold<int>(0, (sum, c) {
          final ct = widget.containerTypes.firstWhere(
                (t) => t.id == c.containerTypeId,
            orElse: () => ContainerType(id: 0, name: 'Unknown'),
          );
          return sum + (ct.width ?? 0);
        });

        final totalWidth = usedWidth + typeWidth;
        if (totalWidth > (parentType.width ?? 0)) return false;
      }

      return true;
    }).toList();

    print('✅ Final filtered types (${result.length}): ${result.map((t) => t.name).join(', ')}');

    // Cache it
    _cachedValidTypes = result;
    _lastParentIdForTypes = currentParentId;

    return result;
  }


  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tip seçilmedi')),
      );
      return;
    }

    // Check parent-child fitting logic
    if (_selectedLocation != null) {
      final parentType = widget.containerTypes.firstWhere(
            (type) => type.id == _selectedLocation!.containerTypeId,
        orElse: () => ContainerType(id: 0, name: 'Bilinmiyor'),
      );

      // 1. Dimension Check
      if ((_selectedType!.height ?? 0) > (parentType.height ?? 0) ||
          (_selectedType!.depth ?? 0) > (parentType.depth ?? 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu öğe, seçilen konumun içine fiziksel olarak sığmaz (yükseklik/derinlik).'),
          ),
        );
        return;
      }

      // 2. Capacity Check (Width / Doluluk Oranı)
      final siblings = widget.possibleLocations.where((c) => c.parentId == _selectedLocation!.locationId).toList();
      final totalWidth = siblings.fold<int>(0, (sum, c) {
        final type = widget.containerTypes.firstWhere(
              (t) => t.id == c.containerTypeId,
          orElse: () => ContainerType(id: 0, name: 'Bilinmiyor'),
        );
        return sum + (type.width ?? 0);
      });

      final thisWidth = _selectedType!.width ?? 0;
      final parentWidth = parentType.width ?? 0;
      final newTotal = totalWidth + thisWidth;

      if (newTotal > parentWidth) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bu konuma eklerseniz kapasite aşılır (%${(newTotal / parentWidth * 100).toStringAsFixed(0)} doluluk).'),
          ),
        );
        return;
      }
    }

    // Proceed with save
    final newContainer = ContainerItem(
      locationId: widget.container?.locationId ?? 0,
      code: _barcodeController.text.trim(),
      containerTypeId: _selectedType!.id,
      parentId: _selectedLocation?.locationId,
      description: null,
    );

    final success = await _containerService.saveContainer(newContainer, AuthService.authToken!);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Saklama elemanı başarıyla güncellendi'
              : 'Yeni saklama elemanı başarıyla eklendi'),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500)); // Let user see the message
      Navigator.of(context).pop({
        'container': newContainer,
        'wasEditing': _isEditing,
        'previousParent': widget.container?.parentId,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydetme işlemi başarısız')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final isEditing = _isEditing;
    final filteredLocations = isEditing
        ? widget.possibleLocations.where((c) => c.code != widget.container!.code).toList()
        : widget.possibleLocations;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Düzenle' : 'Yeni Saklama Elemanı')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Barkod input
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barkod',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Barkod giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type dropdown
              DropdownButtonFormField<ContainerType>(
                value: getValidTypes().contains(_selectedType) ? _selectedType : null,
                decoration: const InputDecoration(
                  labelText: 'Tip',
                ),
                items: [
                  if (!_isEditing)
                    const DropdownMenuItem<ContainerType>(
                      value: null,
                      child: Text('Seçim yok'),
                    ),
                  ...getValidTypes().map((type) {
                    print('📦 getValidTypes called. Parent: ${_selectedLocation?.code}');
                    return DropdownMenuItem<ContainerType>(
                      value: type,
                      child: Text(type.name),
                    );
                  }).toList(),
                ],
                onChanged: (newType) => setState(() => _selectedType = newType),
                validator: (value) =>
                value == null ? 'Tip seçiniz' : null,
              ),
              if (_selectedLocation != null &&
                  getValidTypes().length < widget.containerTypes.length)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Bazı tipler, yükseklik/derinlik veya kapasite sınırları nedeniyle listelenmiyor.',
                    style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),

              // Location dropdown (optional)
              DropdownButtonFormField<ContainerItem>(
                key: ValueKey(_selectedLocation?.locationId ?? 'no_parent'),
                value: _selectedLocation,
                decoration: const InputDecoration(
                  labelText: 'Konum (İsteğe bağlı)',
                ),
                items: [
                  const DropdownMenuItem<ContainerItem>(
                    value: null,
                    child: Text('Seçim yok'),
                  ),
                  ...filteredLocations.map((container) {
                    return DropdownMenuItem<ContainerItem>(
                      value: container,
                      child: Text(container.code),
                    );
                  }).toList(),
                ],
                onChanged: (newLocation) => setState(() {
                  _selectedLocation = newLocation;
                  _selectedType = null;
                  _cachedValidTypes = []; // clear cache so dropdown updates
                  _lastParentIdForTypes = null;
                }),
                validator: (_) => null, // optional, no validation needed
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? 'Kaydet' : 'Ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
