import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/donggua_player.dart';

/// 多源详情页（从搜索结果点击进入）
/// 显示多个视频源及其延迟，类似 web player-layout
class MultiSourceDetailScreen extends StatefulWidget {
  final String vodName;
  final String pic;
  final List<VideoItem> sources;

  const MultiSourceDetailScreen({
    super.key,
    required this.vodName,
    required this.pic,
    required this.sources,
  });

  @override
  State<MultiSourceDetailScreen> createState() => _MultiSourceDetailScreenState();
}

class _SourceWithLatency {
  final VideoItem source;
  int? latency; // null = 测试中, -1 = 超时/失败
  String testType; // direct, proxy, server
  bool useProxy; // 是否使用代理
  String? proxyUrl; // 代理 URL
  VideoDetail? cachedDetail; // 缓存的详情数据

  _SourceWithLatency({
    required this.source, 
    this.latency, 
    this.testType = 'server',
    this.useProxy = false,
    this.proxyUrl,
    this.cachedDetail,
  });
}

class _MultiSourceDetailScreenState extends State<MultiSourceDetailScreen> {
  List<_SourceWithLatency> _sourcesWithLatency = [];
  _SourceWithLatency? _currentSource;
  VideoDetail? _currentDetail;
  bool _isLoadingDetail = false;
  bool _isTestingSources = true;
  int _currentEpisodeIndex = 0;
  bool _isSynopsisExpanded = false;
  
  // 播放相关
  String _currentVideoUrl = '';
  final GlobalKey<DongguaPlayerState> _playerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 初始化源列表
    _sourcesWithLatency = widget.sources.map((s) => _SourceWithLatency(source: s)).toList();
    
