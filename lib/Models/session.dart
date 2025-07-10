class Session {
  final String token;
  final String? guid;
  final String? ipAddress;
  final List<String> functionNames;
  final List<int> createableNodeIds;
  final List<int> editableNodeIds;

  Session({
    required this.token,
    this.guid,
    this.ipAddress,
    required this.functionNames,
    required this.createableNodeIds,
    required this.editableNodeIds,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      token: json['Token'],
      guid: json['Guid_'],
      ipAddress: json['IpAddress'],
      functionNames: List<String>.from(json['FunctionNames'] ?? []),
      createableNodeIds: List<int>.from(
        json['Details']?['CreateableNodeIds'] ?? [],
      ),
      editableNodeIds: List<int>.from(
        json['Details']?['EditableNodeIds'] ?? [],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'Token': token,
    'Guid_': guid,
    'IpAddress': ipAddress,
    'FunctionNames': functionNames,
    'Details': {
      'CreateableNodeIds': createableNodeIds,
      'EditableNodeIds': editableNodeIds,
    },
  };
}
