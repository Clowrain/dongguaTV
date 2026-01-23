import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

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
  
  /// 初始剧集索引（从历史恢复时使用）
  final int? initialEpisodeIndex;
  
  /// 初始播放进度（从历史恢复时使用）
  final Duration? initialPosition;
  
  /// 初始源站点（从历史恢复时使用，优先选择此源）
  final String? initialSiteKey;

  const MultiSourceDetailScreen({
    super.key,
    required this.vodName,
    required this.pic,
    required this.sources,
    this.initialEpisodeIndex,
    this.initialPosition,
    this.initialSiteKey,
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
  
  // 播放相关
  String _currentVideoUrl = '';
  final GlobalKey<DongguaPlayerState> _playerKey = GlobalKey();
  bool _hasRestoredPosition = false; // 是否已恢复播放进度
  Timer? _progressSaveTimer; // 自动保存进度定时器

  @override
  void initState() {
    super.initState();
    // 初始化源列表
    _sourcesWithLatency = widget.sources.map((s) => _SourceWithLatency(source: s)).toList();
    
    // 开始测速（自动选择最快线路会在测速完成后进行）
    _testAllSources();
    
    // 启动自动保存进度定时器（每30秒）
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _saveProgress();
    });
  }
  
  @override
  void dispose() {
    _progressSaveTimer?.cancel();
    super.dispose();
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
    
    // 如果有历史记录指定的源，优先使用
    if (widget.initialSiteKey != null) {
      final historySource = _sourcesWithLatency.firstWhere(
        (s) => s.source.siteKey == widget.initialSiteKey,
        orElse: () => _sourcesWithLatency.first,
      );
      debugPrint('🎯 [历史恢复] 使用历史记录源: ${historySource.source.siteName}');
      _hasAutoSelected = true;
      _switchSource(historySource);
      return;
    }
    
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
      _currentEpisodeIndex = 0;
      _currentVideoUrl = ''; // 清空当前URL
    });
    
    // 优先使用测速时缓存的详情
    VideoDetail? detail = source.cachedDetail;
    
    if (detail != null) {
      // 使用缓存的详情，无需等待
      if (mounted) {
        setState(() {
          _currentDetail = detail;
          _isLoadingDetail = false;
        });
        
        // 自动播放（优先使用历史记录的剧集索引）
        if (detail.playSources.isNotEmpty && detail.playSources.first.episodes.isNotEmpty) {
          final episodeCount = detail.playSources.first.episodes.length;
          // 使用历史记录的索引，超出范围则回退到第一集
          final targetIndex = (widget.initialEpisodeIndex != null && 
                               widget.initialEpisodeIndex! < episodeCount)
              ? widget.initialEpisodeIndex!
              : 0;
          debugPrint('🎯 Using cached detail, auto-playing episode $targetIndex');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _playEpisode(targetIndex);
            }
          });
        }
      }
    } else {
      // 没有缓存，需要请求API
      setState(() => _isLoadingDetail = true);
      
      try {
        detail = await ApiService().getDetail(
          source.source.vodId,
          source.source.siteKey,
        );
        if (mounted) {
          setState(() {
            _currentDetail = detail;
            _isLoadingDetail = false;
          });
          
          // 自动播放（优先使用历史记录的剧集索引）
          if (detail != null && detail.playSources.isNotEmpty && detail.playSources.first.episodes.isNotEmpty) {
            final episodeCount = detail.playSources.first.episodes.length;
            final targetIndex = (widget.initialEpisodeIndex != null && 
                                 widget.initialEpisodeIndex! < episodeCount)
                ? widget.initialEpisodeIndex!
                : 0;
            debugPrint('🎯 Detail loaded, auto-playing episode $targetIndex');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _playEpisode(targetIndex);
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
  }

  /// 获取快速线路 (< 600ms)
  List<_SourceWithLatency> get _fastSources =>
      _sourcesWithLatency.where((s) => s.latency != null && s.latency! >= 0 && s.latency! < 600).toList();

  /// 获取慢速线路 (>= 600ms)
  List<_SourceWithLatency> get _slowSources =>
      _sourcesWithLatency.where((s) => s.latency != null && s.latency! >= 600).toList();

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 计算播放器高度（16:9）但不超过可用高度的60%
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          
          // 判断是否为移动端全屏模式（横屏且高度较小）
          // 桌面端即使宽屏也应显示下方内容
          final isMobileFullscreen = screenWidth > screenHeight && screenHeight < 500;
          
          // 移动端全屏时播放器占满，否则限制高度
          final maxPlayerHeight = isMobileFullscreen 
              ? screenHeight - statusBarHeight  // 全屏模式占满
              : (screenHeight - statusBarHeight) * 0.4;  // 正常模式最多40%
          final playerHeight16x9 = screenWidth * 9 / 16;
          final playerHeight = playerHeight16x9.clamp(0.0, maxPlayerHeight);
          
          return Column(
            children: [
              // 状态栏填充
              Container(
                color: Colors.black,
                height: statusBarHeight,
              ),
              
              // 播放器固定在顶部 - 高度受限
              SizedBox(
                height: playerHeight,
                child: _buildPlayer(),
              ),
              
              // 下方内容可滚动（只在移动端全屏时隐藏）
              if (!isMobileFullscreen)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 标题和元信息
                        _buildTitleSection(),
                        
                        // 线路选择
                        _buildSourceSelector(),
                        
                        const SizedBox(height: 12),
                        
                        // 剧集列表
                        if (_currentDetail != null && _currentDetail!.playSources.isNotEmpty)
                          _buildEpisodeGrid(),
                        
                        const SizedBox(height: 16),
                        
                        // 简介（放在最后）
                        if (_currentDetail != null && _currentDetail!.vodContent.isNotEmpty)
                          _buildSynopsis(),
                        
                        // 底部间距
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  
  /// 播放器组件（固定在顶部）
  Widget _buildPlayer() {
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

    return DongguaPlayer(
      key: _playerKey,
      videoUrl: _currentVideoUrl,
      title: widget.vodName,
      episodeName: episodeName,
      hasNextEpisode: hasNext,
      onNextEpisode: _playNextEpisode,
      onBack: () => Navigator.of(context).pop(),
      onPlayerReady: _onPlayerReady, // 播放器初始化完成的回调
    );
  }
  
  /// 播放器初始化完成的回调
  void _onPlayerReady() {
    debugPrint('🎥 收到播放器初始化完成通知');

    // 如果需要恢复播放进度，现在执行
    if (!_hasRestoredPosition && widget.initialPosition != null && widget.initialPosition!.inSeconds > 0) {
      _hasRestoredPosition = true;
      final player = _playerKey.currentState;
      if (player != null) {
        debugPrint('⏩ 恢复播放进度: ${widget.initialPosition}');
        player.seekTo(widget.initialPosition!);
      }
    }
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

    // 保存观看历史
    _saveWatchHistory(episode.name);
  }
  
  /// 播放下一集
  void _playNextEpisode() {
    if (_currentDetail == null || _currentDetail!.playSources.isEmpty) return;

    final episodes = _currentDetail!.playSources.first.episodes;
    if (_currentEpisodeIndex < episodes.length - 1) {
      _playEpisode(_currentEpisodeIndex + 1);
    }
  }
  
  /// 保存观看历史
  void _saveWatchHistory(String episodeName) {
    if (_currentSource == null || _currentDetail == null) return;
    
    final historyService = context.read<WatchHistoryService>();
    final history = WatchHistory(
      id: '${_currentSource!.source.siteKey}_${_currentSource!.source.vodId}',
      vodId: _currentSource!.source.vodId,
      vodName: widget.vodName,
      vodPic: widget.pic,
      typeName: _currentDetail!.typeName,
      siteKey: _currentSource!.source.siteKey,
      siteName: _currentSource!.source.siteName,
      sourceIndex: 0,
      episodeIndex: _currentEpisodeIndex,
      episodeName: episodeName,
      progress: 0,
      duration: 0,
      updatedAt: DateTime.now(),
      sources: widget.sources,
    );
    
    historyService.save(history);
    debugPrint('📝 Saved watch history: ${widget.vodName} - $episodeName');
  }
  
  /// 保存当前播放进度
  void _saveProgress() {
    if (_currentSource == null) return;
    
    final player = _playerKey.currentState;
    if (player == null) return;
    
    final position = player.currentPosition;
    final duration = player.duration;
    
    // 只有在有进度时才保存
    if (position.inSeconds <= 0 || duration.inSeconds <= 0) return;
    
    final historyId = '${_currentSource!.source.siteKey}_${_currentSource!.source.vodId}';
    final historyService = context.read<WatchHistoryService>();
    
    historyService.updateProgress(
      historyId,
      position.inSeconds,
      duration.inSeconds,
    );
    debugPrint('💾 Auto-saved progress: ${position.inSeconds}s / ${duration.inSeconds}s');
  }

  /// 标题区域 - B站风格
  Widget _buildTitleSection() {
    // 获取视频详情元数据
    final year = _currentDetail?.vodYear ?? '';
    final area = _currentDetail?.vodArea ?? '';
    final typeName = _currentDetail?.typeName ?? '';
    final score = _currentDetail?.vodScore ?? '';
    
    // 构建元数据标签列表
    final metaTags = <String>[];
    if (year.isNotEmpty && year != '0') metaTags.add(year);
    if (area.isNotEmpty) metaTags.add(area);
    if (typeName.isNotEmpty) metaTags.add(typeName);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行: 标题 + 操作按钮
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Expanded(
                child: Text(
                  widget.vodName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              // 收藏按钮（布局占位）
              _buildActionButton(Icons.favorite_border, '收藏', () {
                // TODO: 实现收藏功能
              }),
              const SizedBox(width: 8),
              // 下载按钮（布局占位）
              _buildActionButton(Icons.download_outlined, '下载', () {
                // TODO: 实现下载功能
              }),
            ],
          ),
          const SizedBox(height: 8),
          // 第二行: 元数据 + 评分
          Row(
            children: [
              // 元数据标签
              if (metaTags.isNotEmpty)
                Expanded(
                  child: Text(
                    metaTags.join(' · '),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // 评分
              if (score.isNotEmpty && score != '0' && score != '0.0')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA726).withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFFFA726)),
                      const SizedBox(width: 2),
                      Text(
                        score,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFA726),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 操作按钮
  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: AppTheme.textSecondary),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSynopsis() {
    final content = _currentDetail!.vodContent;
    final director = _currentDetail!.vodDirector;
    final actor = _currentDetail!.vodActor;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '剧情简介',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // 简介内容
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          // 导演信息
          if (director.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('导演', director),
          ],
          // 演员信息
          if (actor.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow('主演', actor),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  /// 信息行
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary.withAlpha(180),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 线路选择器 - Tab 风格
  Widget _buildSourceSelector() {
    // 合并快速和慢速线路，按延迟排序
    final allSources = <_SourceWithLatency>[
      ..._fastSources,
      ..._slowSources,
    ];
    
    // 如果还在测速，显示所有源
    final sourcesToShow = allSources.isEmpty ? _sourcesWithLatency : allSources;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 线路 Tab 行
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sourcesToShow.length + (_isTestingSources ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              // 显示测速指示器
              if (_isTestingSources && index == sourcesToShow.length) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      Text('测速中...', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                );
              }
              
              final source = sourcesToShow[index];
              return _buildSourceTab(source);
            },
          ),
        ),
      ],
    );
  }
  
  /// 单个线路 Tab
  Widget _buildSourceTab(_SourceWithLatency source) {
    final isActive = _currentSource?.source.siteKey == source.source.siteKey;
    final latency = source.latency;
    final hasLatency = latency != null && latency >= 0 && latency < 9999;
    
    return GestureDetector(
      onTap: () => _switchSource(source),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accentColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.accentColor : AppTheme.borderColor,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 选中标记
            if (isActive)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.check, size: 14, color: Colors.white),
              ),
            // 线路名称
            Text(
              source.source.siteName,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? Colors.white : AppTheme.textPrimary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            // 延迟
            if (hasLatency) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive 
                      ? Colors.white.withAlpha(50)
                      : _getLatencyColor(latency).withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${latency}ms',
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? Colors.white : _getLatencyColor(latency),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 根据延迟获取颜色
  Color _getLatencyColor(int latency) {
    if (latency < 300) return const Color(0xFF22C55E); // 绿色 - 快
    if (latency < 600) return const Color(0xFFEAB308); // 黄色 - 中
    return const Color(0xFFEF4444); // 红色 - 慢
  }

  /// 剧集横向滚动 - B站风格
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
              Text(
                '选集',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${episodes.length}集)',
                style: TextStyle(
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
              final isActive = index == _currentEpisodeIndex;
              
              return GestureDetector(
                onTap: () => _playEpisode(index),
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
