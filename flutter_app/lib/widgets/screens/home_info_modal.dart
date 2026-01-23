import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../models/models.dart';

/// 显示影片详情弹窗
void showHomeInfoModal(BuildContext context, TmdbMedia media) {
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
                          ? _VerticalModalContent(media: media, posterUrl: posterUrl)
                          : _HorizontalModalContent(media: media, posterUrl: posterUrl),
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
class _HorizontalModalContent extends StatelessWidget {
  final TmdbMedia media;
  final String posterUrl;

  const _HorizontalModalContent({
    required this.media,
    required this.posterUrl,
  });

  @override
  Widget build(BuildContext context) {
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
          child: _ModalDetails(media: media),
        ),
      ],
    );
  }
}

/// 纵向布局（窄屏/手机）
class _VerticalModalContent extends StatelessWidget {
  final TmdbMedia media;
  final String posterUrl;

  const _VerticalModalContent({
    required this.media,
    required this.posterUrl,
  });

  @override
  Widget build(BuildContext context) {
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
                  _MetaRow(media: media),
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
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 播放按钮
        _PlayButton(media: media),
      ],
    );
  }
}

/// 详情内容（宽屏使用）
class _ModalDetails extends StatelessWidget {
  final TmdbMedia media;

  const _ModalDetails({
    required this.media,
  });

  @override
  Widget build(BuildContext context) {
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
        _MetaRow(media: media),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              media.overview.isNotEmpty ? media.overview : '暂无简介',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _PlayButton(media: media),
      ],
    );
  }
}

/// 元信息行
class _MetaRow extends StatelessWidget {
  final TmdbMedia media;

  const _MetaRow({
    required this.media,
  });

  @override
  Widget build(BuildContext context) {
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
}

/// 播放按钮
class _PlayButton extends StatelessWidget {
  final TmdbMedia media;

  const _PlayButton({
    required this.media,
  });

  @override
  Widget build(BuildContext context) {
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
}
