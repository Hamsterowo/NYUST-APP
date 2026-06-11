class MapBuilding {
  final String id;
  final String name;
  final List<String> aliases;
  final List<String> keyLocations;
  final String description;

  MapBuilding({
    required this.id,
    required this.name,
    required this.aliases,
    required this.keyLocations,
    required this.description,
  });

  factory MapBuilding.fromJson(Map<String, dynamic> json) {
    return MapBuilding(
      id: json['id'] as String,
      name: json['name'] as String,
      aliases: (json['aliases'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      keyLocations: (json['keyLocations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'aliases': aliases,
      'keyLocations': keyLocations,
      'description': description,
    };
  }

  /// 檢查搜尋關鍵字是否匹配該建築物名稱或別名
  bool matches(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return false;
    if (name.toLowerCase().contains(cleanQuery)) return true;
    for (var alias in aliases) {
      if (alias.toLowerCase().contains(cleanQuery)) return true;
    }
    return false;
  }
}
