import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import 'home_info_modal.dart';

/// Hero 轮播区域组件
class HomeHeroCarousel extends StatefulWidget {
  final List<TmdbMedia> heroList;

  const HomeHeroCarousel({
    super.key,
    required this.heroList,
  });

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  final PageController _heroPageController = PageController();
  Timer? _heroTimer;
  int _currentHeroIndex = 0;

  @override
  void initState() {
    super.initState();
    _startHeroTimer();
  }

  @override
  void dispose() {
    _heroPageController.dispose();
    _heroTimer?.cancel();
    super.dispose();
  }

  /// 启动 Hero 轮播定时器（6秒切换）
  void _startHeroTimer() {
    _heroTimer?.cancel();
    if (widget.heroList.length <= 1) return;

    _heroTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      final heroCount = widget.heroList.length;
      if (heroCount > 1) {
        _currentHeroIndex = (_currentHeroIndex + 1) % heroCount;
        _heroPageController.animateToPage(
          _currentHeroIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                itemCount: widget.heroList.length,
                itemBuilder: (context, index) {
                  final media = widget.heroList[index];
                  final imageUrl = AppConfig().getTmdbImageUrl(
                    media.backdropPath,
                    size: 'w1280',
                  );
                  return _HeroItem(
                    media: media,
                    imageUrl: imageUrl,
                    index: index,
                    heroHeight: heroHeight,
                    gradientHeight: gradientHeight,
                  );
                },
              ),

              // 固定搜索框（不随轮播滑动）
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _SearchBar(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 单个 Hero 项
class _HeroItem extends StatelessWidget {
  final TmdbMedia media;
  final String imageUrl;
  final int index;
  final double heroHeight;
  final double gradientHeight;

  const _HeroItem({
    required this.media,
    required this.imageUrl,
    required this.index,
    required this.heroHeight,
    required this.gradientHeight,
  });

  @override
  Widget build(BuildContext context) {
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
        // Logo 栏（小屏幕隐藏）
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return const SizedBox.shrink();
                }
                return _LogoBar();
              },
            ),
          ),
        ),
        // 内容区
        Positioned(
          bottom: 90,
          left: 16,
          right: 16,
          child: _HeroContent(media: media, index: index),
        ),
      ],
    );
  }
}

/// Hero 内容区
class _HeroContent extends StatelessWidget {
  final TmdbMedia media;
  final int index;

  const _HeroContent({
    required this.media,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
              onPressed: () => showHomeInfoModal(context, media),
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
      ],
    );
  }
}

/// Logo 栏
class _LogoBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
}

/// 搜索栏
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
}

/// 空 Hero 区域
class HomeEmptyHero extends StatelessWidget {
  const HomeEmptyHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      color: AppTheme.surfaceColor,
      child: SafeArea(
        child: Column(
          children: [
            _LogoBar(),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _SearchBar(),
            ),
          ],
        ),
      ),
    );
  }
}
