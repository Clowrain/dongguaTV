import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../utils/platform_utils.dart';
import '../../tv/tv_focusable.dart';
import '../manager/flick_manager.dart';
import '../widgets/flick_play_toggle.dart';
import '../widgets/flick_sound_toggle.dart';
import '../widgets/flick_video_progress_bar.dart';
import '../widgets/flick_current_position.dart';
import '../widgets/flick_total_duration.dart';
import '../widgets/helpers/progress_bar/progress_bar_settings.dart';

/// TV 专用的横屏播放器控制条
///
/// 针对 Android TV 的遥控器操作优化
class DongguaTvControls extends StatefulWidget {
  final String title;
  final String episodeName;
  final VoidCallback? onBack;
  final VoidCallback? onNextEpisode;
  final bool hasNextEpisode;

  const DongguaTvControls({
    super.key,
    required this.title,
    required this.episodeName,
    this.onBack,
    this.onNextEpisode,
    this.hasNextEpisode = false,
  });

  @override
  State<DongguaTvControls> createState() => _DongguaTvControlsState();
}

class _DongguaTvControlsState extends State<DongguaTvControls> {
  bool _showControls = true;
  final FocusNode _playButtonFocus = FocusNode();
  final FocusNode _soundButtonFocus = FocusNode();
  final FocusNode _backButtonFocus = FocusNode();
  final FocusNode _nextButtonFocus = FocusNode();

  @override
  void dispose() {
    _playButtonFocus.dispose();
    _soundButtonFocus.dispose();
    _backButtonFocus.dispose();
    _nextButtonFocus.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final flickManager = context.read<FlickManager>();

      // 播放/暂停
      if (event.logicalKey == LogicalKeyboardKey.mediaPlayPause ||
          event.logicalKey == LogicalKeyboardKey.space) {
        flickManager.flickControlManager?.togglePlay();
        _toggleControls();
        return KeyEventResult.handled;
      }

      // 快进 10 秒
      if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.mediaFastForward) {
        final currentPos = flickManager.flickVideoManager?.videoPlayerValue?.position ?? Duration.zero;
        flickManager.flickControlManager?.seekTo(currentPos + const Duration(seconds: 10));
        _toggleControls();
        return KeyEventResult.handled;
      }

      // 快退 10 秒
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.mediaRewind) {
        final currentPos = flickManager.flickVideoManager?.videoPlayerValue?.position ?? Duration.zero;
        flickManager.flickControlManager?.seekTo(currentPos - const Duration(seconds: 10));
        _toggleControls();
        return KeyEventResult.handled;
      }

      // 显示/隐藏控制条
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        _toggleControls();
        return KeyEventResult.handled;
      }

      // 返回
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.goBack) {
        widget.onBack?.call();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: _toggleControls,
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              // 视频内容区域
              const Center(child: SizedBox.shrink()),

              // 控制条
              if (_showControls) ...[
                // 顶部栏
                _buildTopBar(),

                // 中间播放按钮
                _buildCenterPlayButton(),

                // 底部控制栏
                _buildBottomBar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final scale = PlatformUtils.recommendedSpacingScale;
    final fontScale = PlatformUtils.recommendedFontScale;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        padding: EdgeInsets.all(16 * scale),
        child: Row(
          children: [
            // 返回按钮
            TvFocusable(
              focusNode: _backButtonFocus,
              autofocus: true,
              onTap: widget.onBack,
              child: Container(
                padding: EdgeInsets.all(8 * scale),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28 * scale,
                ),
              ),
            ),
            SizedBox(width: 16 * scale),

            // 标题信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18 * fontScale,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.episodeName.isNotEmpty) ...[
                    SizedBox(height: 4 * scale),
                    Text(
                      widget.episodeName,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14 * fontScale,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPlayButton() {
    final scale = PlatformUtils.recommendedSpacingScale;

    return Center(
      child: TvFocusable(
        focusNode: _playButtonFocus,
        onTap: () {
          final flickManager = context.read<FlickManager>();
          flickManager.flickControlManager?.togglePlay();
        },
        child: Container(
          padding: EdgeInsets.all(20 * scale),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: FlickPlayToggle(
            size: 60 * scale,
            color: Colors.white,
            padding: EdgeInsets.zero,
            decoration: const BoxDecoration(),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final scale = PlatformUtils.recommendedSpacingScale;
    final fontScale = PlatformUtils.recommendedFontScale;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        padding: EdgeInsets.all(16 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 进度条
            FlickVideoProgressBar(
              flickProgressBarSettings: FlickProgressBarSettings(
                height: 6 * scale,
                handleRadius: 8 * scale,
                padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                playedColor: Theme.of(context).colorScheme.primary,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white12,
                handleColor: Colors.white,
              ),
            ),
            SizedBox(height: 12 * scale),

            // 控制按钮行
            Row(
              children: [
                // 播放/暂停
                TvFocusable(
                  focusNode: _playButtonFocus,
                  onTap: () {
                    final flickManager = context.read<FlickManager>();
                    flickManager.flickControlManager?.togglePlay();
                  },
                  child: Padding(
                    padding: EdgeInsets.all(8 * scale),
                    child: FlickPlayToggle(
                      size: 32 * scale,
                      color: Colors.white,
                      padding: EdgeInsets.zero,
                      decoration: const BoxDecoration(),
                    ),
                  ),
                ),
                SizedBox(width: 16 * scale),

                // 音量
                TvFocusable(
                  focusNode: _soundButtonFocus,
                  onTap: () {
                    final flickManager = context.read<FlickManager>();
                    flickManager.flickControlManager?.toggleMute();
                  },
                  child: Padding(
                    padding: EdgeInsets.all(8 * scale),
                    child: FlickSoundToggle(
                      size: 28 * scale,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 16 * scale),

                // 时间显示
                FlickCurrentPosition(
                  fontSize: 14 * fontScale,
                  color: Colors.white,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4 * scale),
                  child: Text(
                    '/',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14 * fontScale,
                    ),
                  ),
                ),
                FlickTotalDuration(
                  fontSize: 14 * fontScale,
                  color: Colors.white,
                ),

                const Spacer(),

                // 下一集按钮
                if (widget.hasNextEpisode)
                  TvFocusable(
                    focusNode: _nextButtonFocus,
                    onTap: widget.onNextEpisode,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * scale,
                        vertical: 8 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4 * scale),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '下一集',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14 * fontScale,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4 * scale),
                          Icon(
                            Icons.skip_next,
                            color: Colors.white,
                            size: 20 * scale,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
