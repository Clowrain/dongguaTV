import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/theme.dart';
import 'config/routes.dart';
import 'blocs/blocs.dart';

/// E视界 Flutter 应用
class DongguaTvApp extends StatelessWidget {
  const DongguaTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc()..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (_) => HomeBloc(),
        ),
        BlocProvider(
          create: (_) => SearchBloc()..add(SearchHistoryLoaded()),
        ),
      ],
      child: MaterialApp.router(
        title: 'E视界',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: AppRoutes.router,
      ),
    );
  }
}
