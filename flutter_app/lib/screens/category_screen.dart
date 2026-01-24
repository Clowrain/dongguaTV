import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../blocs/blocs.dart';
import '../config/app_config.dart';
import '../config/theme.dart';
import '../models/models.dart';

/// 分类详情页
class CategoryScreen extends StatefulWidget {
  final String categoryKey;
  final String title;
  final String path;
  final String params;
  final String? sortMode;

  const CategoryScreen({
    super.key,
    required this.categoryKey,
    required this.title,
    required this.path,
    this.params = '',
    this.sortMode,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 根据屏幕宽度计算列数（小屏幕也保持3列，卡片更紧凑）
  int _getColumnCount(double width) {
    if (width < 400) return 3;   // 很小的手机
    if (width < 600) return 3;   // 普通手机
    if (width < 900) return 4;   // 平板竖屏
    if (width < 1200) return 5;  // 平板横屏
    return 6;                    // 桌面
  }

  /// 根据屏幕尺寸计算初始加载页数
  int _getInitialPages(double width, double height) {
    final columns = _getColumnCount(width);
    final itemHeight = (width / columns) * 1.5 + 50; // 海报高度 + 标题
    final visibleRows = (height / itemHeight).ceil();
    final itemsPerPage = 20;
    final neededItems = visibleRows * columns * 1.5; // 多加载 50%
    return (neededItems / itemsPerPage).ceil().clamp(1, 3);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final screenSize = MediaQuery.of(context).size;
        final initialPages = _getInitialPages(screenSize.width, screenSize.height);
        return CategoryBloc()
          ..add(CategoryLoadRequested(
            key: widget.categoryKey,
            title: widget.title,
            path: widget.path,
            params: widget.params,
            sortMode: widget.sortMode,
            initialPages: initialPages,
          ));
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor),
              );
            }

            if (state is CategoryError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    Text(state.message, style: const TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        final screenSize = MediaQuery.of(context).size;
                        final initialPages = _getInitialPages(screenSize.width, screenSize.height);
                        context.read<CategoryBloc>().add(CategoryLoadRequested(
                          key: widget.categoryKey,
                          title: widget.title,
                          path: widget.path,
                          params: widget.params,
                          sortMode: widget.sortMode,
                          initialPages: initialPages,
                        ));
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            }

            if (state is CategoryLoaded) {
              return _buildGridView(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildGridView(BuildContext context, CategoryLoaded state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Netflix 风格：响应式列数计算
        final columns = _getColumnCount(constraints.maxWidth);

        // Netflix 风格间距设置
        const horizontalPadding = 12.0;
        const itemSpacing = 12.0;

        final itemWidth = (constraints.maxWidth - (horizontalPadding * 2) - (itemSpacing * (columns - 1))) / columns;
        // 2:3 宽高比 + 标题和评分高度
        final itemHeight = itemWidth * 1.5 + 40;

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200) {
                context.read<CategoryBloc>().add(const CategoryLoadMoreRequested());
              }
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(horizontalPadding),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio: itemWidth / itemHeight,
                    crossAxisSpacing: itemSpacing,
                    mainAxisSpacing: 20, // 增加垂直间距
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildMediaCard(state.items[index]),
                    childCount: state.items.length,
                  ),
                ),
              ),
              // 加载更多指示器
              if (state.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.accentColor),
                    ),
                  ),
                ),
              // 已无更多
              if (!state.hasMore && state.items.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        '已加载全部 ${state.items.length} 个项目',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary.withAlpha(150),
                        ),
                      ),
                    ),
                  ),
                ),
              // 底部间距
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaCard(TmdbMedia media) {
    final posterUrl = AppConfig().getTmdbImageUrl(media.posterPath, size: 'w342');

    return GestureDetector(
      onTap: () {
        context.push('/search?keyword=${Uri.encodeComponent(media.title)}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 海报
          Expanded(
            child: Stack(
              children: [
                // 主海报图片
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: posterUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (_, __) => Container(
                            color: AppTheme.surfaceColor,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.accentColor,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.surfaceColor,
                            child: const Icon(
                              Icons.movie_outlined,
                              color: AppTheme.textSecondary,
                              size: 40,
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.surfaceColor,
                          child: const Icon(
                            Icons.movie_outlined,
                            color: AppTheme.textSecondary,
                            size: 40,
                          ),
                        ),
                ),

                // 底部渐变遮罩
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 评分标签（右上角）
                if (media.voteAverage > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            media.ratingText,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // 标题
          Text(
            media.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
