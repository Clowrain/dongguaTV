import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/blocs.dart';
import '../../config/theme.dart';

/// 搜索历史列表组件
class SearchHistoryList extends StatelessWidget {
  final List<String> history;
  final Function(String) onHistoryTap;

  const SearchHistoryList({
    super.key,
    required this.history,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '输入关键词搜索影视资源',
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '搜索历史',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<SearchBloc>().add(SearchHistoryCleared());
              },
              child: const Text(
                '清空',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: history.map((keyword) {
            return InputChip(
              label: Text(keyword),
              onPressed: () => onHistoryTap(keyword),
              backgroundColor: AppTheme.surfaceColor,
              labelStyle: const TextStyle(color: AppTheme.textPrimary),
              deleteIconColor: AppTheme.textSecondary,
              onDeleted: () {
                context.read<SearchBloc>().add(SearchHistoryRemoved(keyword));
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
