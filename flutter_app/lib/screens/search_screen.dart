import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/blocs.dart';
import '../config/theme.dart';
import 'multi_source_detail_screen.dart';
import 'widgets/search_history_list.dart';
import 'widgets/search_result_card.dart';

/// 搜索页
class SearchScreen extends StatefulWidget {
  final String? initialKeyword;

  const SearchScreen({super.key, this.initialKeyword});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<SearchBloc>().add(SearchCleared());

    if (widget.initialKeyword != null && widget.initialKeyword!.isNotEmpty) {
      _controller.text = widget.initialKeyword!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _search(widget.initialKeyword!);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search(String keyword) {
    if (keyword.trim().isEmpty) return;
    context.read<SearchBloc>().add(SearchSubmitted(keyword));
    _focusNode.unfocus();
  }

  void _onHistoryTap(String keyword) {
    _controller.text = keyword;
    _search(keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        titleSpacing: 0,
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(20)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: AppTheme.textSecondary.withAlpha(150),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildSearchField()),
            ],
          ),
        ),
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchInitial) {
            return SearchHistoryList(
              history: state.history,
              onHistoryTap: _onHistoryTap,
            );
          }

          if (state is SearchLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentColor,
              ),
            );
          }

          if (state is SearchError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          if (state is SearchResults) {
            return _buildResults(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: const InputDecoration(
        hintText: '搜索电影、剧集...',
        hintStyle: TextStyle(color: AppTheme.textSecondary),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      onSubmitted: _search,
      textInputAction: TextInputAction.search,
    );
  }

  Widget _buildResults(SearchResults state) {
    // 按名称分组
    final groups = <String, SearchGroup>{};
    for (final item in state.items) {
      final name = item.vodName;
      if (!groups.containsKey(name)) {
        groups[name] = SearchGroup(name: name, pic: item.vodPic, sources: []);
      }

      // 更新图片（避免使用默认图）
      final currentPic = groups[name]!.pic;
      if (currentPic.isEmpty || currentPic.contains('nopic') || currentPic.contains('default')) {
        if (item.vodPic.isNotEmpty && !item.vodPic.contains('nopic') && !item.vodPic.contains('default')) {
          groups[name] = SearchGroup(
            name: name,
            pic: item.vodPic,
            sources: groups[name]!.sources,
          );
        }
      }

      // 按 siteKey 去重
      final existingKeys = groups[name]!.sources.map((s) => s.siteKey).toSet();
      if (!existingKeys.contains(item.siteKey)) {
        groups[name]!.sources.add(item);
      }
    }

    final groupList = groups.values.toList();
    groupList.sort((a, b) => b.sources.length.compareTo(a.sources.length));

    if (groupList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              '未找到相关内容',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: groupList.length,
      itemBuilder: (context, index) {
        final group = groupList[index];
        return SearchGroupCard(
          group: group,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MultiSourceDetailScreen(
                  vodName: group.name,
                  pic: group.pic,
                  sources: group.sources,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
