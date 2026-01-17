import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/models.dart';
import '../../services/services.dart';

part 'category_event.dart';
part 'category_state.dart';

/// 分类详情 BLoC
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final ApiService _apiService;
  
  // 保存当前分类配置
  String _path = '';
  String _params = '';
  String? _sortMode;

  CategoryBloc({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(CategoryInitial()) {
    on<CategoryLoadRequested>(_onLoadRequested);
    on<CategoryLoadMoreRequested>(_onLoadMoreRequested);
  }

  /// 初始加载
  Future<void> _onLoadRequested(
    CategoryLoadRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());

    // 保存配置
    _path = event.path;
    _params = event.params;
    _sortMode = event.sortMode;

    try {
      final allItems = <TmdbMedia>[];
      int totalPages = 1;

      // 加载初始页数
      for (int page = 1; page <= event.initialPages; page++) {
        final response = await _apiService.fetchRow(
          path: _path,
          params: _params,
          sortMode: _sortMode,
          page: page,
        );
        allItems.addAll(response.results);
        totalPages = response.totalPages;

        // 如果没有更多页了，提前退出
        if (page >= totalPages) break;
      }

      final loadedPages = event.initialPages.clamp(1, totalPages);

      emit(CategoryLoaded(
        key: event.key,
        title: event.title,
        items: allItems,
        currentPage: loadedPages,
        totalPages: totalPages,
        hasMore: loadedPages < totalPages,
      ));
    } catch (e) {
      emit(CategoryError('加载失败: $e'));
    }
  }

  /// 加载更多
  Future<void> _onLoadMoreRequested(
    CategoryLoadMoreRequested event,
    Emitter<CategoryState> emit,
  ) async {
    if (state is! CategoryLoaded) return;

    final currentState = state as CategoryLoaded;
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.currentPage + 1;
      final response = await _apiService.fetchRow(
        path: _path,
        params: _params,
        sortMode: _sortMode,
        page: nextPage,
      );

      emit(currentState.copyWith(
        items: [...currentState.items, ...response.results],
        currentPage: nextPage,
        totalPages: response.totalPages,
        hasMore: nextPage < response.totalPages,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }
}
