import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../config/theme.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'player_screen.dart';

/// 详情页
class DetailScreen extends StatefulWidget {
  final String siteKey;
  final String vodId;
  final String vodName;

  const DetailScreen({
    super.key,
    required this.siteKey,
    required this.vodId,
    this.vodName = '',
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  VideoDetail? _detail;
  bool _isLoading = true;
  String? _error;
  int _selectedSourceIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await ApiService().getDetail(widget.vodId, widget.siteKey);
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.accentColor,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDetail,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_detail == null) {
      return const Center(
        child: Text(
          '未找到详情',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // 顶部海报
        _buildHeader(),
        
        // 基本信息
        SliverToBoxAdapter(
          child: _buildInfo(),
        ),
        
        // 播放线路选择
        if (_detail!.playSources.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSourceTabs(),
          ),
          // 剧集列表
          SliverToBoxAdapter(
            child: _buildEpisodeGrid(),
          ),
        ],
        
        // 简介
        SliverToBoxAdapter(
          child: _buildSynopsis(),
        ),
        
        // 底部间距
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  /// 构建顶部海报
  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 海报图片
            if (_detail!.vodPic.isNotEmpty)
              CachedNetworkImage(
                imageUrl: _detail!.vodPic,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppTheme.surfaceColor,
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.surfaceColor,
                ),
              ),
            // 渐变遮罩
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.backgroundColor.withOpacity(0.8),
                    AppTheme.backgroundColor,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建基本信息
  Widget _buildInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            _detail!.vodName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          // 别名
          if (_detail!.vodSub.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _detail!.vodSub,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // 元数据标签
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_detail!.vodScore.isNotEmpty && _detail!.vodScore != '0')
                _buildTag(
                  icon: Icons.star,
                  iconColor: Colors.amber,
                  text: _detail!.vodScore,
                ),
              if (_detail!.vodYear.isNotEmpty)
                _buildTag(text: _detail!.vodYear),
              if (_detail!.vodArea.isNotEmpty)
                _buildTag(text: _detail!.vodArea),
              if (_detail!.typeName.isNotEmpty)
                _buildTag(text: _detail!.typeName),
              if (_detail!.vodRemarks.isNotEmpty)
                _buildTag(
                  text: _detail!.vodRemarks,
                  color: AppTheme.accentColor,
                ),
            ],
          ),
          // 演员/导演
          if (_detail!.vodDirector.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '导演: ${_detail!.vodDirector}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (_detail!.vodActor.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '演员: ${_detail!.vodActor}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// 构建标签
  Widget _buildTag({
    IconData? icon,
    Color? iconColor,
    required String text,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.2) ?? AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(4),
        border: color != null
            ? Border.all(color: color.withOpacity(0.5))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor ?? AppTheme.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color ?? AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建线路选择标签页
  Widget _buildSourceTabs() {
    final sources = _detail!.playSources;
    if (sources.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择线路',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(sources.length, (index) {
                final source = sources[index];
                final isSelected = index == _selectedSourceIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(source.name),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedSourceIndex = index;
                      });
                    },
                    selectedColor: AppTheme.accentColor,
                    backgroundColor: AppTheme.surfaceColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建剧集网格
  Widget _buildEpisodeGrid() {
    final sources = _detail!.playSources;
    if (sources.isEmpty || _selectedSourceIndex >= sources.length) {
      return const SizedBox.shrink();
    }

    final episodes = sources[_selectedSourceIndex].episodes;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选集 (${episodes.length}集)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: episodes.map((ep) {
              return InkWell(
                onTap: () {
                  // 导航到播放器页面
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        vodName: _detail!.vodName,
                        siteKey: widget.siteKey,
                        vodId: widget.vodId,
                        episodeName: ep.name,
                        episodeUrl: ep.url,
                        playSources: _detail!.playSources,
                        initialSourceIndex: _selectedSourceIndex,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 60),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.borderColor,
                    ),
                  ),
                  child: Text(
                    ep.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 构建简介
  Widget _buildSynopsis() {
    if (_detail!.vodContent.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '简介',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _detail!.vodContent,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
