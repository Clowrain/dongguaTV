import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'source_latency_tester.dart';

/// 线路选择器组件
class DetailSourceSelector extends StatelessWidget {
  final List<SourceWithLatency> sources;
  final SourceWithLatency? currentSource;
  final bool isTestingSources;
  final Function(SourceWithLatency) onSourceSelected;

  const DetailSourceSelector({
    super.key,
    required this.sources,
    required this.currentSource,
    required this.isTestingSources,
    required this.onSourceSelected,
  });

  List<SourceWithLatency> get _fastSources =>
      sources.where((s) => s.latency != null && s.latency! >= 0 && s.latency! < 600).toList();

  List<SourceWithLatency> get _slowSources =>
      sources.where((s) => s.latency != null && s.latency! >= 600).toList();

  @override
  Widget build(BuildContext context) {
    // 合并快速和慢速线路，按延迟排序
    final allSources = <SourceWithLatency>[
      ..._fastSources,
      ..._slowSources,
    ];

    // 如果还在测速，显示所有源
    final sourcesToShow = allSources.isEmpty ? sources : allSources;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 线路 Tab 行
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sourcesToShow.length + (isTestingSources ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              // 显示测速指示器
              if (isTestingSources && index == sourcesToShow.length) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '测速中...',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final source = sourcesToShow[index];
              return _SourceTab(
                source: source,
                isActive: currentSource?.source.siteKey == source.source.siteKey,
                onTap: () => onSourceSelected(source),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 单个线路 Tab
class _SourceTab extends StatelessWidget {
  final SourceWithLatency source;
  final bool isActive;
  final VoidCallback onTap;

  const _SourceTab({
    required this.source,
    required this.isActive,
    required this.onTap,
  });

  Color _getLatencyColor(int latency) {
    if (latency < 300) return const Color(0xFF22C55E); // 绿色 - 快
    if (latency < 600) return const Color(0xFFEAB308); // 黄色 - 中
    return const Color(0xFFEF4444); // 红色 - 慢
  }

  @override
  Widget build(BuildContext context) {
    final latency = source.latency;
    final hasLatency = latency != null && latency >= 0 && latency < 9999;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accentColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.accentColor : AppTheme.borderColor,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 选中标记
            if (isActive)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.check, size: 14, color: Colors.white),
              ),
            // 线路名称
            Text(
              source.source.siteName,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? Colors.white : AppTheme.textPrimary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            // 延迟
            if (hasLatency) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withAlpha(50)
                      : _getLatencyColor(latency).withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${latency}ms',
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? Colors.white : _getLatencyColor(latency),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
