import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../blocs/blocs.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../services/watch_history_service.dart';
import '../widgets/screens/home_hero_carousel.dart';
import '../widgets/screens/home_category_nav.dart';
import '../widgets/screens/home_media_card.dart';
import '../widgets/screens/home_history_card.dart';

/// 首页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 各区块的 GlobalKey（用于锚点滚动）
  final Map<String, GlobalKey> _sectionKeys = {
    'movie': GlobalKey(),
    'tv': GlobalKey(),
    'cn': GlobalKey(),
    'us': GlobalKey(),
    'krjp': GlobalKey(),
    'anime': GlobalKey(),
    'scifi': GlobalKey(),
    'action': GlobalKey(),
    'comedy': GlobalKey(),
    'crime': GlobalKey(),
    'romance': GlobalKey(),
    'family': GlobalKey(),
    'doc': GlobalKey(),
    'war': GlobalKey(),
    'horror': GlobalKey(),
    'mystery': GlobalKey(),
    'fantasy': GlobalKey(),
    'variety': GlobalKey(),
    'history': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentColor,
              ),
            );
          }

          if (state is HomeError) {
            return _buildErrorView(state.message);
          }

          if (state is HomeLoaded) {
            return _buildContent(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<HomeBloc>().add(HomeLoadRequested());
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(HomeLoaded state) {
    return RefreshIndicator(
      color: AppTheme.accentColor,
      onRefresh: () async {
        context.read<HomeBloc>().add(HomeRefreshRequested());
      },
      child: CustomScrollView(
        slivers: [
          // Hero 轮播区域
          if (state.trending.isNotEmpty)
            SliverToBoxAdapter(
              child: HomeHeroCarousel(
                heroList: state.trending.take(5).toList(),
              ),
            )
          else
            const SliverToBoxAdapter(
              child: HomeEmptyHero(),
            ),

          // 分类导航栏
          SliverToBoxAdapter(
            child: HomeCategoryNav(),
          ),

          // 继续观看
          SliverToBoxAdapter(
            child: Consumer<WatchHistoryService>(
              builder: (context, historyService, _) {
                final histories = historyService.getRecent(20);
                if (histories.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeaderWithMore('继续观看', onMoreTap: () {
                      context.push('/history');
                    }),
                    _buildHistoryRow(histories),
                  ],
                );
              },
            ),
          ),

          // 各类别内容行
          ..._buildContentRows(state),

          // 底部间距
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContentRows(HomeLoaded state) {
    final rows = <Widget>[];

    void addRow(List<TmdbMedia> items, String title, String key, String categoryKey) {
      if (items.isNotEmpty) {
        rows.addAll([
          _buildSectionHeaderWithKey(title, _sectionKeys[key]!, categoryKey: categoryKey),
          _buildMediaRow(items),
        ]);
      }
    }

    addRow(state.movieRow, '🎬 全球震感·电影榜', 'movie', 'movieRow');
    addRow(state.tvRow, '📺 全球必追·剧集榜', 'tv', 'tvRow');
    addRow(state.cnRow, '🐲 华语强档·国产剧', 'cn', 'cnRow');
    addRow(state.usRow, '🇺🇸 美剧·高能剧集', 'us', 'usRow');
    addRow(state.krjpRow, '🎭 日韩潮流·剧集', 'krjp', 'krjpRow');
    addRow(state.animeRow, '👻 二次元·动漫番剧', 'anime', 'animeRow');
    addRow(state.scifiRow, '🚀 科幻奇幻·星际穿越', 'scifi', 'scifiRow');
    addRow(state.actionRow, '💥 动作大片·肾上腺素', 'action', 'actionRow');
    addRow(state.comedyRow, '😂 开心喜剧·解压必备', 'comedy', 'comedyRow');
    addRow(state.crimeRow, '🔍 犯罪悬疑·烧脑神作', 'crime', 'crimeRow');
    addRow(state.romanceRow, '❤️ 爱情·浪漫满屋', 'romance', 'romanceRow');
    addRow(state.familyRow, '🏠 合家欢·温馨时刻', 'family', 'familyRow');
    addRow(state.docRow, '📹 纪录片·探索世界', 'doc', 'docRow');
    addRow(state.warRow, '⚔️ 战争·史诗巨制', 'war', 'warRow');
    addRow(state.horrorRow, '💀 恐怖惊悚·胆小勿入', 'horror', 'horrorRow');
    addRow(state.mysteryRow, '🔮 烧脑悬疑·层层反转', 'mystery', 'mysteryRow');
    addRow(state.fantasyRow, '✨ 奇幻冒险·异想天开', 'fantasy', 'fantasyRow');
    addRow(state.varietyRow, '🎤 热门综艺·娱乐生活', 'variety', 'varietyRow');
    addRow(state.historyRow, '📜 历史·岁月长河', 'history', 'historyRow');

    return rows;
  }

  Widget _buildSectionHeaderWithMore(String title, {required VoidCallback onMoreTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: onMoreTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '更多',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderWithKey(String title, GlobalKey key, {String? categoryKey}) {
    return SliverToBoxAdapter(
      key: key,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            if (categoryKey != null)
              GestureDetector(
                onTap: () => _navigateToCategory(categoryKey, title),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '更多',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary.withAlpha(180),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppTheme.textSecondary.withAlpha(180),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToCategory(String key, String title) {
    final config = HomeBloc.rowConfigs[key];
    if (config == null) return;

    final path = config['path'] ?? '';
    final params = config['params'] ?? '';
    final sortMode = config['sortMode'];

    final uri = Uri(
      path: '/category/$key',
      queryParameters: {
        'title': title,
        'path': path,
        if (params.isNotEmpty) 'params': params,
        if (sortMode != null) 'sortMode': sortMode,
      },
    );
    context.push(uri.toString());
  }

  Widget _buildMediaRow(List<TmdbMedia> items) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200.0,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return HomeMediaCard(
              media: item,
              onTap: () {
                context.push('/search?keyword=${Uri.encodeComponent(item.title)}');
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistoryRow(List<WatchHistory> items) {
    return SizedBox(
      height: 210, // 调整高度以适应 16:9 横向卡片 (157.5 + 标题 + 进度)
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return HomeHistoryCard(
            history: item,
            onTap: () => context.push(
              '/detail',
              extra: {
                'vodName': item.vodName,
                'pic': item.vodPic,
                'sources': item.sources,
                'initialEpisodeIndex': item.episodeIndex,
                'initialPosition': Duration(seconds: item.progress),
                'initialSiteKey': item.siteKey,
              },
            ),
          );
        },
      ),
    );
  }
}
