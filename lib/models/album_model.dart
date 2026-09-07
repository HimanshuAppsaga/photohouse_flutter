class AlbumItem {
  final String id;
  final String? uuid;
  final String title;
  final String? description;
  final int? sortOrder;
  final int photoCount;

  const AlbumItem({
    required this.id,
    this.uuid,
    required this.title,
    this.description,
    this.sortOrder,
    required this.photoCount,
  });

  factory AlbumItem.fromJson(Map<String, dynamic> json) {
    return AlbumItem(
      id: json['id'] != null ? json['id'].toString() : (json['uuid'] ?? ''),
      uuid: json['uuid'] as String?,
      title: (json['name'] ?? json['title'] ?? '') as String,
      description: json['description'] as String?,
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : (json['sortOrder'] is int ? json['sortOrder'] as int : null),
      photoCount: (json['photos_count'] ?? json['photoCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (uuid != null) 'uuid': uuid,
      'name': title,
      if (description != null) 'description': description,
      if (sortOrder != null) 'sort_order': sortOrder,
      'photos_count': photoCount,
    };
  }
}

