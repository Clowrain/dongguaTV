import 'package:equatable/equatable.dart';

/// 认证状态基类
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// 初始状态 (检查中)
class AuthInitial extends AuthState {}

/// 需要配置服务器
class AuthNeedsServer extends AuthState {}

/// 需要密码验证
class AuthNeedsPassword extends AuthState {
  final bool multiUserMode;

  const AuthNeedsPassword({this.multiUserMode = false});

  @override
  List<Object?> get props => [multiUserMode];
}

/// 认证成功
class AuthSuccess extends AuthState {
  final String token;
  final bool syncEnabled;

  const AuthSuccess({
    required this.token,
    this.syncEnabled = false,
  });

  @override
  List<Object?> get props => [token, syncEnabled];
}

/// 认证失败
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// 加载中
class AuthLoading extends AuthState {}
