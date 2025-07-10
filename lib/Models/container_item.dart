class ContainerItem {
  final int locationId;
  final String code;
  final int? parentId;
  final int containerTypeId;
  final String? description;
  String? typeName;
  int? adet;

  ContainerItem({
    required this.locationId,
    required this.code,
    required this.containerTypeId,
    this.parentId,
    this.description,
    this.typeName,
    this.adet,
  });

  factory ContainerItem.fromJson(Map<String, dynamic> json) {
    return ContainerItem(
      locationId: json['LocationId'],
      code: json['Code'] ?? '',
      containerTypeId: json['ContainerTypeId'] ?? 0,
      parentId: json['ParentId'],
      description: json['Description'],
    );
  }

  dynamic getFieldValue(String field) {
    switch (field) {
      case 'code':
        return code;
      case 'typeName':
        return typeName;
      case 'adet':
        return adet;
      default:
        return '';
    }
  }
}

class HierarchyNode {
  final ContainerItem item;
  final List<HierarchyNode> children;

  HierarchyNode({required this.item, this.children = const []});

  static List<HierarchyNode> buildHierarchy(List<ContainerItem> containers) {
    final Map<int, HierarchyNode> lookup = {};
    final List<HierarchyNode> roots = [];

    for (var item in containers) {
      lookup[item.locationId] = HierarchyNode(item: item, children: []);
    }

    for (var item in containers) {
      final node = lookup[item.locationId]!;
      if (item.parentId != null && lookup.containsKey(item.parentId)) {
        lookup[item.parentId]!.children.add(node);
      } else {
        roots.add(node);
      }
    }

    return roots;
  }
}