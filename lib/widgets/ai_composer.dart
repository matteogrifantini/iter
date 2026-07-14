import 'package:flutter/material.dart';

class PersistentAiComposer extends StatefulWidget {
  const PersistentAiComposer({
    super.key,
    required this.onSend,
    this.hint = 'Scrivi a Iter',
  });

  final ValueChanged<String> onSend;
  final String hint;

  @override
  State<PersistentAiComposer> createState() => _PersistentAiComposerState();
}

class _PersistentAiComposerState extends State<PersistentAiComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(Icons.auto_awesome, color: colors.primary, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: widget.hint,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 15,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Invia a Iter',
            onPressed: _submit,
            icon: const Icon(Icons.arrow_upward),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
