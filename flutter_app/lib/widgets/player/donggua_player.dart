import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../utils/platform_utils.dart';
import 'player.dart';

/// 东瓜TV 视频播放器组件
/// 
/// 基于 FlickVideoPlayer，提供简化的 API 供视频详情页使用
class DongguaPlayer extends StatefulWidget {
  /// 视频 URL
  final String videoUrl;
  
  /// 视频标题
  final String title;
  
  /// 当前剧集名
  final String episodeName;
  
  /// 是否有下一集
  final bool hasNextEpisode;
  
  /// 下一集回调
  final VoidCallback? onNextEpisode;
  
  /// 返回回调
  final VoidCallback? onBack;
  
  /// 更多选项回调
  final VoidCallback? onMoreOptions;
  
  /// 视频结束回调
  final VoidCallback? onVideoEnd;
  
  /// 手势开始时回调（父级应禁用滚动）
  final VoidCallback? onGestureStart;
  
  /// 手势结束时回调（父级应恢复滚动）
  final VoidCallback? onGestureEnd;

  /// 播放器初始化完成回调（可用于恢复播放进度）
  final VoidCallback? onPlayerReady;

  const DongguaPlayer({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.episodeName,
    this.hasNextEpisode = false,
    this.onNextEpisode,
    this.onBack,
    this.onMoreOptions,
    this.onVideoEnd,
    this.onGestureStart,
    this.onGestureEnd,
    this.onPlayerReady,
  });

  @override
  State<DongguaPlayer> createState() => DongguaPlayerState();
}

class DongguaPlayerState extends State<DongguaPlayer> {
  FlickManager? _flickManager;
  bool _hasNotifiedReady = false; // 防止重复通知

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(DongguaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoUrl != oldWidget.videoUrl && widget.videoUrl.isNotEmpty) {
      _hasNotifiedReady = false; // 重置标志
      _changeVideo(widget.videoUrl);
    }
  }

  @override
  void dispose() {
    _flickManager?.dispose();
    super.dispose();
  }

  void _initPlayer() {
    if (widget.videoUrl.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    // 监听初始化完成事件
    controller.addListener(() {
      if (!_hasNotifiedReady &&
          controller.value.isInitialized &&
          widget.onPlayerReady != null) {
        _hasNotifiedReady = true;
        debugPrint('🎥 播放器初始化完成，触发 onPlayerReady 回调');
        widget.onPlayerReady!();
      }
    });

    _flickManager = FlickManager(
      videoPlayerController: controller,
      autoPlay: true,
      onVideoEnd: widget.onVideoEnd,
    );

    if (mounted) setState(() {});
  }

  void _changeVideo(String url) {
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));

    // 监听初始化完成事件
    controller.addListener(() {
      if (!_hasNotifiedReady &&
          controller.value.isInitialized &&
          widget.onPlayerReady != null) {
        _hasNotifiedReady = true;
        debugPrint('🎥 播放器初始化完成，触发 onPlayerReady 回调');
        widget.onPlayerReady!();
      }
    });

    if (_flickManager == null) {
      _flickManager = FlickManager(
        videoPlayerController: controller,
        autoPlay: true,
        onVideoEnd: widget.onVideoEnd,
      );
    } else {
      _flickManager!.handleChangeVideo(controller);
    }

    if (mounted) setState(() {});
  }

  // ========== 公开方法 ==========
  
  void play() => _flickManager?.flickControlManager?.play();
  void pause() => _flickManager?.flickControlManager?.pause();
  void togglePlayPause() => _flickManager?.flickControlManager?.togglePlay();
  void seekTo(Duration position) => _flickManager?.flickControlManager?.seekTo(position);
  void setPlaybackSpeed(double speed) => _flickManager?.flickControlManager?.setPlaybackSpeed(speed);
  void setVolume(double volume) => _flickManager?.flickControlManager?.setVolume(volume);
  
  /// 获取当前播放位置
  Duration get currentPosition => 
      _flickManager?.flickVideoManager?.videoPlayerValue?.position ?? Duration.zero;
  
  /// 获取视频总时长
  Duration get duration => 
      _flickManager?.flickVideoManager?.videoPlayerValue?.duration ?? Duration.zero;
  
  /// 是否正在播放
  bool get isPlaying => 
      _flickManager?.flickVideoManager?.videoPlayerValue?.isPlaying ?? false;

  @override
  Widget build(BuildContext context) {
    // 无视频 URL 时显示占位
    if (widget.videoUrl.isEmpty || _flickManager == null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // 使用屏幕宽度计算 16:9 高度
          final width = constraints.maxWidth;
          final height = width * 9 / 16;
          
          return Container(
            width: width,
            height: height,
            color: Colors.black,
            child: Stack(
              children: [
                // 中间提示文字
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_outline, color: Colors.white38, size: 48),
                      SizedBox(height: 8),
                      Text(
                        '请选择剧集开始播放',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // 顶部栏 - 返回按钮
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(150),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        if (widget.onBack != null)
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: widget.onBack,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 使用视频实际比例或默认 16:9
        final videoValue = _flickManager?.flickVideoManager?.videoPlayerValue;
        final aspectRatio = (videoValue?.isInitialized == true) 
            ? videoValue!.aspectRatio 
            : 16 / 9;
        
        // 根据可用宽度计算高度
        final width = constraints.maxWidth;
        final height = width / aspectRatio;
        
        return SizedBox(
          width: width,
          height: height,
          child: FlickVideoPlayer(
            flickManager: _flickManager!,
            onBack: widget.onBack,
            topBarRightWidget: widget.onMoreOptions != null
              ? IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: widget.onMoreOptions,
                )
              : null,
            flickVideoWithControls: FlickVideoWithControls(
              videoFit: BoxFit.contain, // 保持视频原始比例，不裁剪
              controls: DongguaPortraitControls(
                title: widget.title,
                episodeName: widget.episodeName,
                progressBarSettings: FlickProgressBarSettings(
                  height: 4,
                ),
                onGestureStart: widget.onGestureStart,
                onGestureEnd: widget.onGestureEnd,
              ),
            ),
            flickVideoWithControlsFullscreen: FlickVideoWithControls(
              videoFit: BoxFit.contain, // 全屏也保持原始比例
              controls: PlatformUtils.isAndroidTV
                  ? DongguaTvControls(
                      title: widget.title,
                      episodeName: widget.episodeName,
                      onBack: widget.onBack,
                      hasNextEpisode: widget.hasNextEpisode,
                      onNextEpisode: widget.onNextEpisode,
                    )
                  : DongguaLandscapeControls(
                      title: widget.title,
                      episodeName: widget.episodeName,
                      onGestureStart: widget.onGestureStart,
                      onGestureEnd: widget.onGestureEnd,
                    ),
            ),
          ),
        );
      },
    );
  }
}