    // 开始测速（自动选择最快线路会在测速完成后进行）
    _testAllSources();
  }
  
  bool _hasAutoSelected = false; // 防止重复自动选择
  
  /// 测试所有源的延迟
  Future<void> _testAllSources() async {
    setState(() => _isTestingSources = true);
    
    const fastThreshold = 600; // 快速返回阈值 (ms)
    const earlyReturnCount = 2; // 找到这么多快速线路就提前返回
    const maxWaitTime = Duration(seconds: 5); // 最大等待时间
    
    // 设置超时自动选择定时器
    Future.delayed(maxWaitTime, () {
      if (!_hasAutoSelected && mounted) {
        _autoSelectBestSource('超时');
      }
    });
    
    final futures = <Future>[];
    for (final source in _sourcesWithLatency) {
      futures.add(
        // 包裹在 try-catch 中确保单个源失败不影响其他源
        Future(() async {
          try {
            await _testSourceLatency(source);
          } catch (e) {
            // 单个源测速失败，设置为超时状态但不中断其他源
            if (mounted) {
              setState(() {
                source.latency = 9999;
                source.testType = 'failed';
              });
            }
          }
        }).then((_) {
          // 每个测速完成后检查是否可以提前返回
          if (!_hasAutoSelected && mounted) {
            final fastSources = _sourcesWithLatency.where((s) =>
              s.testType == 'direct' && s.latency != null && s.latency! > 0 && s.latency! < fastThreshold
            ).toList();
            
            if (fastSources.length >= earlyReturnCount) {
              _autoSelectBestSource('快速');
            }
          }
        }),
      );
    }
    
    await Future.wait(futures);
    
    // 检查 mounted 避免 setState after dispose
    if (!mounted) return;
    
    // 按延迟排序（快的在前）
    _sourcesWithLatency.sort((a, b) {
      if (a.latency == null || a.latency == -1) return 1;
      if (b.latency == null || b.latency == -1) return -1;
      return a.latency!.compareTo(b.latency!);
    });
    
    // 如果还没自动选择，选择最快的
    if (!_hasAutoSelected) {
      _autoSelectBestSource('完成');
    }
    
    setState(() => _isTestingSources = false);
  }
  
  /// 自动选择最快的源
  void _autoSelectBestSource(String reason) {
    if (_hasAutoSelected) return;
    
    // 优先选择用户端测速(direct)的结果
    var bestSources = _sourcesWithLatency.where((s) =>
      s.testType == 'direct' && s.latency != null && s.latency! > 0 && s.latency! < 9000
    ).toList();
    
    if (bestSources.isEmpty) {
      // 回退到所有有效测速结果
      bestSources = _sourcesWithLatency.where((s) =>
        s.latency != null && s.latency! > 0 && s.latency! < 9000
      ).toList();
    }
    
    if (bestSources.isNotEmpty) {
      bestSources.sort((a, b) => a.latency!.compareTo(b.latency!));
      final best = bestSources.first;
      debugPrint('🎯 [$reason返回] 自动选择: ${best.source.siteName} (${best.latency}ms ${best.testType})');
      _hasAutoSelected = true;
      _switchSource(best);
    } else if (_sourcesWithLatency.isNotEmpty) {
      // 没有测速结果，选择第一个
      debugPrint('⚠️ 无测速结果，选择第一个源');
      _hasAutoSelected = true;
      _switchSource(_sourcesWithLatency.first);
    }
  }

  /// 测试单个源的延迟（完全匹配 HTML openDetail 逻辑）
  /// 流程：1) 获取详情解析m3u8 2) 直连测试 3) 代理测试 4) 服务器回退
  Future<void> _testSourceLatency(_SourceWithLatency source) async {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 5);
    dio.options.receiveTimeout = const Duration(seconds: 5);
    
    try {
      // 1. 获取该源的视频详情
      VideoDetail? detail;
      try {
        detail = await ApiService().getDetail(
          source.source.vodId,
          source.source.siteKey,
        );
        source.cachedDetail = detail;
      } catch (e) {
        // 详情获取失败，回退到服务器测速
        await _fallbackToServerTest(source);
        return;
      }
      
      // 2. 解析出第一个视频 URL（m3u8）
      String? videoUrl;
      if (detail != null && detail.playSources.isNotEmpty) {
        final firstSource = detail.playSources.first;
        if (firstSource.episodes.isNotEmpty) {
          videoUrl = firstSource.episodes.first.url;
        }
      }
      
      if (videoUrl == null || !videoUrl.startsWith('http')) {
        await _fallbackToServerTest(source);
        return;
      }
      
      // 3. 直连测试 m3u8 URL
      bool directSuccess = false;
      int directLatency = 0;
      const int slowThreshold = 1500; // 超过此延迟视为慢速
      
      try {
        final stopwatch = Stopwatch()..start();
        await dio.head(
          videoUrl,
          options: Options(validateStatus: (_) => true),
        );
        stopwatch.stop();
        directLatency = stopwatch.elapsedMilliseconds;
        
        if (directLatency < 5000) {
          directSuccess = true;
          if (mounted) {
            setState(() {
              source.latency = directLatency;
              source.testType = 'direct';
            });
          }
        }
      } catch (e) {
        // 直连失败，继续尝试代理
      }
      
      // 4. 如果直连失败或太慢，尝试代理
      final corsProxyUrl = AppConfig().corsProxyUrl;
      final shouldTryProxy = !directSuccess || (directSuccess && directLatency > slowThreshold);
      
      if (shouldTryProxy && corsProxyUrl.isNotEmpty) {
        try {
          final proxyUrl = '$corsProxyUrl/?url=${Uri.encodeComponent(videoUrl)}';
          final stopwatch = Stopwatch()..start();
          
          await dio.head(
            proxyUrl,
            options: Options(validateStatus: (_) => true),
          );
          stopwatch.stop();
          final proxyLatency = stopwatch.elapsedMilliseconds;
          
          // 如果直连失败则用代理，如果代理快30%以上也用代理
          final useProxy = !directSuccess || (proxyLatency < directLatency * 0.7);
          
          if (useProxy && mounted) {
            setState(() {
              source.latency = proxyLatency;
              source.testType = 'proxy';
              source.useProxy = true;
              source.proxyUrl = corsProxyUrl;
            });
            return;
          }
        } catch (e) {
          // 代理也失败
        }
      }
      
      // 如果直连成功了就返回（已在上面设置了状态）
      if (directSuccess) return;
      
      // 5. 都失败，回退到服务器测速
      await _fallbackToServerTest(source);
      
    } catch (e) {
      if (mounted) {
        setState(() {
          source.latency = 9999;
          source.testType = 'server';
        });
      }
    }
  }
  
  /// 回退到服务器端测速
  Future<void> _fallbackToServerTest(_SourceWithLatency source) async {
    try {
      final latency = await ApiService().checkSiteLatency(source.source.siteKey);
      if (mounted) {
        setState(() {
          source.latency = latency ?? 9999;
          source.testType = 'server';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          source.latency = 9999;
          source.testType = 'server';
        });
      }
    }
  }

  /// 切换源
  Future<void> _switchSource(_SourceWithLatency source) async {
    if (!mounted) return;
    if (_currentSource?.source.siteKey == source.source.siteKey) return;
    
    setState(() {
      _currentSource = source;
      _isLoadingDetail = true;
      _currentEpisodeIndex = 0;
      _currentVideoUrl = ''; // 清空当前URL
    });

    try {
      final detail = await ApiService().getDetail(
        source.source.vodId,
        source.source.siteKey,
      );
      if (mounted) {
        setState(() {
          _currentDetail = detail;
          _isLoadingDetail = false;
        });
        
        // 自动播放第一集（类似 Web 版逻辑）
        if (detail != null && detail.playSources.isNotEmpty && detail.playSources.first.episodes.isNotEmpty) {
          debugPrint('🎯 Detail loaded, auto-playing first episode');
          // 使用 post frame callback 确保 UI 更新后再播放
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _playEpisode(0);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDetail = false;
        });
      }
    }
  }

  /// 获取快速线路 (< 600ms)
  List<_SourceWithLatency> get _fastSources =>
      _sourcesWithLatency.where((s) => s.latency != null && s.latency! >= 0 && s.latency! < 600).toList();

  /// 获取慢速线路 (>= 600ms)
  List<_SourceWithLatency> get _slowSources =>
      _sourcesWithLatency.where((s) => s.latency != null && s.latency! >= 600).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // 顶部海报
          _buildHeader(),
          
          // 标题和元信息
          SliverToBoxAdapter(
            child: _buildTitleSection(),
          ),
          
          // 简介
          if (_currentDetail != null && _currentDetail!.vodContent.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSynopsis(),
            ),
          
          // 线路选择
          SliverToBoxAdapter(
            child: _buildSourceSelector(),
          ),
          
          // 剧集列表
          if (_currentDetail != null && _currentDetail!.playSources.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildEpisodeGrid(),
            ),
          
          // 底部间距
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  /// 顶部播放器/海报区域
  Widget _buildHeader() {
    // 获取当前剧集名称
    String episodeName = '';
    bool hasNext = false;
    if (_currentDetail != null && _currentDetail!.playSources.isNotEmpty) {
      final episodes = _currentDetail!.playSources.first.episodes;
      if (_currentEpisodeIndex < episodes.length) {
        episodeName = episodes[_currentEpisodeIndex].name;
        hasNext = _currentEpisodeIndex < episodes.length - 1;
      }
    }
    
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // 安全区域 padding
          Container(
            color: Colors.black,
            height: MediaQuery.of(context).padding.top,
          ),
          // 播放器
          DongguaPlayer(
            key: _playerKey,
            videoUrl: _currentVideoUrl,
            title: widget.vodName,
            episodeName: episodeName,
            hasNextEpisode: hasNext,
            onNextEpisode: _playNextEpisode,
            onBack: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  /// 播放指定剧集
  void _playEpisode(int index) {
    debugPrint('🎬 _playEpisode called with index: $index');
    if (_currentDetail == null || _currentDetail!.playSources.isEmpty) {
      debugPrint('⚠️ _playEpisode: _currentDetail is null or no playSources');
      return;
    }
    
    final episodes = _currentDetail!.playSources.first.episodes;
    debugPrint('📋 Episodes count: ${episodes.length}');
    if (index >= episodes.length) {
      debugPrint('⚠️ _playEpisode: index $index >= episodes.length ${episodes.length}');
      return;
    }
    
    final episode = episodes[index];
    debugPrint('▶️ Playing episode: ${episode.name}, URL: ${episode.url}');
    setState(() {
      _currentEpisodeIndex = index;
      _currentVideoUrl = episode.url;
    });
    debugPrint('✅ _currentVideoUrl set to: $_currentVideoUrl');
  }
  
  /// 播放下一集
  void _playNextEpisode() {
    if (_currentDetail == null || _currentDetail!.playSources.isEmpty) return;
    
    final episodes = _currentDetail!.playSources.first.episodes;
    if (_currentEpisodeIndex < episodes.length - 1) {
      _playEpisode(_currentEpisodeIndex + 1);
    }
  }

  /// 标题区域
  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            widget.vodName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // 当前播放源
          if (_currentSource != null)
            Row(
              children: [
                const Text(
                  '正在播放: ',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                Text(
                  _currentSource!.source.siteName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// 简介
  Widget _buildSynopsis() {
    final content = _currentDetail!.vodContent;
    const int maxLines = 3;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '剧情简介',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              // 检测文本是否会溢出
              final textStyle = const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.7,
              );
              final textPainter = TextPainter(
                text: TextSpan(text: content, style: textStyle),
                maxLines: maxLines,
                textDirection: TextDirection.ltr,
              );
              textPainter.layout(maxWidth: constraints.maxWidth);
              final isOverflowing = textPainter.didExceedMaxLines;
              
              if (_isSynopsisExpanded) {
                // 展开状态：显示全部内容 + 行内收起按钮
                return RichText(
                  text: TextSpan(
                    style: textStyle,
                    children: [
                      TextSpan(text: content),
                      const TextSpan(text: ' '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => setState(() => _isSynopsisExpanded = false),
                          child: const Text(
                            '收起',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else if (isOverflowing) {
                // 收起状态且有溢出：显示截断文本 + 行内展开按钮
                // 计算截断后能显示多少字符
                final endPos = textPainter.getPositionForOffset(
                  Offset(constraints.maxWidth, textPainter.height - 5),
                );
                // 留出 "...展开" 的空间，大约减少8个字符
                final truncatedLength = (endPos.offset - 8).clamp(0, content.length);
                final truncatedText = content.substring(0, truncatedLength);
                
                return RichText(
                  maxLines: maxLines,
                  overflow: TextOverflow.clip,
                  text: TextSpan(
                    style: textStyle,
                    children: [
                      TextSpan(text: '$truncatedText...'),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => setState(() => _isSynopsisExpanded = true),
                          child: const Text(
                            '展开',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // 内容不溢出，直接显示
                return Text(content, style: textStyle);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 线路选择器
  Widget _buildSourceSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              const Text(
                '切换线路',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (_isTestingSources) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 4),
                Text(
                  '正在测速...',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withAlpha(180)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          
          // 测速类型图例
          if (!_isTestingSources && (_fastSources.isNotEmpty || _slowSources.isNotEmpty))
            _buildLegend(),
          
          // 快速线路
          if (_fastSources.isNotEmpty || _slowSources.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._fastSources.map((s) => _buildSourcePill(s)),
              ],
            ),
            // 慢速线路分隔
            if (_slowSources.isNotEmpty && _fastSources.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.borderColor)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_bottom, size: 14, color: AppTheme.textSecondary.withAlpha(150)),
                    const SizedBox(width: 4),
                    Text(
                      '较慢线路 (${_slowSources.length})',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withAlpha(150)),
                    ),
                  ],
                ),
              ),
            ],
            // 慢速线路
            if (_slowSources.isNotEmpty)
              Opacity(
                opacity: 0.7,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _slowSources.map((s) => _buildSourcePill(s)).toList(),
                ),
              ),
          ],
          
          // 正在测速中
          if (_isTestingSources && _fastSources.isEmpty && _slowSources.isEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sourcesWithLatency.map((s) => _buildSourcePill(s)).toList(),
            ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 测速类型图例
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _buildLegendItem('直连', const Color(0xFF10B981), const Color(0xFF059669)),
          const SizedBox(width: 16),
          _buildLegendItem('中转', const Color(0xFFF59E0B), const Color(0xFFD97706)),
          const SizedBox(width: 16),
          _buildLegendItem('服务', const Color(0xFF6366F1), const Color(0xFF4F46E5)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color1, Color color2) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color1, color2]),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(label, style: const TextStyle(fontSize: 9, color: Colors.white)),
        ),
      ],
    );
  }

  /// 源 pill
  Widget _buildSourcePill(_SourceWithLatency source) {
    final isActive = _currentSource?.source.siteKey == source.source.siteKey;
    
    return GestureDetector(
      onTap: () => _switchSource(source),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accentColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.accentColor : AppTheme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              source.source.siteName,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? Colors.white : AppTheme.textPrimary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (source.latency != null && source.latency! >= 0) ...[
              const SizedBox(width: 6),
              // 延迟点
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getLatencyColor(source.latency!),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${source.latency}ms',
                style: TextStyle(
                  fontSize: 10,
                  color: (isActive ? Colors.white : AppTheme.textSecondary).withAlpha(150),
                ),
              ),
              const SizedBox(width: 4),
              _buildTestTypeBadge(source.testType),
            ] else if (source.latency == null) ...[
              const SizedBox(width: 6),
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: isActive ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 测速类型徽章
  Widget _buildTestTypeBadge(String type) {
    Color color1, color2;
    String label;
    
    switch (type) {
      case 'direct':
        color1 = const Color(0xFF10B981);
        color2 = const Color(0xFF059669);
        label = '直连';
        break;
      case 'proxy':
        color1 = const Color(0xFFF59E0B);
        color2 = const Color(0xFFD97706);
        label = '中转';
        break;
      default:
        color1 = const Color(0xFF6366F1);
        color2 = const Color(0xFF4F46E5);
        label = '服务';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color1, color2]),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  /// 根据延迟获取颜色
  Color _getLatencyColor(int latency) {
    if (latency < 300) return const Color(0xFF22C55E); // 绿色 - 快
    if (latency < 600) return const Color(0xFFEAB308); // 黄色 - 中
    return const Color(0xFFEF4444); // 红色 - 慢
  }

  /// 剧集网格
  Widget _buildEpisodeGrid() {
    if (_isLoadingDetail) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.accentColor),
        ),
      );
    }

    if (_currentDetail == null || _currentDetail!.playSources.isEmpty) {
      return const SizedBox.shrink();
    }

    // 使用第一个播放源的剧集列表
    final episodes = _currentDetail!.playSources.first.episodes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选集播放 (${episodes.length}集)',
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
            children: List.generate(episodes.length, (index) {
              final ep = episodes[index];
              final isActive = index == _currentEpisodeIndex;
              
              return GestureDetector(
                onTap: () => _playEpisode(index),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 50),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.accentColor : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive ? AppTheme.accentColor : AppTheme.borderColor,
                    ),
                  ),
                  child: Text(
                    ep.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isActive ? Colors.white : AppTheme.textPrimary,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
