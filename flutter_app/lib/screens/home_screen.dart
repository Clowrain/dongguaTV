import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../blocs/blocs.dart';
import '../config/app_config.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../config/routes.dart';

/// 首页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  
  // 各区块的 GlobalKey（用于锚点滚动，与 web rowConfigs 一致）
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
    // 加载首页数据
    context.read<HomeBloc>().add(HomeLoadRequested());
    // 启动 Hero 轮播定时器
    _startHeroTimer();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heroPageController.dispose();
    _heroTimer?.cancel();
    super.dispose();
  }

  // Hero 轮播相关
  final PageController _heroPageController = PageController();
  Timer? _heroTimer;
  int _currentHeroIndex = 0;

  /// 启动 Hero 轮播定时器（6秒切换）
  void _startHeroTimer() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      final state = context.read<HomeBloc>().state;
      if (state is HomeLoaded && state.trending.isNotEmpty) {
        final heroCount = state.trending.take(5).length;
        if (heroCount > 1) {
          _currentHeroIndex = (_currentHeroIndex + 1) % heroCount;
          _heroPageController.animateToPage(
            _currentHeroIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  /// 滚动到指定区块
  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
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
                    state.message,
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

          if (state is HomeLoaded) {
            return RefreshIndicator(
              color: AppTheme.accentColor,
              onRefresh: () async {
                context.read<HomeBloc>().add(HomeRefreshRequested());
              },
              child: CustomScrollView(
                slivers: [
                  // Hero 轮播区域（本周 TOP 5）
                  if (state.trending.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildHeroCarousel(context, state.trending.take(5).toList()),
                    )
                  else
                    SliverToBoxAdapter(
                      child: _buildEmptyHero(context),
                    ),
                  
                  // 分类导航栏
                  SliverToBoxAdapter(
                    child: _buildCategoryNav(context),
                  ),
                  
                  // 继续观看
                  if (state.continueWatching.isNotEmpty) ...[
                    _buildSectionHeader('继续观看'),
                    _buildHistoryRow(state.continueWatching),
                  ],
                  
                  // 🎬 电影榜
                  if (state.movieRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('🎬 全球震感·电影榜', _sectionKeys['movie']!, categoryKey: 'movieRow'),
                    _buildMediaRow(state.movieRow),
                  ],
                  
                  // 📺 剧集榜
                  if (state.tvRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('📺 全球必追·剧集榜', _sectionKeys['tv']!, categoryKey: 'tvRow'),
                    _buildMediaRow(state.tvRow),
                  ],
                  
                  // 🐲 国产剧
                  if (state.cnRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('🐲 华语强档·国产剧', _sectionKeys['cn']!, categoryKey: 'cnRow'),
                    _buildMediaRow(state.cnRow),
                  ],
                  
                  // 🇺🇸 美剧
                  if (state.usRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('🇺🇸 美剧·高能剧集', _sectionKeys['us']!, categoryKey: 'usRow'),
                    _buildMediaRow(state.usRow),
                  ],
                  
                  // 🎭 日韩
                  if (state.krjpRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('🎭 日韩潮流·剧集', _sectionKeys['krjp']!, categoryKey: 'krjpRow'),
                    _buildMediaRow(state.krjpRow),
                  ],
                  
                  // 👻 动漫
                  if (state.animeRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('👻 二次元·动漫番剧', _sectionKeys['anime']!, categoryKey: 'animeRow'),
                    _buildMediaRow(state.animeRow),
                  ],
                  
                  // 🚀 科幻奇幻
                  if (state.scifiRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('🚀 科幻奇幻·星际穿越', _sectionKeys['scifi']!, categoryKey: 'scifiRow'),
                    _buildMediaRow(state.scifiRow),
                  ],
                  
                  // 💥 动作大片
                  if (state.actionRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('💥 动作大片·肾上腺素', _sectionKeys['action']!, categoryKey: 'actionRow'),
                    _buildMediaRow(state.actionRow),
                  ],
                  
                  // 😂 喜剧
                  if (state.comedyRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('😂 开心喜剧·解压必备', _sectionKeys['comedy']!, categoryKey: 'comedyRow'),
                    _buildMediaRow(state.comedyRow),
                  ],
                  
                  // 🔍 犯罪悬疑
                  if (state.crimeRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('🔍 犯罪悬疑·烧脑神作', _sectionKeys['crime']!, categoryKey: 'crimeRow'),
                    _buildMediaRow(state.crimeRow),
                  ],
                  
                  // ❤️ 爱情
                  if (state.romanceRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('❤️ 爱情·浪漫满屋', _sectionKeys['romance']!, categoryKey: 'romanceRow'),
                    _buildMediaRow(state.romanceRow),
                  ],
                  
                  // 🏠 家庭
                  if (state.familyRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('🏠 合家欢·温馨时刻', _sectionKeys['family']!, categoryKey: 'familyRow'),
                    _buildMediaRow(state.familyRow),
                  ],
                  
                  // 📹 纪录片
                  if (state.docRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('📹 纪录片·探索世界', _sectionKeys['doc']!, categoryKey: 'docRow'),
                    _buildMediaRow(state.docRow),
                  ],
                  
                  // ⚔️ 战争
                  if (state.warRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('⚔️ 战争·史诗巨制', _sectionKeys['war']!, categoryKey: 'warRow'),
                    _buildMediaRow(state.warRow),
                  ],
                  
                  // 💀 恐怖惊悚
                  if (state.horrorRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('💀 恐怖惊悚·胆小勿入', _sectionKeys['horror']!, categoryKey: 'horrorRow'),
                    _buildMediaRow(state.horrorRow),
                  ],
                  
                  // 🔮 悬疑
                  if (state.mysteryRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('🔮 烧脑悬疑·层层反转', _sectionKeys['mystery']!, categoryKey: 'mysteryRow'),
                    _buildMediaRow(state.mysteryRow),
                  ],
                  
                  // ✨ 奇幻
                  if (state.fantasyRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('✨ 奇幻冒险·异想天开', _sectionKeys['fantasy']!, categoryKey: 'fantasyRow'),
                    _buildMediaRow(state.fantasyRow),
                  ],
                  
                  // 🎤 综艺
                  if (state.varietyRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('🎤 热门综艺·娱乐生活', _sectionKeys['variety']!, categoryKey: 'varietyRow'),
                    _buildMediaRow(state.varietyRow),
                  ],
                  
                  // 📜 历史
                  if (state.historyRow.isNotEmpty) ...[
                    _buildSectionHeaderWithKey('📜 历史·岁月长河', _sectionKeys['history']!, categoryKey: 'historyRow'),
                    _buildMediaRow(state.historyRow),
                  ],
                  
                  // 底部间距
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// 无数据时的空 Hero
  Widget _buildEmptyHero(BuildContext context) {
    return Container(
      height: 300,
      color: AppTheme.surfaceColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildLogoBar(),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSearchBar(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建 Logo 栏（沉浸式）
  Widget _buildLogoBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'E视界',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/search'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(150),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(30)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: Colors.white.withAlpha(180),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              '搜索电影、剧集...',
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建 Hero 轮播区域（本周 TOP 5，带自动轮播）
  Widget _buildHeroCarousel(BuildContext context, List<TmdbMedia> heroList) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final heroHeight = (screenWidth * 9 / 16).clamp(400.0, 600.0);
        final gradientHeight = heroHeight * 0.6;

        return SizedBox(
          height: heroHeight,
          child: Stack(
            children: [
              // PageView 轮播
              PageView.builder(
                controller: _heroPageController,
                onPageChanged: (index) {
                  setState(() => _currentHeroIndex = index);
                },
                itemCount: heroList.length,
                itemBuilder: (context, index) {
                  final media = heroList[index];
                  final imageUrl = AppConfig().getTmdbImageUrl(
                    media.backdropPath,
                    size: 'w1280',
                  );
                  return _buildHeroItem(context, media, imageUrl, index, heroHeight, gradientHeight);
                },
              ),

              // 固定搜索框（不随轮播滑动）
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildSearchBar(context),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建单个 Hero 项（轮播中的每一页）
  Widget _buildHeroItem(BuildContext context, TmdbMedia media, String imageUrl, int index, double heroHeight, double gradientHeight) {
    return Stack(
      children: [
        // 背景图
        if (imageUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: imageUrl,
            height: heroHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: heroHeight,
              color: AppTheme.surfaceColor,
            ),
            errorWidget: (_, __, ___) => Container(
              height: heroHeight,
              color: AppTheme.surfaceColor,
              child: const Icon(Icons.movie, size: 64, color: AppTheme.textSecondary),
            ),
          )
        else
          Container(
            height: heroHeight,
            color: AppTheme.surfaceColor,
          ),
        // 顶部渐变（Logo 可见性）
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(180),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // 底部渐变
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: gradientHeight,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppTheme.backgroundColor,
                  AppTheme.backgroundColor.withAlpha(200),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Logo 栏（小屏幕隐藏，给 Hero 更多空间）
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 宽度 < 600（手机）隐藏 Logo
                if (constraints.maxWidth < 600) {
                  return const SizedBox.shrink();
                }
                return _buildLogoBar();
              },
            ),
          ),
        ),
        // 内容区（留出搜索框空间）
        Positioned(
          bottom: 90,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 本周 TOP 排名
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFe52d27), Color(0xFFb31217)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '本周 TOP ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 标题
              Text(
                media.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // 简介
              Text(
                media.overview.isNotEmpty ? media.overview : '精彩内容不容错过',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withAlpha(200),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              // 按钮
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push('/search?keyword=${Uri.encodeComponent(media.title)}');
                    },
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text('播放'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showInfoModal(context, media),
                    icon: const Icon(Icons.info_outline, size: 20),
                    label: const Text('更多信息'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withAlpha(100)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
              // 注意：搜索框已移到 _buildHeroCarousel 作为固定元素
            ],
          ),
        ),
      ],
    );
  }

  /// 构建 Hero 区域（沉浸式，响应式高度）- 保留兼容
  Widget _buildHeroSection(BuildContext context, TmdbMedia media) {
    final imageUrl = AppConfig().getTmdbImageUrl(
      media.backdropPath,
      size: 'w1280',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据屏幕宽度计算高度（16:9 宽高比，带最小最大限制）
        final screenWidth = constraints.maxWidth;
        final heroHeight = (screenWidth * 9 / 16).clamp(400.0, 600.0);
        final gradientHeight = heroHeight * 0.6;

        return SizedBox(
          height: heroHeight,
          child: Stack(
            children: [
              // 背景图
              if (imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: heroHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: heroHeight,
                    color: AppTheme.surfaceColor,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: heroHeight,
                    color: AppTheme.surfaceColor,
                    child: const Icon(Icons.movie, size: 64, color: AppTheme.textSecondary),
                  ),
                )
              else
                Container(
                  height: heroHeight,
                  width: double.infinity,
                  color: AppTheme.surfaceColor,
                  child: const Icon(Icons.movie, size: 64, color: AppTheme.textSecondary),
                ),
              
              // 顶部渐变（为 Logo 栏提供可见性）
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(180),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // 底部渐变
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: gradientHeight,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(200),
                        AppTheme.backgroundColor,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              
              // 沉浸式 Logo 栏
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: _buildLogoBar(),
                ),
              ),
              
              // 底部内容（标题、简介、按钮 + 搜索框）
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      Text(
                        media.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // 简介
                      if (media.overview.isNotEmpty)
                        Text(
                          media.overview,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withAlpha(200),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 12),
                      // 按钮区
                      Row(
                        children: [
                          // 播放按钮
                          ElevatedButton.icon(
                            onPressed: () {
                              context.push('/search?keyword=${Uri.encodeComponent(media.title)}');
                            },
                            icon: const Icon(Icons.play_arrow, size: 20),
                            label: const Text('播放'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 更多信息按钮
                          OutlinedButton.icon(
                            onPressed: () {
                              _showInfoModal(context, media);
                            },
                            icon: const Icon(Icons.info_outline, size: 20),
                            label: const Text('更多信息'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withAlpha(100)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 搜索框
                      _buildSearchBar(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 分类数据（包含锚点 key，与 web rowConfigs 一致）
  static const List<Map<String, dynamic>> _categories = [
    {'name': '电影', 'icon': Icons.movie_outlined, 'key': 'movie', 'colors': [0xFFFF512F, 0xFFDD2476]},
    {'name': '剧集', 'icon': Icons.tv_outlined, 'key': 'tv', 'colors': [0xFF4facfe, 0xFF00f2fe]},
    {'name': '国产', 'icon': Icons.flag_outlined, 'key': 'cn', 'colors': [0xFFf093fb, 0xFFf5576c]},
    {'name': '美剧', 'icon': Icons.language, 'key': 'us', 'colors': [0xFFa18cd1, 0xFFfbc2eb]},
    {'name': '日韩', 'icon': Icons.emoji_emotions_outlined, 'key': 'krjp', 'colors': [0xFF84fab0, 0xFF8fd3f4]},
    {'name': '动漫', 'icon': Icons.animation_outlined, 'key': 'anime', 'colors': [0xFFa1c4fd, 0xFFc2e9fb]},
    {'name': '科幻', 'icon': Icons.rocket_launch_outlined, 'key': 'scifi', 'colors': [0xFFfa709a, 0xFFfee140]},
    {'name': '动作', 'icon': Icons.sports_martial_arts, 'key': 'action', 'colors': [0xFF30cfd0, 0xFF330867]},
    {'name': '喜剧', 'icon': Icons.sentiment_very_satisfied, 'key': 'comedy', 'colors': [0xFFffecd2, 0xFFfcb69f]},
    {'name': '犯罪', 'icon': Icons.search, 'key': 'crime', 'colors': [0xFF667eea, 0xFF764ba2]},
    {'name': '爱情', 'icon': Icons.favorite_outline, 'key': 'romance', 'colors': [0xFFff9a9e, 0xFFfecfef]},
    {'name': '家庭', 'icon': Icons.home_outlined, 'key': 'family', 'colors': [0xFFa8edea, 0xFFfed6e3]},
    {'name': '纪录', 'icon': Icons.videocam_outlined, 'key': 'doc', 'colors': [0xFFfff1eb, 0xFFace0f9]},
    {'name': '战争', 'icon': Icons.shield_outlined, 'key': 'war', 'colors': [0xFFff0844, 0xFFffb199]},
    {'name': '恐怖', 'icon': Icons.nightlight_round, 'key': 'horror', 'colors': [0xFF434343, 0xFF000000]},
    {'name': '悬疑', 'icon': Icons.psychology_outlined, 'key': 'mystery', 'colors': [0xFF667eea, 0xFF764ba2]},
    {'name': '奇幻', 'icon': Icons.auto_awesome, 'key': 'fantasy', 'colors': [0xFFfccb90, 0xFFd57eeb]},
    {'name': '综艺', 'icon': Icons.mic_outlined, 'key': 'variety', 'colors': [0xFFd299c2, 0xFFfef9d7]},
    {'name': '历史', 'icon': Icons.account_balance_outlined, 'key': 'history', 'colors': [0xFFaccbee, 0xFFe7f0fd]},
  ];

  /// 构建分类导航栏
  Widget _buildCategoryNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final sectionKey = cat['key'] as String;
            return _CategoryItem(
              name: cat['name'] as String,
              icon: cat['icon'] as IconData,
              colors: (cat['colors'] as List<int>).map((c) => Color(c)).toList(),
              onTap: () {
                // 滚动到对应区块
                _scrollToSection(_sectionKeys[sectionKey]!);
              },
            );
          },
        ),
      ),
    );
  }

  /// 显示影片详情弹窗（响应式布局）
  void _showInfoModal(BuildContext context, TmdbMedia media) {
    final posterUrl = AppConfig().getTmdbImageUrl(
      media.posterPath,
      size: 'w500',
    );
    final backdropUrl = AppConfig().getTmdbImageUrl(
      media.backdropPath,
      size: 'w1280',
    );

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(200),
      builder: (dialogContext) => LayoutBuilder(
        builder: (context, constraints) {
          // 根据屏幕尺寸判断布局方向
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final isNarrow = screenWidth < 500;
          
          // 动态计算弹窗尺寸
          final dialogWidth = isNarrow 
              ? screenWidth * 0.92 
              : (screenWidth * 0.8).clamp(400.0, 700.0);
          // 计算最小最大高度限制
          final minHeight = isNarrow ? 300.0 : 280.0;
          final maxHeight = isNarrow 
              ? (screenHeight * 0.8).clamp(400.0, 700.0)
              : (screenHeight * 0.75).clamp(350.0, 550.0);

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 16 : 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogWidth,
                minHeight: minHeight,
                maxHeight: maxHeight,
              ),
              child: IntrinsicHeight(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // 背景图
                      if (backdropUrl.isNotEmpty)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ShaderMask(
                              shaderCallback: (rect) => LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withAlpha(60),
                                  Colors.transparent,
                                ],
                              ).createShader(rect),
                              blendMode: BlendMode.dstIn,
                              child: CachedNetworkImage(
                                imageUrl: backdropUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      // 内容区
                      Padding(
                        padding: EdgeInsets.all(isNarrow ? 16 : 20),
                        child: isNarrow 
                            ? _buildVerticalModalContent(dialogContext, media, posterUrl)
                            : _buildHorizontalModalContent(dialogContext, media, posterUrl),
                      ),
                      // 关闭按钮
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.white.withAlpha(180)),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 横向布局（宽屏）
  Widget _buildHorizontalModalContent(BuildContext context, TmdbMedia media, String posterUrl) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 海报
        if (posterUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: posterUrl,
              width: 140,
              height: 210,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 140, height: 210,
                color: AppTheme.backgroundColor,
              ),
              errorWidget: (_, __, ___) => Container(
                width: 140, height: 210,
                color: AppTheme.backgroundColor,
                child: const Icon(Icons.movie, size: 48),
              ),
            ),
          ),
        const SizedBox(width: 20),
        // 详情
        Expanded(
          child: _buildModalDetails(context, media),
        ),
      ],
    );
  }

  /// 纵向布局（窄屏/手机）
  Widget _buildVerticalModalContent(BuildContext context, TmdbMedia media, String posterUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部：海报 + 基本信息
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (posterUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: posterUrl,
                  width: 100,
                  height: 150,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 100, height: 150,
                    color: AppTheme.backgroundColor,
                    child: const Icon(Icons.movie, size: 36),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(media),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 简介
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              media.overview.isNotEmpty ? media.overview : '暂无简介',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 播放按钮
        _buildPlayButton(context, media),
      ],
    );
  }

  /// 详情内容（宽屏使用）
  Widget _buildModalDetails(BuildContext context, TmdbMedia media) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          media.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        _buildMetaRow(media),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              media.overview.isNotEmpty ? media.overview : '暂无简介',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildPlayButton(context, media),
      ],
    );
  }

  /// 元信息行
  Widget _buildMetaRow(TmdbMedia media) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        if (media.voteAverage > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(media.ratingText, style: const TextStyle(color: Colors.amber)),
            ],
          ),
        if (media.year.isNotEmpty)
          Text(media.year, style: const TextStyle(color: AppTheme.textSecondary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.textSecondary),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            media.isMovie ? '电影' : '剧集',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  /// 播放按钮
  Widget _buildPlayButton(BuildContext context, TmdbMedia media) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          context.push('/search?keyword=${Uri.encodeComponent(media.title)}');
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('立即播放'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// 构建区域标题
  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  /// 构建带 GlobalKey 和"更多"按钮的区域标题
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

  /// 跳转到分类详情页
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

  /// 构建媒体横向列表
  Widget _buildMediaRow(List<TmdbMedia> items) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _MediaCard(
              media: item,
              onTap: () => context.push('/search?keyword=${Uri.encodeComponent(item.title)}'),
            );
          },
        ),
      ),
    );
  }

  /// 构建观看历史横向列表
  Widget _buildHistoryRow(List<WatchHistory> items) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _HistoryCard(
              history: item,
              onTap: () => AppRoutes.goToDetail(
                context,
                siteKey: item.siteKey,
                vodId: item.vodId,
                vodName: item.vodName,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 媒体卡片
class _MediaCard extends StatelessWidget {
  final TmdbMedia media;
  final VoidCallback onTap;

  const _MediaCard({
    required this.media,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = AppConfig().getTmdbImageUrl(
      media.posterPath,
      size: 'w342',
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppTheme.posterWidthMobile,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 海报
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppTheme.surfaceColor,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.surfaceColor,
                          child: const Icon(
                            Icons.movie,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      )
                    : Container(
                        color: AppTheme.surfaceColor,
                        child: const Icon(
                          Icons.movie,
                          color: AppTheme.textSecondary,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // 标题
            Text(
              media.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
            ),
            // 评分
            if (media.voteAverage > 0)
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    media.ratingText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 观看历史卡片
class _HistoryCard extends StatelessWidget {
  final WatchHistory history;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.history,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppTheme.posterWidthMobile,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 海报
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: history.vodPic.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: history.vodPic,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (_, __) => Container(
                              color: AppTheme.surfaceColor,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppTheme.surfaceColor,
                              child: const Icon(
                                Icons.movie,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.surfaceColor,
                            child: const Icon(
                              Icons.movie,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                  ),
                  // 进度条
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      child: LinearProgressIndicator(
                        value: history.progressPercent,
                        backgroundColor: Colors.black54,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.accentColor,
                        ),
                        minHeight: 3,
                      ),
                    ),
                  ),
                  // 集数标签
                  if (history.episodeName.isNotEmpty)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          history.episodeName,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 标题
            Text(
              history.vodName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分类导航项
class _CategoryItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.name,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标容器
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: colors.first.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            // 名称
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
