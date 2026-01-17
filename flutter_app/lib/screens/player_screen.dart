import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../config/theme.dart';
import '../models/models.dart';

/// 播放器页面
class PlayerScreen extends StatefulWidget {
  final String vodName;
  final String siteKey;
  final String vodId;
  final String episodeName;
  final String episodeUrl;
  final List<PlaySource> playSources;
  final int initialSourceIndex;

  const PlayerScreen({
    super.key,
    required this.vodName,
    required this.siteKey,
    required this.vodId,
    required this.episodeName,
    required this.episodeUrl,
    required this.playSources,
    this.initialSourceIndex = 0,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  
  int _currentSourceIndex = 0;
  int _currentEpisodeIndex = 0;
  String _currentUrl = '';
  bool _isLoading = true;
  String? _error;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentSourceIndex = widget.initialSourceIndex;
    _currentUrl = widget.episodeUrl;
    
    // 初始化播放器
    _player = Player();
    _controller = VideoController(_player);
    
    // 找到当前剧集索引
    _findCurrentEpisodeIndex();
    
    // 开始播放
    _parseAndPlay(widget.episodeUrl);
    
    // 全屏横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _player.dispose();
    // 恢复竖屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _findCurrentEpisodeIndex() {
    if (_currentSourceIndex >= widget.playSources.length) return;
    final episodes = widget.playSources[_currentSourceIndex].episodes;
    for (int i = 0; i < episodes.length; i++) {
      if (episodes[i].url == _currentUrl) {
        _currentEpisodeIndex = i;
        break;
      }
    }
  }

  /// 播放 URL（直接使用剧集 URL，通常是 m3u8）
  Future<void> _parseAndPlay(String url) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentUrl = url;
    });

    try {
      // 直接播放 URL（m3u8 或其他格式）
      await _player.open(Media(url));
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = '播放失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 切换线路
  void _switchSource(int index) {
    if (index == _currentSourceIndex) return;
    setState(() {
      _currentSourceIndex = index;
      _currentEpisodeIndex = 0;
    });
    // 播放新线路的第一集
    final episodes = widget.playSources[index].episodes;
    if (episodes.isNotEmpty) {
      _parseAndPlay(episodes[0].url);
    }
  }

  /// 切换剧集
  void _playEpisode(int index, String url) {
    if (url == _currentUrl) return;
    setState(() => _currentEpisodeIndex = index);
    _parseAndPlay(url);
  }

  /// 播放上一集
  void _playPrevious() {
    if (_currentEpisodeIndex > 0) {
      final episodes = widget.playSources[_currentSourceIndex].episodes;
      _playEpisode(_currentEpisodeIndex - 1, episodes[_currentEpisodeIndex - 1].url);
    }
  }

  /// 播放下一集
  void _playNext() {
    final episodes = widget.playSources[_currentSourceIndex].episodes;
    if (_currentEpisodeIndex < episodes.length - 1) {
      _playEpisode(_currentEpisodeIndex + 1, episodes[_currentEpisodeIndex + 1].url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            // 视频播放器
            Center(
              child: Video(
                controller: _controller,
                controls: NoVideoControls,
              ),
            ),
            
            // 加载中
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor),
              ),
            
            // 错误提示
            if (_error != null)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _parseAndPlay(_currentUrl),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            
            // 顶部控制栏
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(),
              ),
            
            // 底部控制栏
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(),
              ),
          ],
        ),
      ),
    );
  }

  /// 顶部控制栏
  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha(200),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          // 标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.vodName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.playSources[_currentSourceIndex].name} · ${_getCurrentEpisodeName()}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentEpisodeName() {
    if (_currentSourceIndex >= widget.playSources.length) return '';
    final episodes = widget.playSources[_currentSourceIndex].episodes;
    if (_currentEpisodeIndex >= episodes.length) return '';
    return episodes[_currentEpisodeIndex].name;
  }

  /// 底部控制栏
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withAlpha(200),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 线路选择
          _buildSourceSelector(),
          const SizedBox(height: 12),
          // 剧集选择
          _buildEpisodeSelector(),
        ],
      ),
    );
  }

  /// 线路选择器
  Widget _buildSourceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '切换线路',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(widget.playSources.length, (index) {
              final source = widget.playSources[index];
              final isSelected = index == _currentSourceIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _switchSource(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accentColor : Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected 
                          ? null 
                          : Border.all(color: Colors.white.withAlpha(50)),
                    ),
                    child: Text(
                      source.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// 剧集选择器
  Widget _buildEpisodeSelector() {
    if (_currentSourceIndex >= widget.playSources.length) {
      return const SizedBox.shrink();
    }
    
    final episodes = widget.playSources[_currentSourceIndex].episodes;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '选集 (${episodes.length}集)',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const Spacer(),
            // 上一集
            IconButton(
              icon: const Icon(Icons.skip_previous, color: Colors.white70),
              onPressed: _currentEpisodeIndex > 0 ? _playPrevious : null,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            // 下一集
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white70),
              onPressed: _currentEpisodeIndex < episodes.length - 1 ? _playNext : null,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: episodes.length,
            itemBuilder: (context, index) {
              final ep = episodes[index];
              final isSelected = index == _currentEpisodeIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _playEpisode(index, ep.url),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accentColor : Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                      border: isSelected 
                          ? null 
                          : Border.all(color: Colors.white.withAlpha(40)),
                    ),
                    child: Text(
                      ep.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
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
