import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/server_setup_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/category_screen.dart';
import '../screens/history_screen.dart';
import '../screens/multi_source_detail_screen.dart';
import '../models/video_item.dart';

/// 应用路由配置
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String serverSetup = '/server-setup';
  static const String login = '/login';
  static const String home = '/home';
  static const String search = '/search';
  static const String detail = '/detail/:siteKey/:vodId';
  static const String category = '/category/:key';
  static const String history = '/history';

  /// 路由配置
  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: serverSetup,
        builder: (context, state) => const ServerSetupScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: search,
        builder: (context, state) {
          final keyword = state.uri.queryParameters['keyword'];
          return SearchScreen(initialKeyword: keyword);
        },
      ),
      GoRoute(
        path: '/detail/:siteKey/:vodId',
        builder: (context, state) {
          final siteKey = state.pathParameters['siteKey'] ?? '';
          final vodId = state.pathParameters['vodId'] ?? '';
          final vodName = state.uri.queryParameters['name'] ?? '';
          return DetailScreen(
            siteKey: siteKey,
            vodId: vodId,
            vodName: vodName,
          );
        },
      ),
      // 历史记录进入播放页（使用 extra 传递数据）
      GoRoute(
        path: '/detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(body: Center(child: Text('无效的播放参数')));
          }
          return MultiSourceDetailScreen(
            vodName: extra['vodName'] as String? ?? '',
            pic: extra['pic'] as String? ?? '',
            sources: (extra['sources'] as List?)?.cast<VideoItem>() ?? [],
            initialEpisodeIndex: extra['initialEpisodeIndex'] as int?,
            initialPosition: extra['initialPosition'] as Duration?,
            initialSiteKey: extra['initialSiteKey'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/category/:key',
        builder: (context, state) {
          final key = state.pathParameters['key'] ?? '';
          final queryParams = state.uri.queryParameters;
          return CategoryScreen(
            categoryKey: key,
            title: queryParams['title'] ?? '',
            path: queryParams['path'] ?? '',
            params: queryParams['params'] ?? '',
            sortMode: queryParams['sortMode'],
          );
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
    ],
  );

  /// 导航到详情页
  static void goToDetail(
    BuildContext context, {
    required String siteKey,
    required String vodId,
    String? vodName,
  }) {
    context.push(
      '/detail/$siteKey/$vodId${vodName != null ? '?name=$vodName' : ''}',
    );
  }
}
