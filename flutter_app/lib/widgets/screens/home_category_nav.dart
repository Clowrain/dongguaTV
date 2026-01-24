import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../blocs/home/home_bloc.dart';

/// 分类数据（包含锚点 key，与 web rowConfigs 一致）
const List<Map<String, dynamic>> categoryData = [
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

/// 分类导航栏
class HomeCategoryNav extends StatelessWidget {
  const HomeCategoryNav({super.key});

  /// 分类 key 到 rowConfig key 的映射
  static const Map<String, String> _categoryToRowKey = {
    'movie': 'movieRow',
    'tv': 'tvRow',
    'cn': 'cnRow',
    'us': 'usRow',
    'krjp': 'krjpRow',
    'anime': 'animeRow',
    'scifi': 'scifiRow',
    'action': 'actionRow',
    'comedy': 'comedyRow',
    'crime': 'crimeRow',
    'romance': 'romanceRow',
    'family': 'familyRow',
    'doc': 'docRow',
    'war': 'warRow',
    'horror': 'horrorRow',
    'mystery': 'mysteryRow',
    'fantasy': 'fantasyRow',
    'variety': 'varietyRow',
    'history': 'historyRow',
  };

  void _navigateToCategory(BuildContext context, String categoryKey, String categoryName) {
    final rowKey = _categoryToRowKey[categoryKey];
    if (rowKey == null) return;

    final config = HomeBloc.rowConfigs[rowKey];
    if (config == null) return;

    final path = config['path'] ?? '';
    final params = config['params'] ?? '';
    final sortMode = config['sortMode'];
    final title = config['title'] ?? categoryName;

    final uri = Uri(
      path: '/category/$categoryKey',
      queryParameters: {
        'title': title,
        'path': path,
        if (params.isNotEmpty) 'params': params,
        if (sortMode != null) 'sortMode': sortMode,
      },
    );
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: categoryData.length,
          itemBuilder: (context, index) {
            final cat = categoryData[index];
            final categoryKey = cat['key'] as String;
            final categoryName = cat['name'] as String;
            return _CategoryItem(
              name: categoryName,
              icon: cat['icon'] as IconData,
              colors: (cat['colors'] as List<int>).map((c) => Color(c)).toList(),
              onTap: () {
                // 跳转到分类详情页
                _navigateToCategory(context, categoryKey, categoryName);
              },
            );
          },
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
