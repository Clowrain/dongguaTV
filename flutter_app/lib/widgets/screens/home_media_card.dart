import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../models/models.dart';

/// 媒体卡片 - Netflix 风格竖向海报
class HomeMediaCard extends StatelessWidget {
  final TmdbMedia media;
  final VoidCallback onTap;

  const HomeMediaCard({
    super.key,
    required this.media,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = AppConfig().getTmdbImageUrl(
      media.posterPath,
      size: 'w342',
    );

    // Netflix 风格：2:3 比例的竖向海报
    const cardWidth = AppTheme.posterWidthMobile;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 5),
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
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
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
      ),
    );
  }
}
