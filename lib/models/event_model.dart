import 'album_model.dart';

class EventItem {
  final String id;
  final String title;
  final String tag;
  final String date;
  final int photoCount;
  final int albumCount;
  final bool isReadyToShare;
  final String? location;
  final String? description;
  final bool clientSelectionEnabled;
  final String? createdAt;
  final String? updatedAt;
  final List<AlbumItem> albums;

  const EventItem({
    required this.id,
    required this.title,
    required this.tag,
    required this.date,
    required this.photoCount,
    required this.albumCount,
    this.isReadyToShare = true,
    this.location,
    this.description,
    this.clientSelectionEnabled = false,
    this.createdAt,
    this.updatedAt,
    this.albums = const [],
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    List<AlbumItem> loadedAlbums = const [];
    if (json['albums'] is List) {
      loadedAlbums = (json['albums'] as List)
          .map((a) => AlbumItem.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return EventItem(
      id: (json['uuid'] ?? json['id'] ?? '') as String,
      title: (json['name'] ?? json['title'] ?? '') as String,
      tag: (json['type'] ?? json['tag'] ?? 'general') as String,
      date: (json['event_date'] ?? json['date'] ?? '') as String,
      photoCount: (json['photos_count'] ?? json['photoCount'] ?? 0) as int,
      albumCount: (json['albums_count'] ?? json['albumCount'] ?? 0) as int,
      isReadyToShare: (json['gallery_enabled'] ?? json['isReadyToShare'] ?? true) as bool,
      location: json['location'] as String?,
      description: json['description'] as String?,
      clientSelectionEnabled: (json['client_selection_enabled'] ?? false) as bool,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      albums: loadedAlbums,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': id,
      'name': title,
      'type': tag,
      'event_date': date,
      'photos_count': photoCount,
      'albums_count': albumCount,
      'gallery_enabled': isReadyToShare,
      if (location != null) 'location': location,
      if (description != null) 'description': description,
      'client_selection_enabled': clientSelectionEnabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (albums.isNotEmpty) 'albums': albums.map((a) => a.toJson()).toList(),
    };
  }

  EventItem copyWith({
    String? id,
    String? title,
    String? tag,
    String? date,
    int? photoCount,
    int? albumCount,
    bool? isReadyToShare,
    String? location,
    String? description,
    bool? clientSelectionEnabled,
    String? createdAt,
    String? updatedAt,
    List<AlbumItem>? albums,
  }) {
    return EventItem(
      id: id ?? this.id,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      date: date ?? this.date,
      photoCount: photoCount ?? this.photoCount,
      albumCount: albumCount ?? this.albumCount,
      isReadyToShare: isReadyToShare ?? this.isReadyToShare,
      location: location ?? this.location,
      description: description ?? this.description,
      clientSelectionEnabled: clientSelectionEnabled ?? this.clientSelectionEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      albums: albums ?? this.albums,
    );
  }


  static List<EventItem> get sampleEvents => [
        const EventItem(
          id: '1',
          title: 'Maulik',
          tag: 'Ring Ceremony',
          date: '2026-08-26',
          photoCount: 2,
          albumCount: 1,
          isReadyToShare: true,
          albums: [
            AlbumItem(
              id: '1',
              title: 'Maulik ring ceremony',
              photoCount: 1,
            ),
          ],
        ),
        const EventItem(
          id: '2',
          title: 'deep',
          tag: 'Wedding',
          date: '2026-07-23',
          photoCount: 90,
          albumCount: 2,
          isReadyToShare: true,
          albums: [
            AlbumItem(
              id: '2',
              title: 'Sangeet Night',
              photoCount: 45,
            ),
            AlbumItem(
              id: '3',
              title: 'Wedding Ceremony',
              photoCount: 45,
            ),
          ],
        ),
        const EventItem(
          id: '3',
          title: 'Wedding',
          tag: 'Wedding',
          date: '2026-01-31',
          photoCount: 133,
          albumCount: 1,
          isReadyToShare: true,
          albums: [
            AlbumItem(
              id: '4',
              title: 'Reception Party',
              photoCount: 133,
            ),
          ],
        ),
      ];
}
