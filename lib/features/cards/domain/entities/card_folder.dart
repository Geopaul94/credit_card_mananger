/// Represents a user-created folder grouping payment cards.
class CardFolder {
  const CardFolder({
    required this.id,
    required this.name,
    this.iconKey = 'folder',
    this.colorIndex = 0,
    this.cardIds = const <String>[],
    required this.createdAt,
  });

  final String id;
  final String name;
  final String iconKey;
  final int colorIndex;
  final List<String> cardIds;
  final DateTime createdAt;

  CardFolder copyWith({
    String? id,
    String? name,
    String? iconKey,
    int? colorIndex,
    List<String>? cardIds,
    DateTime? createdAt,
  }) {
    return CardFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorIndex: colorIndex ?? this.colorIndex,
      cardIds: cardIds ?? this.cardIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconKey': iconKey,
      'colorIndex': colorIndex,
      'cardIds': cardIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CardFolder.fromMap(Map<String, dynamic> map) {
    return CardFolder(
      id: map['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: map['name'] as String? ?? 'Untitled Folder',
      iconKey: map['iconKey'] as String? ?? 'folder',
      colorIndex: (map['colorIndex'] as num?)?.toInt() ?? 0,
      cardIds: (map['cardIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
