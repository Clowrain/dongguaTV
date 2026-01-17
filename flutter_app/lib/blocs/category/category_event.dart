part of 'category_bloc.dart';

/// 分类详情事件基类
abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

/// 初始加载分类数据
class CategoryLoadRequested extends CategoryEvent {
  final String key;
  final String title;
  final String path;
  final String params;
  final String? sortMode;
  final int initialPages;

  const CategoryLoadRequested({
    required this.key,
    required this.title,
    required this.path,
    this.params = '',
    this.sortMode,
    this.initialPages = 1,
  });

  @override
  List<Object?> get props => [key, title, path, params, sortMode, initialPages];
}

/// 加载更多
class CategoryLoadMoreRequested extends CategoryEvent {
  const CategoryLoadMoreRequested();
}
