import 'package:equatable/equatable.dart';

import '../../models/models.dart';

/// 首页状态基类
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class HomeInitial extends HomeState {}

/// 加载中
class HomeLoading extends HomeState {}

/// 加载成功
class HomeLoaded extends HomeState {
  /// 趋势列表（Hero 用）
  final List<TmdbMedia> trending;
  
  /// 继续观看
  final List<WatchHistory> continueWatching;
  
  // ============ 分类区块数据（与 web rowConfigs 一致） ============
  
  final List<TmdbMedia> movieRow;      // 电影榜
  final List<TmdbMedia> tvRow;         // 剧集榜
  final List<TmdbMedia> cnRow;         // 国产剧
  final List<TmdbMedia> usRow;         // 美剧
  final List<TmdbMedia> krjpRow;       // 日韩剧
  final List<TmdbMedia> animeRow;      // 动漫
  final List<TmdbMedia> scifiRow;      // 科幻奇幻
  final List<TmdbMedia> actionRow;     // 动作片
  final List<TmdbMedia> comedyRow;     // 喜剧
  final List<TmdbMedia> crimeRow;      // 犯罪悬疑
  final List<TmdbMedia> romanceRow;    // 爱情
  final List<TmdbMedia> familyRow;     // 家庭
  final List<TmdbMedia> docRow;        // 纪录片
  final List<TmdbMedia> warRow;        // 战争
  final List<TmdbMedia> horrorRow;     // 恐怖
  final List<TmdbMedia> mysteryRow;    // 悬疑
  final List<TmdbMedia> fantasyRow;    // 奇幻
  final List<TmdbMedia> varietyRow;    // 综艺
  final List<TmdbMedia> historyRow;    // 历史

  const HomeLoaded({
    this.trending = const [],
    this.continueWatching = const [],
    this.movieRow = const [],
    this.tvRow = const [],
    this.cnRow = const [],
    this.usRow = const [],
    this.krjpRow = const [],
    this.animeRow = const [],
    this.scifiRow = const [],
    this.actionRow = const [],
    this.comedyRow = const [],
    this.crimeRow = const [],
    this.romanceRow = const [],
    this.familyRow = const [],
    this.docRow = const [],
    this.warRow = const [],
    this.horrorRow = const [],
    this.mysteryRow = const [],
    this.fantasyRow = const [],
    this.varietyRow = const [],
    this.historyRow = const [],
  });

  HomeLoaded copyWith({
    List<TmdbMedia>? trending,
    List<WatchHistory>? continueWatching,
    List<TmdbMedia>? movieRow,
    List<TmdbMedia>? tvRow,
    List<TmdbMedia>? cnRow,
    List<TmdbMedia>? usRow,
    List<TmdbMedia>? krjpRow,
    List<TmdbMedia>? animeRow,
    List<TmdbMedia>? scifiRow,
    List<TmdbMedia>? actionRow,
    List<TmdbMedia>? comedyRow,
    List<TmdbMedia>? crimeRow,
    List<TmdbMedia>? romanceRow,
    List<TmdbMedia>? familyRow,
    List<TmdbMedia>? docRow,
    List<TmdbMedia>? warRow,
    List<TmdbMedia>? horrorRow,
    List<TmdbMedia>? mysteryRow,
    List<TmdbMedia>? fantasyRow,
    List<TmdbMedia>? varietyRow,
    List<TmdbMedia>? historyRow,
  }) {
    return HomeLoaded(
      trending: trending ?? this.trending,
      continueWatching: continueWatching ?? this.continueWatching,
      movieRow: movieRow ?? this.movieRow,
      tvRow: tvRow ?? this.tvRow,
      cnRow: cnRow ?? this.cnRow,
      usRow: usRow ?? this.usRow,
      krjpRow: krjpRow ?? this.krjpRow,
      animeRow: animeRow ?? this.animeRow,
      scifiRow: scifiRow ?? this.scifiRow,
      actionRow: actionRow ?? this.actionRow,
      comedyRow: comedyRow ?? this.comedyRow,
      crimeRow: crimeRow ?? this.crimeRow,
      romanceRow: romanceRow ?? this.romanceRow,
      familyRow: familyRow ?? this.familyRow,
      docRow: docRow ?? this.docRow,
      warRow: warRow ?? this.warRow,
      horrorRow: horrorRow ?? this.horrorRow,
      mysteryRow: mysteryRow ?? this.mysteryRow,
      fantasyRow: fantasyRow ?? this.fantasyRow,
      varietyRow: varietyRow ?? this.varietyRow,
      historyRow: historyRow ?? this.historyRow,
    );
  }

  @override
  List<Object?> get props => [
        trending, continueWatching, movieRow, tvRow, cnRow, usRow, krjpRow,
        animeRow, scifiRow, actionRow, comedyRow, crimeRow, romanceRow,
        familyRow, docRow, warRow, horrorRow, mysteryRow, fantasyRow, varietyRow, historyRow,
      ];
}

/// 加载失败
class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
