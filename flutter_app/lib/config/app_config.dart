/// 应用配置
class AppConfig {
  /// 单例模式
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  /// 服务器地址 (可由用户配置)
  String _serverUrl = '';

  /// 获取服务器地址
  String get serverUrl => _serverUrl;

  /// 设置服务器地址
  set serverUrl(String url) {
    // 移除末尾斜杠
    _serverUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// 是否已配置服务器
  bool get isConfigured => _serverUrl.isNotEmpty;

  /// TMDB API Key (从服务器获取)
  String tmdbApiKey = '';

  /// TMDB 代理 URL (从服务器获取)
  String tmdbProxyUrl = '';

  /// CORS 代理 URL (从服务器获取)
  String corsProxyUrl = '';

  /// 是否启用本地图片缓存
  bool enableLocalImageCache = true;

  /// 是否启用历史同步
  bool syncEnabled = false;

  /// 是否为多用户模式
  bool multiUserMode = false;

  /// 用户认证 token
  String authToken = '';

  /// 是否已认证
  bool get isAuthenticated => authToken.isNotEmpty;

  /// 获取 TMDB 图片 URL
  String getTmdbImageUrl(String path, {String size = 'w500'}) {
    if (path.isEmpty) return '';
    
    // 如果服务器配置了代理，使用服务器代理
    if (_serverUrl.isNotEmpty) {
      return '$_serverUrl/api/tmdb-image/$size/${path.replaceFirst('/', '')}';
    }
    
    // 否则直接使用 TMDB
    final base = tmdbProxyUrl.isNotEmpty 
        ? '$tmdbProxyUrl/t/p' 
        : 'https://image.tmdb.org/t/p';
    return '$base/$size$path';
  }

  /// 重置配置
  void reset() {
    _serverUrl = '';
    tmdbApiKey = '';
    tmdbProxyUrl = '';
    corsProxyUrl = '';
    enableLocalImageCache = true;
    syncEnabled = false;
    multiUserMode = false;
    authToken = '';
  }
}
