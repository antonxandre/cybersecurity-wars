import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/lobby_models.dart';
import 'lobby_panel.dart';

/// Painel de Notícias e Atualizações Táticas do Perímetro.
class NewsPanel extends StatefulWidget {
  final List<LobbyNewsItem> news;

  const NewsPanel({super.key, required this.news});

  @override
  State<NewsPanel> createState() => _NewsPanelState();
}

class _NewsPanelState extends State<NewsPanel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.news.isEmpty) return const SizedBox.shrink();

    final item = widget.news[_currentIndex];

    return LobbyPanel(
      title: 'COMUNICADOS TÁTICOS',
      icon: Icons.newspaper_rounded,
      accentColor: item.accentColor,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.news.length, (index) {
          final isCurrent = index == _currentIndex;
          return GestureDetector(
            onTap: () => setState(() => _currentIndex = index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: isCurrent ? 12 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: isCurrent ? item.accentColor : AppColors.textMuted,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: item.accentColor, width: 0.8),
                ),
                child: Text(
                  item.tag,
                  style: AppTypography.codeSmall.copyWith(
                    color: item.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                item.date,
                style: AppTypography.codeSmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            item.summary,
            style: AppTypography.codeSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
