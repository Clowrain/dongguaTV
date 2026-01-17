import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/models.dart';
import '../../services/services.dart';
import 'search_event.dart';
import 'search_state.dart';

/// 搜索 BLoC
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ApiService _apiService;
  final CacheService _cacheService;
  
  StreamSubscription? _searchSubscription;
  // 用于取消进行中搜索的标识
  int _currentSearchId = 0;

  SearchBloc({
    ApiService? apiService,
    CacheService? cacheService,
  })  : _apiService = apiService ?? ApiService(),
        _cacheService = cacheService ?? CacheService(),
        super(const SearchInitial()) {
    on<SearchHistoryLoaded>(_onHistoryLoaded);
    on<SearchSubmitted>(_onSubmitted);
    on<SearchCleared>(_onCleared);
    on<SearchHistoryRemoved>(_onHistoryRemoved);
    on<SearchHistoryCleared>(_onHistoryCleared);
  }

  /// 加载搜索历史
  void _onHistoryLoaded(
    SearchHistoryLoaded event,
    Emitter<SearchState> emit,
  ) {
    final history = _cacheService.getSearchHistory();
    emit(SearchInitial(history: history));
  }

  /// 执行搜索
  Future<void> _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    final keyword = event.keyword.trim();
    if (keyword.isEmpty) return;

    // 取消之前的搜索
    await _searchSubscription?.cancel();
    _searchSubscription = null;
    
    // 增加搜索ID，使之前的搜索回调失效
    final searchId = ++_currentSearchId;

    // 保存搜索历史
    await _cacheService.addSearchHistory(keyword);

    emit(SearchLoading(keyword));

    // 收集所有结果
    final allItems = <VideoItem>[];
    final seenIds = <String>{};
    var completedSites = 0;

    try {
      // 使用 await for 迭代流
      await for (final items in _apiService.searchStream(keyword)) {
        // 检查是否已取消（通过 searchId 判断）
        if (searchId != _currentSearchId || emit.isDone) return;
        
        // 去重
        for (final item in items) {
          if (!seenIds.contains(item.uniqueId)) {
            seenIds.add(item.uniqueId);
            allItems.add(item);
          }
        }
        completedSites++;

        // 再次检查取消状态
        if (searchId != _currentSearchId || emit.isDone) return;

        // 发射中间状态
        emit(SearchResults(
          keyword: keyword,
          items: List.from(allItems),
          isLoading: true,
          completedSites: completedSites,
        ));
      }

      // 流完成后，检查是否仍有效
      if (searchId != _currentSearchId || emit.isDone) return;
      
      emit(SearchResults(
        keyword: keyword,
        items: allItems,
        isLoading: false,
        completedSites: completedSites,
      ));
    } catch (e) {
      if (searchId != _currentSearchId || emit.isDone) return;
      
      if (allItems.isEmpty) {
        emit(SearchError('搜索失败: $e'));
      } else {
        // 有部分结果时保留
        emit(SearchResults(
          keyword: keyword,
          items: allItems,
          isLoading: false,
          completedSites: completedSites,
        ));
      }
    }
  }

  /// 清空搜索
  void _onCleared(
    SearchCleared event,
    Emitter<SearchState> emit,
  ) {
    // 增加 searchId 使进行中的搜索失效
    _currentSearchId++;
    _searchSubscription?.cancel();
    _searchSubscription = null;
    final history = _cacheService.getSearchHistory();
    emit(SearchInitial(history: history));
  }

  /// 删除搜索历史
  Future<void> _onHistoryRemoved(
    SearchHistoryRemoved event,
    Emitter<SearchState> emit,
  ) async {
    await _cacheService.removeSearchHistory(event.keyword);
    final history = _cacheService.getSearchHistory();
    emit(SearchInitial(history: history));
  }

  /// 清空搜索历史
  Future<void> _onHistoryCleared(
    SearchHistoryCleared event,
    Emitter<SearchState> emit,
  ) async {
    await _cacheService.clearSearchHistory();
    emit(const SearchInitial());
  }

  @override
  Future<void> close() {
    _searchSubscription?.cancel();
    return super.close();
  }
}
