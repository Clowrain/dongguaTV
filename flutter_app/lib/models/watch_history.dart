import 'package:equatable/equatable.dart';

/// 观看历史模型
class WatchHistory extends Equatable {
  /// 唯一标识 (格式: siteKey_vodId)
  final String id;
  
  /// 视频 ID
  final String vodId;
  
  /// 视频名称
  final String vodName;
  
  /// 海报图片
  final String vodPic;
  
  /// 类型
  final String typeName;
  
  /// 来源站点 Key
  final String siteKey;
  
  /// 来源站点名称
  final String siteName;
  
  /// 当前播放线路索引
  final int sourceIndex;
  
  /// 当前播放剧集索引
  final int episodeIndex;
  
  /// 当前播放剧集名称
  final String episodeName;
  
  /// 播放进度 (秒)
  final int progress;
  
  /// 总时长 (秒)
  final int duration;
  
  /// 最后观看时间
  final DateTime updatedAt;

  const WatchHistory({
    required this.id,
    required this.vodId,
    required this.vodName,
    this.vodPic = '',
    this.typeName = '',
    required this.siteKey,
    this.siteName = '',
    this.sourceIndex = 0,
    this.episodeIndex = 0,
    this.episodeName = '',
    this.progress = 0,
    this.duration = 0,
    required this.updatedAt,
  });

  factory WatchHistory.fromJson(Map<String, dynamic> json) {
    return WatchHistory(
      id: json['id'] as String? ?? '',
      vodId: json['vod_id'] as String? ?? '',
      vodName: json['vod_name'] as String? ?? '',
      vodPic: json['vod_pic'] as String? ?? '',
      typeName: json['type_name'] as String? ?? '',
      siteKey: json['site_key'] as String? ?? '',
      siteName: json['site_name'] as String? ?? '',
      sourceIndex: json['source_index'] as int? ?? 0,
      episodeIndex: json['episode_index'] as int? ?? 0,
      episodeName: json['episode_name'] as String? ?? '',
      progress: json['progress'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vod_id': vodId,
      'vod_name': vodName,
      'vod_pic': vodPic,
      'type_name': typeName,
      'site_key': siteKey,
      'site_name': siteName,
      'source_index': sourceIndex,
      'episode_index': episodeIndex,
      'episode_name': episodeName,
      'progress': progress,
      'duration': duration,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 获取进度百分比
  double get progressPercent {
    if (duration == 0) return 0;
    return (progress / duration).clamp(0.0, 1.0);
  }

  /// 获取进度显示文本
  String get progressText {
    if (duration == 0) return '';
    return '${_formatDuration(progress)} / ${_formatDuration(duration)}';
  }

  /// 格式化时长
  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 创建更新后的副本
  WatchHistory copyWith({
    int? sourceIndex,
    int? episodeIndex,
    String? episodeName,
    int? progress,
    int? duration,
  }) {
    return WatchHistory(
      id: id,
      vodId: vodId,
      vodName: vodName,
      vodPic: vodPic,
      typeName: typeName,
      siteKey: siteKey,
      siteName: siteName,
      sourceIndex: sourceIndex ?? this.sourceIndex,
      episodeIndex: episodeIndex ?? this.episodeIndex,
      episodeName: episodeName ?? this.episodeName,
      progress: progress ?? this.progress,
      duration: duration ?? this.duration,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, updatedAt];
}
