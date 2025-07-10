import 'package:flutter/material.dart';
import '../Models/container_item.dart';
import '../Models/container_type.dart';
import '../Services/container_service.dart';
import '../Services/container_type_service.dart';
import '../auth_service.dart';
import 'edit_add_container-screen.dart';

class ContainerListScreen extends StatefulWidget {
  const ContainerListScreen({super.key});

  @override
  State<ContainerListScreen> createState() => _ContainerListScreenState();
}

class _ContainerListScreenState extends State<ContainerListScreen> {
  Future<List<ContainerItem>> _futureContainers = Future.value([]);
  final ContainerService _containerService = ContainerService();
  final ContainerTypeService _containerTypeService =
  ContainerTypeService('https://greendocsweb.koda.com.tr:444');
  Set<int> _expandedNodes = {};
  List<ContainerItem> containers = [];
  late Future<List<ContainerType>> _futureContainerTypes;
  List<ContainerType> containerTypes = [];
  bool _isLoading = true;
  Map<int, bool> _fullnessCalculated = {};
  Map<int, double> _fullnessCache = {};

  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Adı';

  final Map<String, String> _columnToField = {
    'Adı': 'code',
    'Tip': 'typeName',
    'Adet': 'adet',
  };

  final List<String> _columns = ['Adı', 'Tip', 'Adet'];

  List<ContainerItem> filteredContainers = [];

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    final types = await _containerTypeService.getContainerTypes(AuthService.authToken!);
    final items = await _containerService.getContainers(AuthService.authToken!);

    for (var container in items) {
      final match = types.firstWhere(
            (type) => type.id == container.containerTypeId,
        orElse: () => ContainerType(id: 0, name: 'Bilinmiyor', width: 0, height: 0, depth: 0),
      );
      container.typeName = match.name;
    }

    for (var container in items) {
      container.adet = items.where((c) => c.parentId == container.locationId).length;
    }

