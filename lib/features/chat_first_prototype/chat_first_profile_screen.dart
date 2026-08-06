import 'package:flutter/material.dart';

class ChatFirstProfileScreen extends StatelessWidget {
  const ChatFirstProfileScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onOpenChats,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onOpenChats;

  static const _learned = <String>[
    'Ritmo lento e senza orari fissi',
    'Niente museo dopo il pomeriggio in città',
    'Almeno una tavola di quartiere per viaggio',
    'Preferisci la finestra sul corridoio in treno',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
        children: <Widget>[
          const _ProfileHeader(),
          const SizedBox(height: 24),
          _Card(
            title: 'Aspetto',
            child: SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Chiaro'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Scuro'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('Sistema'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
              ],
              selected: <ThemeMode>{themeMode},
              onSelectionChanged: (selection) =>
                  onThemeChanged(selection.first),
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            title: 'Memoria appresa',
            subtitle:
                'Iter impara dai piani che accetti, non da sondaggi. Qui mostriamo '
                'solo ciò che filtra dalle nostre conversazioni.',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final item in _learned)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            title: 'Privacy',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.lock_outline, size: 20, color: colors.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Per ora Iter è una demo: le conversazioni e i piani restano '
                    'solo sul dispositivo. Niente dati personali lasciano l’app.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onOpenChats,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Vai alle conversazioni'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.primary, width: 2),
          ),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: colors.surfaceContainerHighest,
            child: Icon(Icons.person_outline, size: 30, color: colors.primary),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Viaggiatore',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Preferenze e stile appresi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}