import 'package:flutter/material.dart';
import '../../utils/platform_utils.dart';
import 'home_media_card.dart';

/// TV 优化的媒体卡片
///
/// 为 Android TV 提供更大的卡片和焦点效果
class TvHomeMediaCard extends StatelessWidget {
  final dynamic media;
  final VoidCallback? onTap;
  final bool autofocus;

  const TvHomeMediaCard({
    super.key,
    required this.media,
    this.onTap,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    // 如果不是 TV，使用普通卡片
    if (!PlatformUtils.isAndroidTV) {
      return HomeMediaCard(
        media: media,
        onTap: onTap ?? () {},
      );
    }

    // TV 模式：更大的卡片和焦点效果
    final scale = PlatformUtils.recommendedSpacingScale;
    final fontScale = PlatformUtils.recommendedFontScale;

    return Focus(
      autofocus: autofocus,
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;

          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 180 * scale,
              margin: EdgeInsets.symmetric(horizontal: 8 * scale),
              decoration: BoxDecoration(
                border: isFocused
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      )
                    : null,
                borderRadius: BorderRadius.circular(8 * scale),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              transform: isFocused
                  ? (Matrix4.identity()..scale(1.1))
                  : Matrix4.identity(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 海报图片
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8 * scale),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: media.posterPath != null
                          ? Image.network(
                              'https://image.tmdb.org/t/p/w500${media.posterPath}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.movie,
                                    size: 48,
                                    color: Colors.white24,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.movie,
                                size: 48,
                                color: Colors.white24,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  // 标题
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4 * scale),
                    child: Text(
                      media.title ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14 * fontScale,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
