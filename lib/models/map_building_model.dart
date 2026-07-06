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
      aliases:
          (json['aliases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      keyLocations:
          (json['keyLocations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
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

  /// 大樓短代碼樣式（2~3 個純英文字母，如 AI、EB、ASP）
  static final RegExp _codeLike = RegExp(r'^[a-z]{2,3}$');

  /// 檢查搜尋關鍵字是否匹配該建築物名稱或別名
  bool matches(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return false;

    // 短英文代碼（如 AI、EM、MB）改用精確比對，避免子字串誤中
    // 內嵌英文的別名（例：「前瞻AI暨…實驗室」「EMBA教室」）。
    if (_codeLike.hasMatch(cleanQuery)) {
      if (id.replaceAll('building-', '').toLowerCase() == cleanQuery) {
        return true;
      }
      for (var alias in aliases) {
        if (alias.toLowerCase() == cleanQuery) return true;
      }
      return false;
    }

    // 其餘（中文、較長字串）維持子字串比對
    if (name.toLowerCase().contains(cleanQuery)) return true;
    for (var alias in aliases) {
      if (alias.toLowerCase().contains(cleanQuery)) return true;
    }
    return false;
  }
}
