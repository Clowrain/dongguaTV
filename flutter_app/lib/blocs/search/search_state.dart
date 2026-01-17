import 'package:equatable/equatable.dart';

import '../../models/models.dart';

/// 搜索状态基类
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class SearchInitial extends SearchState {
  /// 搜索历史
  final List<String> history;

  const SearchInitial({this.history = const []});

  @override
  List<Object?> get props => [history];
}

/// 搜索中
class SearchLoading extends SearchState {
  final String keyword;

  const SearchLoading(this.keyword);

  @override
  List<Object?> get props => [keyword];
}

/// 搜索结果 (流式更新)
class SearchResults extends SearchState {
  final String keyword;
  
  /// 搜索结果
  final List<VideoItem> items;
  
  /// 是否还在加载
  final bool isLoading;
  
  /// 已完成的站点数
  final int completedSites;

  const SearchResults({
    required this.keyword,
    this.items = const [],
    this.isLoading = false,
    this.completedSites = 0,
  });

  SearchResults copyWith({
    List<VideoItem>? items,
    bool? isLoading,
    int? completedSites,
  }) {
    return SearchResults(
      keyword: keyword,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      completedSites: completedSites ?? this.completedSites,
    );
  }

  @override
  List<Object?> get props => [keyword, items, isLoading, completedSites];
}

/// 搜索失败
class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}