    setState(() {
      containerTypes = types;
      containers = items;
      filteredContainers = items;
      _futureContainers = Future.value(items);
      _isLoading = false;
    });
  }

  void _filterList(String keyword) {
    final selectedField = _columnToField[_selectedFilter] ?? 'code';
    setState(() {
      filteredContainers = containers.where((item) {
        final value = selectedField == 'adet'
            ? item.adet.toString()
            : (item.getFieldValue(selectedField)?.toString() ?? '');
        return value.toLowerCase().contains(keyword.toLowerCase());
      }).toList();
    });
  }

  void _loadContainers() {
    _fullnessCache.clear();
    _fullnessCalculated.clear();
    _futureContainers = _containerService.getContainers(AuthService.authToken!);
    _futureContainers.then((value) {
      // Set typeName
      for (var container in value) {
        final match = containerTypes.firstWhere(
              (type) => type.id == container.containerTypeId,
          orElse: () => ContainerType(id: 0, name: 'Bilinmiyor', width: 0, height: 0, depth: 0),
        );
        container.typeName = match.name;
      }

      // Build tree and flatten
      final tree = buildHierarchyTree(value);
      final flatList = flattenHierarchy(tree);

      // Set adet (child count)
      for (var container in flatList) {
        container.adet = flatList.where((c) => c.parentId == container.locationId).length;
      }

      setState(() {
        containers = flatList;
        filteredContainers = flatList;
      });
    });
  }


  List<HierarchyNode> buildHierarchyTree(List<ContainerItem> flatList) {
    final Map<int, HierarchyNode> lookup = {
      for (var item in flatList)
        item.locationId: HierarchyNode(item: item, children: []),
    };

    final List<HierarchyNode> roots = [];

    for (var item in flatList) {
      final node = lookup[item.locationId]!;
      if (item.parentId != null && lookup.containsKey(item.parentId)) {
        lookup[item.parentId]!.children.add(node);
      } else {
        roots.add(node);
      }
    }

    return roots;
  }

  void _editContainer(ContainerItem container, {String? previousParent}) async {
    final allContainers = containers;
    final containerTypes = this.containerTypes;

    Set<int> getDescendants(int id) {
      Set<int> result = {};
      void collect(int currentId) {
        final children = allContainers.where((c) => c.parentId == currentId);
        for (var child in children) {
          result.add(child.locationId);
          collect(child.locationId);
        }
      }
      collect(id);
      return result;
    }

    final descendants = getDescendants(container.locationId);

    final filteredLocations = allContainers
        .where((c) => c.locationId != container.locationId && !descendants.contains(c.locationId))
        .toList();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAddContainerScreen(
          container: container,
          containerTypes: containerTypes,
          allContainers: containers,
          possibleLocations: filteredLocations,
        ),
      ),
    );

    if (result != null) {
      _loadContainers();
    }
  }

  Future<void> _deleteContainer(ContainerItem container) async {
    final hasChildren = containers.any((c) => c.parentId == container.locationId);
    final typeInUse = containers.any(
          (c) => c.containerTypeId == container.containerTypeId && c.locationId != container.locationId,
    );

    if (typeInUse) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu tip başka bir saklama elemanında da kullanılıyor.')),
      );
      return;
    }

    if (hasChildren) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alt birimleri olan bir öğe silinemez.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emin misiniz?'),
        content: Text('${container.code} silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _containerService.deleteContainer(container.locationId, AuthService.authToken!);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${container.code} silindi')),
        );
        _loadEverything();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silme başarısız')),
        );
      }
    }
  }

  double calculateFullness(ContainerItem parent, List<ContainerItem> allContainers, List<ContainerType> allTypes) {
    final parentType = allTypes.firstWhere(
          (t) => t.id == parent.containerTypeId,
      orElse: () => ContainerType(id: 0, name: 'Bilinmiyor'),
    );
    final parentWidth = parentType.width ?? 0;
    final children = allContainers.where((c) => c.parentId == parent.locationId).toList();
    final usedWidth = children.fold<int>(0, (sum, c) {
      final type = allTypes.firstWhere(
            (t) => t.id == c.containerTypeId,
        orElse: () => ContainerType(id: 0, name: 'Bilinmiyor'),
      );
      return sum + (type.width ?? 0);
    });
    if (parentWidth == 0) return 0;
    return usedWidth / parentWidth;
  }

  List<ContainerItem> flattenHierarchy(List<HierarchyNode> tree) {
    final List<ContainerItem> flat = [];
    void visit(HierarchyNode node) {
      flat.add(node.item);
      for (final child in node.children) {
        visit(child);
      }
    }
    for (final node in tree) {
      visit(node);
    }
    return flat;
  }
  Widget _buildTileWithLines(HierarchyNode node, {int level = 0}) {
    final container = node.item;
    final bool isExpanded = _expandedNodes.contains(container.locationId);

    final bool isFullnessReady = _fullnessCalculated[container.locationId] == true;
    final double cachedFullness = isFullnessReady
        ? _fullnessCache[container.locationId]!.clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            // vertical line
            if (level > 0)
              Positioned(
                left: (level - 1) * 16.0 + 10,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: Colors.grey.shade400),
              ),
            Padding(
              padding: EdgeInsets.only(left: level * 16.0, right: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedNodes.remove(container.locationId);
                    } else {
                      _expandedNodes.add(container.locationId);
                    }
                  });
                },
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.inbox, size: 20, color: Colors.grey),
                  title: Text(
                    container.code,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tip: ${container.typeName ?? "Bilinmiyor"}'),
                      Text('Adet: ${container.adet}'),
                      if (isFullnessReady)
                        Row(
                          children: [
                            Text(
                              '%${(cachedFullness * 100).toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: cachedFullness,
                                minHeight: 12,
                                backgroundColor: Colors.grey[300],
                                color: cachedFullness >= 1.0 ? Colors.red : Colors.blue,
                              ),
                            ),
                          ],
                        )
                      else
                        TextButton.icon(
                          icon: const Icon(Icons.bar_chart, size: 18),
                          label: const Text("Doluluk Hesapla"),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(20, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            final fullness = calculateFullness(container, containers, containerTypes);
                            setState(() {
                              _fullnessCache[container.locationId] = fullness;
                              _fullnessCalculated[container.locationId] = true;
                            });
                          },
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.black54),
                        onPressed: () => _editContainer(container),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.black54),
                        onPressed: () => _deleteContainer(container),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (isExpanded)
          ...node.children.map((child) => _buildTileWithLines(child, level: level + 1)).toList(),
      ],
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saklama Elemanları')),
      body: FutureBuilder<List<ContainerItem>>(
        future: _futureContainers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Kayıtlı saklama elemanı yok.'));
          }

          final tree = buildHierarchyTree(filteredContainers);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterList,
                        decoration: const InputDecoration(
                          labelText: 'Ara',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: const InputDecoration(
                          labelText: 'Kolon',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        items: _columns.map((col) {
                          return DropdownMenuItem<String>(
                            value: col,
                            child: Text(col, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedFilter = newValue!;
                            _filterList(_searchController.text);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: tree.map((node) => _buildTileWithLines(node)).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class HierarchyNode {
  final ContainerItem item;
  final List<HierarchyNode> children;
  HierarchyNode({required this.item, required this.children});
}
