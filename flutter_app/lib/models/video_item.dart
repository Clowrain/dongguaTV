import 'package:equatable/equatable.dart';

/// 视频条目模型 (搜索结果/列表项)
class VideoItem extends Equatable {
  /// 视频 ID
  final String vodId;
  
  /// 视频名称
  final String vodName;
  
  /// 海报图片 URL
  final String vodPic;
  
  /// 备注 (如: 更新至第10集)
  final String vodRemarks;
  
  /// 年份
  final String vodYear;
  
  /// 类型名称
  final String typeName;
  
  /// 内容简介
  final String vodContent;
  
  /// 播放来源 (多个用 $$$ 分隔)
  final String vodPlayFrom;
  
  /// 播放地址 (多个用 $$$ 分隔)
  final String vodPlayUrl;
  
  /// 来源站点 Key
  final String siteKey;
  
  /// 来源站点名称
  final String siteName;

  const VideoItem({
    required this.vodId,
    required this.vodName,
    this.vodPic = '',
    this.vodRemarks = '',
    this.vodYear = '',
    this.typeName = '',
    this.vodContent = '',
    this.vodPlayFrom = '',
    this.vodPlayUrl = '',
    this.siteKey = '',
    this.siteName = '',
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      vodId: _parseId(json['vod_id']),
      vodName: json['vod_name'] as String? ?? '',
      vodPic: json['vod_pic'] as String? ?? '',
      vodRemarks: json['vod_remarks'] as String? ?? '',
      vodYear: json['vod_year'] as String? ?? '',
      typeName: json['type_name'] as String? ?? '',
      vodContent: json['vod_content'] as String? ?? '',
      vodPlayFrom: json['vod_play_from'] as String? ?? '',
      vodPlayUrl: json['vod_play_url'] as String? ?? '',
      siteKey: json['site_key'] as String? ?? '',
      siteName: json['site_name'] as String? ?? '',
    );
  }

  /// 解析 ID (可能是 int 或 String)
  static String _parseId(dynamic id) {
    if (id == null) return '';
    if (id is int) return id.toString();
    return id.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'vod_id': vodId,
      'vod_name': vodName,
      'vod_pic': vodPic,
      'vod_remarks': vodRemarks,
      'vod_year': vodYear,
      'type_name': typeName,
      'vod_content': vodContent,
      'vod_play_from': vodPlayFrom,
      'vod_play_url': vodPlayUrl,
      'site_key': siteKey,
      'site_name': siteName,
    };
  }

  /// 是否有播放地址
  bool get hasPlayUrl => vodPlayUrl.isNotEmpty;

  /// 获取播放来源列表
  List<String> get playSources {
    if (vodPlayFrom.isEmpty) return [];
    return vodPlayFrom.split(r'$$$');
  }

  /// 获取唯一标识 (站点Key + 视频ID)
  String get uniqueId => '${siteKey}_$vodId';

  @override
  List<Object?> get props => [
        vodId,
        vodName,
        vodPic,
        vodRemarks,
        vodYear,
        typeName,
        siteKey,
      ];
}
