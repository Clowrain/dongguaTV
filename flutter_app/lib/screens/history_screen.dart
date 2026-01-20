import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
              // 响应式列数
              final columns = constraints.maxWidth < 600 
                  ? 2 
                  : constraints.maxWidth < 900 
                      ? 3 
                      : 4;
              
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.65,
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

/// 历史记录网格卡片
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
          // 封面图
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.surfaceColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 封面
                  history.vodPic.isNotEmpty
                      ? Image.network(
                          history.vodPic,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                  // 剧集标签
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(180),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        history.episodeName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 标题
          Text(
            history.vodName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          // 来源
          Text(
            history.siteName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.surfaceColor,
      child: Icon(
        Icons.movie_outlined,
        size: 32,
        color: AppTheme.textSecondary.withAlpha(100),
      ),
    );
  }
}
