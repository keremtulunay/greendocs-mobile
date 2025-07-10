class ContainerType {
  final int id;
  final String name;
  final int? width;
  final int? height;
  final int? depth;

  ContainerType({
    required this.id,
    required this.name,
    this.width,
    this.height,
    this.depth,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ContainerType &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory ContainerType.fromJson(Map<String, dynamic> json) {
    return ContainerType(
      id: json['ContainerTypeId'],
      name: json['Name'] ?? '',
      width: json['Width'] ?? 0,
      height: json['Height'] ?? 0,
        depth: json['Length'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ContainerTypeId': id,
      'Name': name,
      'Width': width,
      'Height': height,
      'Length': depth,
    };
  }
}
extension ContainerTypeField on ContainerType {
  String getFieldValue(String field) {
    switch (field) {
      case 'name':
        return name;
      case 'width':
        return width?.toString() ?? '';
      case 'height':
        return height?.toString() ?? '';
      case 'depth':
        return depth?.toString() ?? '';
      default:
        return '';
    }
  }
}