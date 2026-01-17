import 'package:equatable/equatable.dart';

/// 首页事件基类
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// 加载首页数据
class HomeLoadRequested extends HomeEvent {}

/// 刷新首页数据
class HomeRefreshRequested extends HomeEvent {}

/// 刷新观看历史
class HomeHistoryRefreshRequested extends HomeEvent {}
