import 'package:flutter/material.dart';

/// Barra di inserimento messaggi e scelte rapide per la chat di organizzazione.
class OrganizationMessageComposer extends StatefulWidget {
  const OrganizationMessageComposer({
    super.key,
    required this.onSend,
    this.quickChips = const <String>[],
    this.onChipSelected,
    this.placeholder = 'Scrivi una risposta o preferenza...',
    this.enabled = true,
  });

  final ValueChanged<String> onSend;
  final List<String> quickChips;
  final ValueChanged<String>? onChipSelected;
  final String placeholder;
  final bool enabled;

  @override
  State<OrganizationMessageComposer> createState() =>
      _OrganizationMessageComposerState();
}

class _OrganizationMessageComposerState
    extends State<OrganizationMessageComposer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.quickChips.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: widget.quickChips.map((chip) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(chip),
                        onPressed: widget.enabled
                            ? () {
                                if (widget.onChipSelected != null) {
                                  widget.onChipSelected!(chip);
                                } else {
                                  widget.onSend(chip);
                                }
                              }
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: widget.enabled,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.arrow_upward_rounded),
                  onPressed: widget.enabled ? _handleSend : null,
                  tooltip: 'Invia',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
