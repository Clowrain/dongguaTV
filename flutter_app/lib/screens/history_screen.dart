import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../config/theme.dart';
import '../models/watch_history.dart';
import '../services/watch_history_service.dart';

/// 观看历史详情页
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('观看历史'),
        actions: [
          Consumer<WatchHistoryService>(
            builder: (context, historyService, _) {
              if (historyService.histories.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: '清空历史',
                onPressed: () => _showClearConfirmDialog(context, historyService),
              );
            },
          ),
        ],
      ),
      body: Consumer<WatchHistoryService>(
        builder: (context, historyService, _) {
          final histories = historyService.histories;
          
          if (histories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: AppTheme.textSecondary.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无观看记录',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return LayoutBuilder(
            builder: (context, constraints) {
              // 根据屏幕宽度动态计算列数
              // Netflix 风格：更宽松的间距
              const minCardWidth = 140.0; // 增加最小卡片宽度
              final availableWidth = constraints.maxWidth - 24; // 减去左右 padding (12 * 2)
              final columns = (availableWidth / minCardWidth).floor().clamp(2, 6);

              // 保持 2:3 宽高比
              const aspectRatio = 2 / 3;

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 20, // 增加垂直间距
                  crossAxisSpacing: 12, // 保持水平间距
                  childAspectRatio: aspectRatio,
                ),
                itemCount: histories.length,
                itemBuilder: (context, index) {
                  return _HistoryGridCard(
                    history: histories[index],
                    onTap: () => _navigateToPlayer(context, histories[index]),
                    onLongPress: () => _showDeleteDialog(context, historyService, histories[index]),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToPlayer(BuildContext context, WatchHistory history) {
    context.push(
      '/detail',
      extra: {
        'vodName': history.vodName,
        'pic': history.vodPic,
        'sources': history.sources,
        'initialEpisodeIndex': history.episodeIndex,
        'initialPosition': Duration(seconds: history.progress),
        'initialSiteKey': history.siteKey,
      },
    );
  }

  void _showDeleteDialog(BuildContext context, WatchHistoryService service, WatchHistory history) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('删除记录'),
        content: Text('确定要删除 "${history.vodName}" 的观看记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              service.remove(history.id);
              Navigator.pop(context);
            },
            child: Text('删除', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context, WatchHistoryService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('清空历史'),
        content: const Text('确定要清空所有观看记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              service.clear();
              Navigator.pop(context);
            },
            child: Text('清空', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }
}

/// 历史记录网格卡片 - Netflix 风格
class _HistoryGridCard extends StatelessWidget {
  final WatchHistory history;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _HistoryGridCard({
    required this.history,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 海报
          Expanded(
            child: Stack(
              children: [
                // 背景图片
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: history.vodPic.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: history.vodPic,
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
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
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
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                    child: LinearProgressIndicator(
                      value: history.progressPercent,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.accentColor,
                      ),
                      minHeight: 3,
                    ),
                  ),
                ),

                // 集数标签（左上角）
                if (history.episodeName.isNotEmpty)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        history.episodeName,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // 线路标识（右上角）
                if (history.siteName.isNotEmpty)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        history.siteName,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // 标题
          Text(
            history.vodName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          // 进度文本
          if (history.progressPercent > 0)
            Text(
              '${(history.progressPercent * 100).toInt()}%',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }
}
