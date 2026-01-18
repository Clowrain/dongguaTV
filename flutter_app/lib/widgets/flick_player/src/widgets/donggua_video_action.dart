import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../../flick_video_player.dart';

/// 东瓜视频手势控制组件
/// 
/// 整合所有手势到一个组件中：
/// - onTap: 显示/隐藏控制层
/// - onDoubleTap: 左半快退，右半快进（带视觉反馈）
/// - onVerticalDrag: 左半亮度，右半音量
/// - onHorizontalDrag: 进度调节
/// 
/// 通过 onGestureStart/onGestureEnd 回调通知父级禁用滚动
class DongguaVideoAction extends StatefulWidget {
  const DongguaVideoAction({
    super.key,
    this.child,
    this.seekDuration = const Duration(seconds: 10),
    this.onGestureStart,
    this.onGestureEnd,
  });

  final Widget? child;
  final Duration seekDuration;
  
  /// 手势开始时回调，父级应禁用滚动
  final VoidCallback? onGestureStart;
  
  /// 手势结束时回调，父级应恢复滚动
  final VoidCallback? onGestureEnd;

  @override
  State<DongguaVideoAction> createState() => _DongguaVideoActionState();
}

class _DongguaVideoActionState extends State<DongguaVideoAction> {
  // 拖动状态
  bool _isDragging = false;
  String? _dragDirection;
  String _adjustType = '';
  Offset _dragStart = Offset.zero;
  double _currentValue = 0;
  double _displayValue = 0;
  
  // 进度调节
  Duration _seekStartPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  Duration _seekPosition = Duration.zero;
  
  // 指示器
  bool _showIndicator = false;
  
  // 双击快进/快退/播放暂停反馈
  bool _showSeekFeedback = false;
  String _doubleTapAction = ''; // 'forward', 'backward', 'toggle'
  
  // 屏幕尺寸
  double _screenWidth = 0;
  double _screenHeight = 0;
  
  // 点击检测
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  static const _doubleTapMaxDuration = Duration(milliseconds: 300);
  static const _doubleTapMaxDistance = 50.0;
  static const _dragThreshold = 15.0;

  Future<void> _initBrightness() async {
    if (kIsWeb) {
      _currentValue = 0.5;
      return;
    }
    try {
      _currentValue = await ScreenBrightness.instance.application;
    } catch (e) {
      _currentValue = 0.5;
    }
  }

