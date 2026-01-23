import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/models.dart';

/// 剧集网格/列表组件
class DetailEpisodeGrid extends StatelessWidget {
  final VideoDetail? detail;
  final int currentEpisodeIndex;
  final bool isLoading;
  final Function(int) onEpisodeSelected;

  const DetailEpisodeGrid({
    super.key,
    required this.detail,
    required this.currentEpisodeIndex,
    required this.isLoading,
    required this.onEpisodeSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.accentColor),
        ),
      );
    }

    if (detail == null || detail!.playSources.isEmpty) {
      return const SizedBox.shrink();
    }

    // 使用第一个播放源的剧集列表
    final episodes = detail!.playSources.first.episodes;

    // 如果只有一集（电影），简化显示
    if (episodes.length == 1) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                '选集',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${episodes.length}集)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 横向滚动选集
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: episodes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final ep = episodes[index];
              final isActive = index == currentEpisodeIndex;

              return GestureDetector(
                onTap: () => onEpisodeSelected(index),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 50),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.accentColor : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive ? AppTheme.accentColor : AppTheme.borderColor,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 当前播放标记
                      if (isActive)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.play_arrow, size: 14, color: Colors.white),
                        ),
                      Text(
                        ep.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isActive ? Colors.white : AppTheme.textPrimary,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
