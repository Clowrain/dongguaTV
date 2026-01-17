import 'package:equatable/equatable.dart';

/// TMDB 电影/剧集模型
class TmdbMedia extends Equatable {
  /// TMDB ID
  final int id;
  
  /// 标题
  final String title;
  
  /// 原始标题
  final String originalTitle;
  
  /// 简介
  final String overview;
  
  /// 海报路径
  final String posterPath;
  
  /// 背景图路径
  final String backdropPath;
  
  /// 评分
  final double voteAverage;
  
  /// 评分人数
  final int voteCount;
  
  /// 发布日期
  final String releaseDate;
  
  /// 媒体类型 (movie / tv)
  final String mediaType;
  
  /// 类型 ID 列表
  final List<int> genreIds;
  
  /// 人气值
  final double popularity;

  const TmdbMedia({
    required this.id,
    required this.title,
    this.originalTitle = '',
    this.overview = '',
    this.posterPath = '',
    this.backdropPath = '',
    this.voteAverage = 0,
    this.voteCount = 0,
    this.releaseDate = '',
    this.mediaType = 'movie',
    this.genreIds = const [],
    this.popularity = 0,
  });

  factory TmdbMedia.fromJson(Map<String, dynamic> json) {
    final isMovie = json['media_type'] == 'movie' || 
                   json['title'] != null;
    
    return TmdbMedia(
      id: json['id'] as int? ?? 0,
      title: (isMovie ? json['title'] : json['name']) as String? ?? '',
      originalTitle: (isMovie ? json['original_title'] : json['original_name']) as String? ?? '',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String? ?? '',
      backdropPath: json['backdrop_path'] as String? ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      voteCount: json['vote_count'] as int? ?? 0,
      releaseDate: (isMovie ? json['release_date'] : json['first_air_date']) as String? ?? '',
      mediaType: json['media_type'] as String? ?? (isMovie ? 'movie' : 'tv'),
      genreIds: (json['genre_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ?? [],
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
    );
  }

  /// 是否为电影
  bool get isMovie => mediaType == 'movie';

  /// 是否为剧集
  bool get isTv => mediaType == 'tv';

  /// 获取年份
  String get year {
    if (releaseDate.isEmpty) return '';
    return releaseDate.split('-').first;
  }

  /// 获取评分显示文本
  String get ratingText {
    if (voteAverage == 0) return '暂无评分';
    return voteAverage.toStringAsFixed(1);
  }

  @override
  List<Object?> get props => [id, mediaType];
}

/// TMDB 分页响应
class TmdbPageResponse {
  final int page;
  final int totalPages;
  final int totalResults;
  final List<TmdbMedia> results;

  const TmdbPageResponse({
    this.page = 1,
    this.totalPages = 1,
    this.totalResults = 0,
    this.results = const [],
  });

  factory TmdbPageResponse.fromJson(Map<String, dynamic> json) {
    return TmdbPageResponse(
      page: json['page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
      totalResults: json['total_results'] as int? ?? 0,
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => TmdbMedia.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// 是否有下一页
  bool get hasMore => page < totalPages;
}
