import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../blocs/blocs.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../models/models.dart';
import 'multi_source_detail_screen.dart';

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
    // 进入搜索页时清空之前的搜索状态
    context.read<SearchBloc>().add(SearchCleared());
    
    // 如果有初始关键词，自动填充并搜索
    if (widget.initialKeyword != null && widget.initialKeyword!.isNotEmpty) {
      _controller.text = widget.initialKeyword!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _search(widget.initialKeyword!);
      });
    } else {
      // 自动聚焦搜索框
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        titleSpacing: 0, // 减少返回按钮和标题之间的间距
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
        // 移除右侧关闭按钮
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchInitial) {
            return _buildHistoryList(state.history);
          }

          if (state is SearchLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '正在搜索 "${state.keyword}"...',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          if (state is SearchResults) {
            return _buildResults(state);
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

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// 构建搜索框
  Widget _buildSearchField() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      textInputAction: TextInputAction.search,
      textAlignVertical: TextAlignVertical.center, // 垂直居中
      onSubmitted: _search,
      decoration: InputDecoration(
        hintText: '搜索电影、剧集...',
        hintStyle: TextStyle(
          color: AppTheme.textSecondary.withAlpha(128),
          fontSize: 15,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        // 移除悬停高亮效果
        filled: false,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
      ),
    );
  }

  /// 构建搜索历史列表
  Widget _buildHistoryList(List<String> history) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '输入关键词搜索影视资源',
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.5),
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
              onPressed: () {
                _controller.text = keyword;
                _search(keyword);
              },
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

  /// 构建搜索结果（按名称分组，显示 X源）
  Widget _buildResults(SearchResults state) {
    // 按名称分组
    final groups = <String, _SearchGroup>{};
    for (final item in state.items) {
      final name = item.vodName;
      if (!groups.containsKey(name)) {
        groups[name] = _SearchGroup(name: name, pic: item.vodPic, sources: []);
      }
      // 如果当前组的图片为空或默认图，用新图替换
      final currentPic = groups[name]!.pic;
      if (currentPic.isEmpty || currentPic.contains('nopic') || currentPic.contains('default')) {
        if (item.vodPic.isNotEmpty && !item.vodPic.contains('nopic') && !item.vodPic.contains('default')) {
          groups[name] = _SearchGroup(
            name: name,
            pic: item.vodPic,
            sources: groups[name]!.sources,
          );
        }
      }
      // 按 siteKey 去重，避免同一站点重复出现
      final existingKeys = groups[name]!.sources.map((s) => s.siteKey).toSet();
      if (!existingKeys.contains(item.siteKey)) {
        groups[name]!.sources.add(item);
      }
    }

    // 按来源数量排序（多源优先）
    final groupedList = groups.values.toList()
      ..sort((a, b) => b.sources.length.compareTo(a.sources.length));

    if (groupedList.isEmpty && !state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '未找到 "${state.keyword}" 相关结果',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 加载中提示（仅在加载中且有结果时显示）
        if (state.isLoading)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  groupedList.isEmpty ? '正在全网搜索...' : '正在搜索更多资源...',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        // 结果列表
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.55,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: groupedList.length,
            itemBuilder: (context, index) {
              final group = groupedList[index];
              return _GroupedResultCard(
                group: group,
                onTap: () {
                  // 导航到多源详情页，传递所有源
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MultiSourceDetailScreen(
                        vodName: group.name,
                        pic: group.pic,
                        sources: group.sources,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 搜索分组
class _SearchGroup {
  final String name;
  final String pic;
  final List<VideoItem> sources;

  _SearchGroup({required this.name, required this.pic, required this.sources});
}

/// 分组结果卡片（显示 X源）
class _GroupedResultCard extends StatelessWidget {
  final _SearchGroup group;
  final VoidCallback onTap;

  const _GroupedResultCard({
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 海报
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: group.pic.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: group.pic,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (_, __) => Container(
                            color: AppTheme.surfaceColor,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.surfaceColor,
                            child: const Icon(
                              Icons.movie,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.surfaceColor,
                          child: const Icon(
                            Icons.movie,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                ),
                // X源 标签
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${group.sources.length} 源',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // 标题
          Text(
            group.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 搜索结果卡片
class _SearchResultCard extends StatelessWidget {
  final VideoItem item;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 海报
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.vodPic.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.vodPic,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (_, __) => Container(
                            color: AppTheme.surfaceColor,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.surfaceColor,
                            child: const Icon(
                              Icons.movie,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.surfaceColor,
                          child: const Icon(
                            Icons.movie,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                ),
                // 备注标签
                if (item.vodRemarks.isNotEmpty)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.vodRemarks,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // 来源标签
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.siteName,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // 标题
          Text(
            item.vodName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
            ),
          ),
          // 类型
          if (item.typeName.isNotEmpty)
            Text(
              item.typeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
