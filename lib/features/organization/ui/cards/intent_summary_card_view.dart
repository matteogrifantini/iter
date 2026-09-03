import 'package:flutter/material.dart';
import '../../models/organization_card.dart';

/// Widget per la visualizzazione dell'intento iniziale dell'utente.
class IntentSummaryCardView extends StatelessWidget {
  const IntentSummaryCardView({
    super.key,
    required this.card,
    this.onEditPressed,
  });

  final OrganizationCard card;
  final VoidCallback? onEditPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final destinations =
        (card.payload['candidateDestinations'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final budget = card.payload['budgetEurPerPerson'] as double?;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
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
                  color: theme.colorScheme.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.explore_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  card.title ?? 'Desiderio di viaggio',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onEditPressed != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Modifica desiderio',
                  onPressed: onEditPressed,
                ),
            ],
          ),
          if (card.description != null && card.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '“${card.description}”',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (destinations.isNotEmpty || budget != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final dest in destinations)
                  Chip(
                    avatar: const Icon(Icons.location_on_outlined, size: 16),
                    label: Text(dest),
                    visualDensity: VisualDensity.compact,
                  ),
                if (budget != null)
                  Chip(
                    avatar: const Icon(Icons.euro_rounded, size: 16),
                    label: Text('Target: ~${budget.round()} € p.p.'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
