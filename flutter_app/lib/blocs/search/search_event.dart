import 'package:equatable/equatable.dart';

/// 搜索事件基类
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// 加载搜索历史
class SearchHistoryLoaded extends SearchEvent {}

/// 执行搜索
class SearchSubmitted extends SearchEvent {
  final String keyword;

  const SearchSubmitted(this.keyword);

  @override
  List<Object?> get props => [keyword];
}

/// 清空搜索
class SearchCleared extends SearchEvent {}

/// 删除搜索历史
class SearchHistoryRemoved extends SearchEvent {
  final String keyword;

  const SearchHistoryRemoved(this.keyword);

  @override
  List<Object?> get props => [keyword];
}

/// 清空搜索历史
class SearchHistoryCleared extends SearchEvent {}
