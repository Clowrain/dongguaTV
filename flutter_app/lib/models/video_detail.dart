import 'package:equatable/equatable.dart';

/// 视频详情模型
class VideoDetail extends Equatable {
  /// 视频 ID
  final String vodId;
  
  /// 视频名称
  final String vodName;
  
  /// 别名
  final String vodSub;
  
  /// 海报图片
  final String vodPic;
  
  /// 演员
  final String vodActor;
  
  /// 导演
  final String vodDirector;
  
  /// 编剧
  final String vodWriter;
  
  /// 简介
  final String vodContent;
  
  /// 评分
  final String vodScore;
  
  /// 年份
  final String vodYear;
  
  /// 地区
  final String vodArea;
  
  /// 语言
  final String vodLang;
  
  /// 类型
  final String typeName;
  
  /// 更新时间
  final String vodTime;
  
  /// 备注
  final String vodRemarks;
  
  /// 播放来源
  final String vodPlayFrom;
  
  /// 播放地址
  final String vodPlayUrl;
  
  /// 来源站点 Key
  final String siteKey;
  
  /// 来源站点名称
  final String siteName;

  const VideoDetail({
    required this.vodId,
    required this.vodName,
    this.vodSub = '',
    this.vodPic = '',
    this.vodActor = '',
    this.vodDirector = '',
    this.vodWriter = '',
    this.vodContent = '',
    this.vodScore = '',
    this.vodYear = '',
    this.vodArea = '',
    this.vodLang = '',
    this.typeName = '',
    this.vodTime = '',
    this.vodRemarks = '',
    this.vodPlayFrom = '',
    this.vodPlayUrl = '',
    this.siteKey = '',
    this.siteName = '',
  });

  factory VideoDetail.fromJson(Map<String, dynamic> json, {
    String siteKey = '',
    String siteName = '',
  }) {
    return VideoDetail(
      vodId: _parseId(json['vod_id']),
      vodName: json['vod_name'] as String? ?? '',
      vodSub: json['vod_sub'] as String? ?? '',
      vodPic: json['vod_pic'] as String? ?? '',
      vodActor: json['vod_actor'] as String? ?? '',
      vodDirector: json['vod_director'] as String? ?? '',
      vodWriter: json['vod_writer'] as String? ?? '',
      vodContent: _cleanHtml(json['vod_content'] as String? ?? ''),
      vodScore: json['vod_score']?.toString() ?? '',
      vodYear: json['vod_year']?.toString() ?? '',
      vodArea: json['vod_area'] as String? ?? '',
      vodLang: json['vod_lang'] as String? ?? '',
      typeName: json['type_name'] as String? ?? '',
      vodTime: json['vod_time'] as String? ?? '',
      vodRemarks: json['vod_remarks'] as String? ?? '',
      vodPlayFrom: json['vod_play_from'] as String? ?? '',
      vodPlayUrl: json['vod_play_url'] as String? ?? '',
      siteKey: siteKey,
      siteName: siteName,
    );
  }

  static String _parseId(dynamic id) {
    if (id == null) return '';
    if (id is int) return id.toString();
    return id.toString();
  }

  /// 清理 HTML 标签
  static String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  /// 获取播放线路列表
  List<PlaySource> get playSources {
    if (vodPlayFrom.isEmpty || vodPlayUrl.isEmpty) return [];
    
    final sources = vodPlayFrom.split(r'$$$');
    final urls = vodPlayUrl.split(r'$$$');
    
    final result = <PlaySource>[];
    for (var i = 0; i < sources.length && i < urls.length; i++) {
      final episodes = _parseEpisodes(urls[i]);
      if (episodes.isNotEmpty) {
        result.add(PlaySource(
          name: sources[i].trim(),
          episodes: episodes,
        ));
      }
    }
    return result;
  }

  /// 解析剧集列表
  List<Episode> _parseEpisodes(String urlString) {
    if (urlString.isEmpty) return [];
    
    final episodes = <Episode>[];
    final items = urlString.split('#');
    
    for (var i = 0; i < items.length; i++) {
      final item = items[i].trim();
      if (item.isEmpty) continue;
      
      final parts = item.split(r'$');
      if (parts.length >= 2) {
        episodes.add(Episode(
          name: parts[0].trim(),
          url: parts[1].trim(),
          index: i,
        ));
      } else if (parts.length == 1 && parts[0].contains('http')) {
        episodes.add(Episode(
          name: '第${i + 1}集',
          url: parts[0].trim(),
          index: i,
        ));
      }
    }
    return episodes;
  }

  /// 是否为电影 (只有一集)
  bool get isMovie {
    final sources = playSources;
    if (sources.isEmpty) return true;
    return sources.first.episodes.length == 1;
  }

  @override
  List<Object?> get props => [vodId, vodName, siteKey];
}

/// 播放线路
class PlaySource extends Equatable {
  final String name;
  final List<Episode> episodes;

  const PlaySource({
    required this.name,
    required this.episodes,
  });

  @override
  List<Object?> get props => [name, episodes];
}

/// 剧集
class Episode extends Equatable {
  final String name;
  final String url;
  final int index;

  const Episode({
    required this.name,
    required this.url,
    required this.index,
  });

  @override
  List<Object?> get props => [name, url, index];
}
