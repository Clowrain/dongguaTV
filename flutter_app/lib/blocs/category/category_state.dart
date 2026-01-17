part of 'category_bloc.dart';

/// 分类详情状态基类
abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class CategoryInitial extends CategoryState {}

/// 加载中
class CategoryLoading extends CategoryState {}

/// 加载成功
class CategoryLoaded extends CategoryState {
  final String key;
  final String title;
  final List<TmdbMedia> items;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final bool isLoadingMore;

  const CategoryLoaded({
    required this.key,
    required this.title,
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  CategoryLoaded copyWith({
    List<TmdbMedia>? items,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return CategoryLoaded(
      key: key,
      title: title,
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [key, title, items, currentPage, totalPages, hasMore, isLoadingMore];
}

/// 加载失败
class CategoryError extends CategoryState {
  final String message;

  const CategoryError(this.message);

  @override
  List<Object?> get props => [message];
}
