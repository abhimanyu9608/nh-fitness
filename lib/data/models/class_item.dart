import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/assets.dart';
import '../../core/format.dart';
import 'converters.dart';

/// An online class (`classes/{id}`, PRD section 8.1).
///
/// Videos are unlisted YouTube links (PRD CLS-2). Only members with an active
/// membership can read these documents (PRD section 9).
class ClassItem {
  const ClassItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.durationMin,
    required this.youtubeUrl,
    required this.thumbnailUrl,
    required this.published,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final int durationMin;
  final String youtubeUrl;

  /// Empty means "use the YouTube thumbnail" (PRD section 7.10).
  final String thumbnailUrl;
  final bool published;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get videoId => youtubeVideoId(youtubeUrl);

  /// The admin's thumbnail if given, else YouTube's, else a stock photo.
  String get effectiveThumbnailUrl {
    if (thumbnailUrl.trim().isNotEmpty) return thumbnailUrl.trim();
    final id = videoId;
    return id == null ? NHAssets.classFallback : NHAssets.youtubeThumbnail(id);
  }

  factory ClassItem.fromMap(String id, Map<String, dynamic> data) {
    return ClassItem(
      id: id,
      title: asString(data['title']),
      description: asString(data['description']),
      category: asString(data['category']),
      durationMin: asInt(data['durationMin']),
      youtubeUrl: asString(data['youtubeUrl']),
      thumbnailUrl: asString(data['thumbnailUrl']),
      published: asBool(data['published']),
      sortOrder: asInt(data['sortOrder'], 999),
      createdAt: asDate(data['createdAt']),
      updatedAt: asDate(data['updatedAt']),
    );
  }

  factory ClassItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      ClassItem.fromMap(doc.id, doc.data() ?? const {});

  Map<String, Object?> toMap() => {
    'title': title,
    'description': description,
    'category': category,
    'durationMin': durationMin,
    'youtubeUrl': youtubeUrl,
    'thumbnailUrl': thumbnailUrl,
    'published': published,
    'sortOrder': sortOrder,
  };

  ClassItem copyWith({
    String? title,
    String? description,
    String? category,
    int? durationMin,
    String? youtubeUrl,
    String? thumbnailUrl,
    bool? published,
    int? sortOrder,
  }) {
    return ClassItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      durationMin: durationMin ?? this.durationMin,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      published: published ?? this.published,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
