import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/models.dart';
import '../../services/services.dart';
import 'home_event.dart';
import 'home_state.dart';

/// 首页 BLoC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ApiService _apiService;
  final CacheService _cacheService;

  /// 榜单配置（和 web rowConfigs 完全一致）
  static const Map<String, Map<String, String>> rowConfigs = {
    'movieRow': {'title': '全球震感·电影榜', 'path': '/trending/movie/week', 'params': ''},
    'tvRow': {'title': '全球必追·剧集榜', 'path': '/trending/tv/week', 'params': ''},
    'cnRow': {'title': '华语强档·国产剧', 'path': '/discover/tv', 'params': 'with_origin_country=CN', 'sortMode': 'newest'},
    'usRow': {'title': '美剧·高能剧集', 'path': '/discover/tv', 'params': 'with_origin_country=US', 'sortMode': 'newest'},
    'krjpRow': {'title': '日韩潮流·剧集', 'path': '/discover/tv', 'params': 'with_origin_country=KR|JP', 'sortMode': 'newest'},
    'animeRow': {'title': '二次元·动漫番剧', 'path': '/discover/tv', 'params': 'with_genres=16', 'sortMode': 'newest'},
    'scifiRow': {'title': '科幻奇幻·星际穿越', 'path': '/discover/movie', 'params': 'with_genres=878,14', 'sortMode': 'newest'},
    'actionRow': {'title': '动作大片·肾上腺素', 'path': '/discover/movie', 'params': 'with_genres=28', 'sortMode': 'newest'},
    'comedyRow': {'title': '开心喜剧·解压必备', 'path': '/discover/movie', 'params': 'with_genres=35', 'sortMode': 'newest'},
    'crimeRow': {'title': '犯罪悬疑·烧脑神作', 'path': '/discover/movie', 'params': 'with_genres=80,9648', 'sortMode': 'newest'},
    'romanceRow': {'title': '爱情·浪漫满屋', 'path': '/discover/movie', 'params': 'with_genres=10749', 'sortMode': 'newest'},
    'familyRow': {'title': '合家欢·温馨时刻', 'path': '/discover/movie', 'params': 'with_genres=10751', 'sortMode': 'newest'},
    'docRow': {'title': '纪录片·探索世界', 'path': '/discover/movie', 'params': 'with_genres=99', 'sortMode': 'newest'},
    'warRow': {'title': '战争·史诗巨制', 'path': '/discover/movie', 'params': 'with_genres=10752', 'sortMode': 'newest'},
    'horrorRow': {'title': '恐怖惊悚·胆小勿入', 'path': '/discover/movie', 'params': 'with_genres=27', 'sortMode': 'newest'},
    'mysteryRow': {'title': '烧脑悬疑·层层反转', 'path': '/discover/movie', 'params': 'with_genres=9648', 'sortMode': 'newest'},
    'fantasyRow': {'title': '奇幻冒险·异想天开', 'path': '/discover/movie', 'params': 'with_genres=14', 'sortMode': 'newest'},
    'varietyRow': {'title': '热门综艺·娱乐生活', 'path': '/discover/tv', 'params': 'with_genres=10764', 'sortMode': 'newest'},
    'historyRow': {'title': '历史·岁月长河', 'path': '/discover/movie', 'params': 'with_genres=36', 'sortMode': 'newest'},
  };

  HomeBloc({
    ApiService? apiService,
    CacheService? cacheService,
  })  : _apiService = apiService ?? ApiService(),
        _cacheService = cacheService ?? CacheService(),
        super(HomeInitial()) {
    on<HomeLoadRequested>(_onLoadRequested);
    on<HomeRefreshRequested>(_onRefreshRequested);
    on<HomeHistoryRefreshRequested>(_onHistoryRefreshRequested);
  }

  /// 带容错的 API 调用
  Future<TmdbPageResponse> _safeFetchRow(String key) async {
    try {
      final config = rowConfigs[key]!;
      return await _apiService.fetchRow(
        path: config['path']!,
        params: config['params'] ?? '',
        sortMode: config['sortMode'],
      );
    } catch (e) {
      return const TmdbPageResponse();
    }
  }

  /// 带容错的趋势 API 调用
  Future<TmdbPageResponse> _safeTrending() async {
    try {
      return await _apiService.getTrending();
    } catch (e) {
      return const TmdbPageResponse();
    }
  }

  /// 加载首页数据
  Future<void> _onLoadRequested(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());

    try {
      // 并行加载所有分类数据（带容错）
      final results = await Future.wait([
        _safeTrending(),            // 0: trending (for Hero)
        _safeFetchRow('movieRow'),  // 1
        _safeFetchRow('tvRow'),     // 2
        _safeFetchRow('cnRow'),     // 3
        _safeFetchRow('usRow'),     // 4
        _safeFetchRow('krjpRow'),   // 5
        _safeFetchRow('animeRow'),  // 6
        _safeFetchRow('scifiRow'),  // 7
        _safeFetchRow('actionRow'), // 8
        _safeFetchRow('comedyRow'), // 9
        _safeFetchRow('crimeRow'),  // 10
        _safeFetchRow('romanceRow'),// 11
        _safeFetchRow('familyRow'), // 12
        _safeFetchRow('docRow'),    // 13
        _safeFetchRow('warRow'),    // 14
        _safeFetchRow('horrorRow'), // 15
        _safeFetchRow('mysteryRow'),// 16
        _safeFetchRow('fantasyRow'),// 17
        _safeFetchRow('varietyRow'),// 18
        _safeFetchRow('historyRow'),// 19
      ]);

      // 获取本地观看历史
      final history = _cacheService.getWatchHistory();

      emit(HomeLoaded(
        trending: results[0].results,
        continueWatching: history.take(10).toList(),
        movieRow: results[1].results,
        tvRow: results[2].results,
        cnRow: results[3].results,
        usRow: results[4].results,
        krjpRow: results[5].results,
        animeRow: results[6].results,
        scifiRow: results[7].results,
        actionRow: results[8].results,
        comedyRow: results[9].results,
        crimeRow: results[10].results,
        romanceRow: results[11].results,
        familyRow: results[12].results,
        docRow: results[13].results,
        warRow: results[14].results,
        horrorRow: results[15].results,
        mysteryRow: results[16].results,
        fantasyRow: results[17].results,
        varietyRow: results[18].results,
        historyRow: results[19].results,
      ));
    } catch (e) {
      emit(HomeError('加载失败: $e'));
    }
  }

  /// 刷新首页数据
  Future<void> _onRefreshRequested(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    
    try {
      final results = await Future.wait([
        _safeTrending(),
        _safeFetchRow('movieRow'),
        _safeFetchRow('tvRow'),
        _safeFetchRow('cnRow'),
        _safeFetchRow('usRow'),
        _safeFetchRow('krjpRow'),
        _safeFetchRow('animeRow'),
        _safeFetchRow('scifiRow'),
        _safeFetchRow('actionRow'),
        _safeFetchRow('comedyRow'),
        _safeFetchRow('crimeRow'),
        _safeFetchRow('romanceRow'),
        _safeFetchRow('familyRow'),
        _safeFetchRow('docRow'),
        _safeFetchRow('warRow'),
        _safeFetchRow('horrorRow'),
        _safeFetchRow('mysteryRow'),
        _safeFetchRow('fantasyRow'),
        _safeFetchRow('varietyRow'),
        _safeFetchRow('historyRow'),
      ]);

      final history = _cacheService.getWatchHistory();

      emit(HomeLoaded(
        trending: results[0].results,
        continueWatching: history.take(10).toList(),
        movieRow: results[1].results,
        tvRow: results[2].results,
        cnRow: results[3].results,
        usRow: results[4].results,
        krjpRow: results[5].results,
        animeRow: results[6].results,
        scifiRow: results[7].results,
        actionRow: results[8].results,
        comedyRow: results[9].results,
        crimeRow: results[10].results,
        romanceRow: results[11].results,
        familyRow: results[12].results,
        docRow: results[13].results,
        warRow: results[14].results,
        horrorRow: results[15].results,
        mysteryRow: results[16].results,
        fantasyRow: results[17].results,
        varietyRow: results[18].results,
        historyRow: results[19].results,
      ));
    } catch (e) {
      if (currentState is HomeLoaded) {
        emit(currentState);
      } else {
        emit(HomeError('刷新失败: $e'));
      }
    }
  }

  /// 刷新观看历史
  Future<void> _onHistoryRefreshRequested(
    HomeHistoryRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;
    
    final currentState = state as HomeLoaded;
    final history = _cacheService.getWatchHistory();
    
    emit(currentState.copyWith(
      continueWatching: history.take(10).toList(),
    ));
  }
}
