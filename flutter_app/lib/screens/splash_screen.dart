import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../blocs/blocs.dart';
import '../config/theme.dart';

/// 启动页 - 带有精美动画效果
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _fadeController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Logo 动画控制器
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 文字动画控制器
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // 淡出动画控制器
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Logo 缩放动画（从 0.5 到 1.0）
    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));

    // Logo 透明度动画
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // 文字滑动动画
    _textSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    // 文字透明度动画
    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    // 整体淡出动画
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimationSequence() async {
    // 1. Logo 动画
    await _logoController.forward();

    // 等待 200ms
    await Future.delayed(const Duration(milliseconds: 200));

    // 2. 文字动画
    await _textController.forward();

    // 等待 800ms 让用户看到完整效果
    await Future.delayed(const Duration(milliseconds: 800));

    // 3. 开始淡出（如果还在当前页面）
    if (mounted) {
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _logoController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthNeedsServer) {
          context.go('/server-setup');
        } else if (state is AuthNeedsPassword) {
          context.go('/login');
        } else if (state is AuthSuccess) {
          context.go('/home');
        } else if (state is AuthFailure) {
          context.go('/server-setup');
        }
      },
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          );
        },
        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.backgroundColor,
                  AppTheme.backgroundColor.withValues(alpha: 0.8),
                  const Color(0xFF1a1a1a),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo 区域
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoOpacityAnimation.value,
                          child: Transform.scale(
                            scale: _logoScaleAnimation.value,
                            child: _buildLogoSection(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // 文字区域
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textOpacityAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _textSlideAnimation.value),
                            child: _buildTextSection(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 60),

                    // 加载指示器
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textOpacityAnimation.value,
                          child: _buildLoadingIndicator(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      width: 160.0,
      height: 160.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Image.asset(
          'assets/launcher/icon.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTextSection() {
    return Column(
      children: [
        // 主标题
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.white,
              Colors.white.withValues(alpha: 0.8),
            ],
          ).createShader(bounds),
          child: const Text(
            'E视界',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 8,
              height: 1.2,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 副标题
        Text(
          '流媒体聚合播放器',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary.withValues(alpha: 0.8),
            letterSpacing: 2,
            fontWeight: FontWeight.w300,
          ),
        ),

        const SizedBox(height: 8),

        // Slogan
        Text(
          'Discover Your World of Entertainment',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
            letterSpacing: 1,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 40.0,
          height: 40.0,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.accentColor.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '加载中...',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary.withValues(alpha: 0.6),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