  Future<void> _setBrightness(double value) async {
    if (kIsWeb) return;
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(value);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _resetBrightness() async {
    if (kIsWeb) return;
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _resetBrightness();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _dragStart = event.localPosition;
    _dragDirection = null;
    _isDragging = false;
    
    final videoManager = Provider.of<FlickVideoManager>(context, listen: false);
    
    // 预设调节类型
    if (event.localPosition.dx < _screenWidth / 2) {
      _adjustType = 'brightness';
      _initBrightness();
    } else {
      _adjustType = 'volume';
      _currentValue = videoManager.videoPlayerValue?.volume ?? 1.0;
    }
    _displayValue = _currentValue;
    
    // 获取播放位置
    _seekStartPosition = videoManager.videoPlayerValue?.position ?? Duration.zero;
    _videoDuration = videoManager.videoPlayerValue?.duration ?? Duration.zero;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final deltaX = event.localPosition.dx - _dragStart.dx;
    final deltaY = _dragStart.dy - event.localPosition.dy;
    final distance = (event.localPosition - _dragStart).distance;
    
    // 确定方向（第一次超过阈值时）
    if (_dragDirection == null && distance > _dragThreshold) {
      _isDragging = true;
      _dragDirection = deltaX.abs() > deltaY.abs() ? 'horizontal' : 'vertical';
      if (_dragDirection == 'horizontal') {
        _adjustType = 'seek';
      }
      // 通知父级禁用滚动
      widget.onGestureStart?.call();
    }
    
    if (!_isDragging) return;
    
    if (_dragDirection == 'horizontal') {
      // 进度调节
      if (_videoDuration.inMilliseconds > 0) {
        final seekRatio = deltaX / _screenWidth * 0.5;
        final seekDelta = Duration(
          milliseconds: (_videoDuration.inMilliseconds * seekRatio).toInt()
        );
        _seekPosition = (_seekStartPosition + seekDelta);
        if (_seekPosition < Duration.zero) _seekPosition = Duration.zero;
        if (_seekPosition > _videoDuration) _seekPosition = _videoDuration;
        _displayValue = _seekPosition.inMilliseconds / _videoDuration.inMilliseconds;
        
        setState(() => _showIndicator = true);
      }
    } else if (_dragDirection == 'vertical') {
      // 音量/亮度调节
      const sensitivity = 1.5;
      final delta = (deltaY / _screenHeight) * sensitivity;
      _displayValue = (_currentValue + delta).clamp(0.0, 1.0);
      
      setState(() => _showIndicator = true);
      
      final controlManager = Provider.of<FlickControlManager>(context, listen: false);
      if (_adjustType == 'volume') {
        controlManager.setVolume(_displayValue);
      } else if (_adjustType == 'brightness') {
        _setBrightness(_displayValue);
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_isDragging) {
      // 通知父级恢复滚动
      widget.onGestureEnd?.call();
      
      // 拖动结束
      if (_dragDirection == 'horizontal' && _adjustType == 'seek') {
        if (_videoDuration.inMilliseconds > 0) {
          final controlManager = Provider.of<FlickControlManager>(context, listen: false);
          controlManager.seekTo(_seekPosition);
        }
      }
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _showIndicator = false);
        }
      });
    } else {
      // 检测点击/双击
      final now = DateTime.now();
      final tapPosition = event.localPosition;
      
      if (_lastTapTime != null && 
          _lastTapPosition != null &&
          now.difference(_lastTapTime!) < _doubleTapMaxDuration &&
          (tapPosition - _lastTapPosition!).distance < _doubleTapMaxDistance) {
        // 双击
        _handleDoubleTap(tapPosition);
        _lastTapTime = null;
        _lastTapPosition = null;
      } else {
        // 可能是单击，等待双击超时
        _lastTapTime = now;
        _lastTapPosition = tapPosition;
        
        Future.delayed(_doubleTapMaxDuration, () {
          if (_lastTapTime == now) {
            // 确认是单击
            _handleSingleTap();
            _lastTapTime = null;
            _lastTapPosition = null;
          }
        });
      }
    }
    
    _isDragging = false;
    _dragDirection = null;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_isDragging) {
      widget.onGestureEnd?.call();
    }
    _isDragging = false;
    _dragDirection = null;
  }

  void _handleSingleTap() {
    final displayManager = Provider.of<FlickDisplayManager>(context, listen: false);
    displayManager.handleVideoTap();
  }

  void _handleDoubleTap(Offset position) {
    final controlManager = Provider.of<FlickControlManager>(context, listen: false);
    
    // 屏幕分为三区: 左40% | 中20% | 右40%
    final leftZone = _screenWidth * 0.4;
    final rightZone = _screenWidth * 0.6;
    
    if (position.dx < leftZone) {
      // 左侧 - 快退
      controlManager.seekBackward(widget.seekDuration);
      _showDoubleTapFeedback('backward');
    } else if (position.dx > rightZone) {
      // 右侧 - 快进
      controlManager.seekForward(widget.seekDuration);
      _showDoubleTapFeedback('forward');
    } else {
      // 中间 - 播放/暂停切换（无需反馈）
      controlManager.togglePlay();
    }
  }
  
  void _showDoubleTapFeedback(String action) {
    setState(() {
      _doubleTapAction = action;
      _showSeekFeedback = true;
    });
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showSeekFeedback = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _screenWidth = constraints.maxWidth;
        _screenHeight = constraints.maxHeight;

        return Stack(
          children: [
            // 使用 Listener 直接处理指针事件
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _handlePointerDown,
                onPointerMove: _handlePointerMove,
                onPointerUp: _handlePointerUp,
                onPointerCancel: _handlePointerCancel,
                child: widget.child ?? const SizedBox.expand(),
              ),
            ),
            
            // 双击快进/快退反馈
            if (_showSeekFeedback)
              Positioned(
                left: _doubleTapAction == 'backward' ? 40 : null,
                right: _doubleTapAction == 'forward' ? 40 : null,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildSeekFeedback(),
                ),
              ),
            
            // 调节指示器
            if (_showIndicator)
              IgnorePointer(
                child: Center(child: _buildIndicator()),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSeekFeedback() {
    final seconds = widget.seekDuration.inSeconds;
    final isForward = _doubleTapAction == 'forward';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isForward ? Icons.fast_forward : Icons.fast_rewind,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            '${isForward ? '+' : '-'}${seconds}s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    if (_adjustType == 'seek') {
      return _buildSeekIndicator();
    }
    
    final icon = _adjustType == 'volume'
        ? (_displayValue > 0 ? Icons.volume_up : Icons.volume_off)
        : Icons.brightness_6;
    final label = _adjustType == 'volume' ? '音量' : '亮度';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: _displayValue,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(_displayValue * 100).toInt()}%',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSeekIndicator() {
    final seekDelta = _seekPosition - _seekStartPosition;
    final isForward = seekDelta >= Duration.zero;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isForward ? Icons.fast_forward : Icons.fast_rewind,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            '${isForward ? '+' : ''}${_formatDuration(seekDelta)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatDuration(_seekPosition)} / ${_formatDuration(_videoDuration)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 150,
            child: LinearProgressIndicator(
              value: _displayValue.clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final isNegative = duration.isNegative;
    final d = isNegative ? -duration : duration;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${isNegative ? '-' : ''}${d.inHours}:$minutes:$seconds';
    }
    return '${isNegative ? '-' : ''}$minutes:$seconds';
  }
}
