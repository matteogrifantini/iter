import 'package:flutter/material.dart';

/// Rich interactive option buttons displayed under the assistant's question in chat.
/// Supports emoji icons, responsive 2/3 per row layout, and multi-selection for
/// travel vibes/interests.
class InteractiveQuestionOptions extends StatefulWidget {
  const InteractiveQuestionOptions({
    super.key,
    required this.options,
    required this.onSelect,
    this.allowMultiSelect,
  });

  final List<String> options;
  final ValueChanged<String> onSelect;
  final bool? allowMultiSelect;

  @override
  State<InteractiveQuestionOptions> createState() => _InteractiveQuestionOptionsState();
}

class _InteractiveQuestionOptionsState extends State<InteractiveQuestionOptions> {
  final Set<String> _selected = <String>{};

  bool get _isMultiSelect {
    if (widget.allowMultiSelect != null) return widget.allowMultiSelect!;
    // Automatically detect multi-select eligibility (e.g. travel vibes, interests)
    return widget.options.any((o) {
      final low = o.toLowerCase();
      return low.contains('cultur') ||
          low.contains('relax') ||
          low.contains('seral') ||
          low.contains('local') ||
          low.contains('scorc') ||
          low.contains('parch') ||
          low.contains('muse');
    });
  }

  static _ParsedOption _parseOption(String option) {
    var trimmed = option.trim();
    // Strip leading emoji or bullet if present in AI text
    final parts = trimmed.split(' ');
    if (parts.length >= 2 && parts[0].runes.any((r) => r > 1000)) {
      trimmed = trimmed.substring(parts[0].length).trim();
    }

    final low = trimmed.toLowerCase();
    if (low.contains('coppia') || low.contains('due')) return _ParsedOption(icon: Icons.people_outline_rounded, label: trimmed);
    if (low.contains('solo') || low.contains('singol')) return _ParsedOption(icon: Icons.person_outline_rounded, label: trimmed);
    if (low.contains('amici') || low.contains('grupp')) return _ParsedOption(icon: Icons.groups_outlined, label: trimmed);
    if (low.contains('famiglia') || low.contains('bambin')) return _ParsedOption(icon: Icons.family_restroom_rounded, label: trimmed);
    if (low.contains('cultur') || low.contains('muse')) return _ParsedOption(icon: Icons.account_balance_outlined, label: trimmed);
    if (low.contains('relax') || low.contains('parch')) return _ParsedOption(icon: Icons.park_outlined, label: trimmed);
    if (low.contains('seral') || low.contains('local') || low.contains('night')) return _ParsedOption(icon: Icons.nightlife_rounded, label: trimmed);
    if (low.contains('scorc') || low.contains('quartier') || low.contains('foto')) return _ParsedOption(icon: Icons.photo_camera_outlined, label: trimmed);
    if (low.contains('weekend')) return _ParsedOption(icon: Icons.bolt_rounded, label: trimmed);
    if (low.contains('settiman')) return _ParsedOption(icon: Icons.calendar_month_outlined, label: trimmed);
    if (low.contains('ponte') || low.contains('spiaggi') || low.contains('mare')) return _ParsedOption(icon: Icons.beach_access_outlined, label: trimmed);
    if (low.contains('flessibil') || low.contains('vol')) return _ParsedOption(icon: Icons.flight_takeoff_rounded, label: trimmed);
    if (low.contains('hotel') || low.contains('allogg') || low.contains('dormir')) return _ParsedOption(icon: Icons.hotel_outlined, label: trimmed);
    if (low.contains('nord') || low.contains('sud') || low.contains('centro') || low.contains('zona')) return _ParsedOption(icon: Icons.explore_outlined, label: trimmed);
    if (low.contains('salva')) return _ParsedOption(icon: Icons.bookmark_added_outlined, label: trimmed);
    if (low.contains('modifica')) return _ParsedOption(icon: Icons.edit_outlined, label: trimmed);

    return _ParsedOption(icon: Icons.auto_awesome_rounded, label: trimmed);
  }


  void _handleTap(String label) {
    if (_isMultiSelect) {
      setState(() {
        if (_selected.contains(label)) {
          _selected.remove(label);
        } else {
          _selected.add(label);
        }
      });
    } else {
      widget.onSelect(label);
    }
  }

  void _confirmMultiSelect() {
    if (_selected.isEmpty) return;
    final combined = _selected.join(' e ');
    widget.onSelect(combined);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMulti = _isMultiSelect;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMulti)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.checklist_rounded, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Puoi scegliere più opzioni:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.options.map((option) {
              final parsed = _parseOption(option);
              final isSelected = _selected.contains(parsed.label);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleTap(parsed.label),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withValues(alpha: 0.45),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          parsed.icon,
                          size: 15,
                          color: isSelected ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          parsed.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                        if (isMulti && isSelected) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 15,
                            color: colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (isMulti && _selected.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _confirmMultiSelect,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                label: Text(
                  'Invia scelte (${_selected.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ParsedOption {
  const _ParsedOption({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

