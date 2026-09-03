import 'package:flutter/material.dart';
import '../../models/organization_card.dart';

/// Widget per la visualizzazione di una domanda mirata/adattiva con opzioni.
class QuestionCardView extends StatelessWidget {
  const QuestionCardView({
    super.key,
    required this.card,
    required this.onAnswerSelected,
  });

  final OrganizationCard card;
  final ValueChanged<String> onAnswerSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final options =
        (card.payload['options'] as List?)?.map((e) => e.toString()).toList() ??
        card.actions.map((a) => a.label).toList();

    final isConfirmed = card.state == OrganizationCardState.confirmed;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConfirmed
              ? (isDark ? Colors.white24 : Colors.black12)
              : theme.colorScheme.primary.withAlpha(80),
          width: isConfirmed ? 1.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? Colors.green.withAlpha(25)
                      : theme.colorScheme.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConfirmed
                      ? Icons.check_rounded
                      : Icons.help_outline_rounded,
                  size: 18,
                  color: isConfirmed ? Colors.green : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  card.title ?? 'Domanda',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (card.description != null && card.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              card.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isConfirmed
                    ? (isDark ? Colors.white70 : Colors.black87)
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isConfirmed ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
          if (!isConfirmed && options.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final opt in options)
                  _buildOptionButton(context, opt, theme),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String option,
    ThemeData theme,
  ) {
    final isDecideOrUnsure =
        option.toLowerCase().contains('non lo so') ||
        option.toLowerCase().contains('decidi tu');

    return InkWell(
      onTap: () => onAnswerSelected(option),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDecideOrUnsure
              ? theme.colorScheme.surfaceContainerHighest.withAlpha(120)
              : theme.colorScheme.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDecideOrUnsure
                ? Colors.transparent
                : theme.colorScheme.primary.withAlpha(50),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              option,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDecideOrUnsure
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: isDecideOrUnsure
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
