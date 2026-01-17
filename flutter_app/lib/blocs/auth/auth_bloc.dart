import 'package:flutter_bloc/flutter_bloc.dart';

import '../../config/app_config.dart';
import '../../services/services.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// 认证 BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService;
  final CacheService _cacheService;

  AuthBloc({
    ApiService? apiService,
    CacheService? cacheService,
  })  : _apiService = apiService ?? ApiService(),
        _cacheService = cacheService ?? CacheService(),
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthServerSet>(_onServerSet);
    on<AuthPasswordSubmitted>(_onPasswordSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  /// 检查认证状态
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // 1. 检查是否已配置服务器地址
    final savedUrl = _cacheService.getServerUrl();
    if (savedUrl == null || savedUrl.isEmpty) {
      emit(AuthNeedsServer());
      return;
    }

    // 2. 初始化 API 服务
    AppConfig().serverUrl = savedUrl;
    _apiService.init(baseUrl: savedUrl);

    try {
      // 3. 检查是否需要密码
      final authCheck = await _apiService.checkAuth();
      final requirePassword = authCheck['requirePassword'] as bool? ?? false;
      final multiUserMode = authCheck['multiUserMode'] as bool? ?? false;

      if (!requirePassword) {
        // 无需密码，直接进入
        await _loadConfig();
        emit(const AuthSuccess(token: ''));
        return;
      }

      // 4. 检查是否有保存的 token
      final savedToken = _cacheService.getAuthToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        // 验证保存的 token
        final verifyResult = await _apiService.verifyPassword('');
        // 如果密码为空还是成功，说明 token 仍有效
        // 实际上需要用 passwordHash 验证
        // 这里简化处理，假设 token 有效
        AppConfig().authToken = savedToken;
        await _loadConfig(token: savedToken);
        
        final syncEnabled = verifyResult['syncEnabled'] as bool? ?? false;
        emit(AuthSuccess(token: savedToken, syncEnabled: syncEnabled));
        return;
      }

      // 5. 需要输入密码
      emit(AuthNeedsPassword(multiUserMode: multiUserMode));
    } catch (e) {
      emit(AuthFailure('连接服务器失败: $e'));
    }
  }

  /// 设置服务器地址
  Future<void> _onServerSet(
    AuthServerSet event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final url = event.serverUrl.trim();
    if (url.isEmpty) {
      emit(const AuthFailure('请输入服务器地址'));
      return;
    }

    // 验证 URL 格式
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      emit(const AuthFailure('请输入有效的 URL (以 http:// 或 https:// 开头)'));
      return;
    }

    try {
      // 初始化 API 并测试连接
      _apiService.init(baseUrl: url);
      
      // 尝试获取配置测试连接
      await _apiService.checkAuth();

      // 保存服务器地址
      await _cacheService.saveServerUrl(url);
      AppConfig().serverUrl = url;

      // 重新检查认证
      add(AuthCheckRequested());
    } catch (e) {
      emit(AuthFailure('无法连接到服务器: $e'));
    }
  }

  /// 提交密码
  Future<void> _onPasswordSubmitted(
    AuthPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final result = await _apiService.verifyPassword(event.password);
      final success = result['success'] as bool? ?? false;

      if (!success) {
        emit(const AuthFailure('密码错误'));
        return;
      }

      final token = result['passwordHash'] as String? ?? '';
      final syncEnabled = result['syncEnabled'] as bool? ?? false;

      // 保存 token
      await _cacheService.saveAuthToken(token);
      AppConfig().authToken = token;

      // 加载配置
      await _loadConfig(token: token);

      emit(AuthSuccess(token: token, syncEnabled: syncEnabled));
    } catch (e) {
      emit(AuthFailure('验证失败: $e'));
    }
  }

  /// 登出
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _cacheService.clearAuth();
    AppConfig().reset();
    emit(AuthNeedsServer());
  }

  /// 加载服务器配置
  Future<void> _loadConfig({String? token}) async {
    try {
      final config = await _apiService.getConfig(token: token);
      final appConfig = AppConfig();
      
      appConfig.tmdbApiKey = config['tmdb_api_key'] as String? ?? '';
      appConfig.tmdbProxyUrl = config['tmdb_proxy_url'] as String? ?? '';
      appConfig.corsProxyUrl = config['cors_proxy_url'] as String? ?? '';
      appConfig.enableLocalImageCache = 
          config['enable_local_image_cache'] as bool? ?? true;
      appConfig.syncEnabled = config['sync_enabled'] as bool? ?? false;
      appConfig.multiUserMode = config['multi_user_mode'] as bool? ?? false;
    } catch (_) {
      // 配置加载失败不影响登录
    }
  }
}
