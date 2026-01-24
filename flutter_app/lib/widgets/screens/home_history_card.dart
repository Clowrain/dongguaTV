import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/theme.dart';
import '../../models/models.dart';

/// 观看历史卡片 - Netflix 风格横向卡片
class HomeHistoryCard extends StatelessWidget {
  final WatchHistory history;
  final VoidCallback onTap;

  const HomeHistoryCard({
    super.key,
    required this.history,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Netflix 风格：16:9 横向卡片，宽度更大
    const cardWidth = 280.0;
    const cardHeight = 157.5; // 280 * 9/16 = 157.5

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 16:9 横向海报
            SizedBox(
              height: cardHeight,
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
                                size: 48,
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.surfaceColor,
                            child: const Icon(
                              Icons.movie_outlined,
                              color: AppTheme.textSecondary,
                              size: 48,
                            ),
                          ),
                  ),

                  // 渐变遮罩（底部）
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 播放按钮覆盖层
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.black.withValues(alpha: 0.2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),

                  // 进度条（更粗，Netflix 风格）
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
                        minHeight: 4,
                      ),
                    ),
                  ),

                  // 集数标签（左上角，更醒目）
                  if (history.episodeName.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
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
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // 线路标识（右上角）
                  if (history.siteName.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          history.siteName,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 标题（更大的字体）
            Text(
              history.vodName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            // 进度文本
            if (history.progressPercent > 0)
              Text(
                '已观看 ${(history.progressPercent * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
