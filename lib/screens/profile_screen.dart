import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onAvailability,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onAvailability;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      key: const PageStorageKey('profile'),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: Text(
                'M',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Matteo',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'Iter impara solo dalle scelte che confermi.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 42),
        Text(
          'Il tuo modo di viaggiare',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            Chip(label: Text('Camminare senza fretta')),
            Chip(label: Text('Treni')),
            Chip(label: Text('Cene spontanee')),
            Chip(label: Text('Mare fuori stagione')),
          ],
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'La modifica dei gusti arriverà nel prossimo passaggio.',
                ),
              ),
            );
          },
          icon: const Icon(Icons.tune),
          label: const Text('Modifica ciò che Iter ricorda'),
        ),
        const SizedBox(height: 34),
        Text('Aspetto', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Iter parte chiara. La tua scelta resta salvata su questo dispositivo.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_outlined),
              label: Text('Chiaro'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_outlined),
              label: Text('Scuro'),
            ),
          ],
          selected: <ThemeMode>{themeMode},
          onSelectionChanged: (selection) => onThemeChanged(selection.first),
        ),
        const SizedBox(height: 34),
        Text('Disponibilità', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        ListTile(
          contentPadding: EdgeInsets.zero,
          minTileHeight: 64,
          leading: Icon(Icons.calendar_month_outlined, color: colors.primary),
          title: const Text('Giorni liberi e turni'),
          subtitle: const Text('Per ora aggiungi solo le date che scegli tu.'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: onAvailability,
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          minTileHeight: 64,
          leading: Icon(Icons.shield_outlined, color: colors.primary),
          title: const Text('Privacy e memoria'),
          subtitle: const Text(
            'Nessun documento o dato sensibile nel prototipo.',
          ),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (context) => const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Text(
                  'Il prototipo usa dati locali. Quando collegheremo Supabase, ogni viaggio resterà protetto dal relativo account.',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
