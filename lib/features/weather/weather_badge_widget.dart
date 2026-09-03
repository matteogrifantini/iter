import 'package:flutter/material.dart';

import 'weather_models.dart';

/// Widget presenting weather forecast badge with expandable daily details.
class WeatherBadgeWidget extends StatefulWidget {
  const WeatherBadgeWidget({super.key, required this.report});

  final TripWeatherReport report;

  @override
  State<WeatherBadgeWidget> createState() => _WeatherBadgeWidgetState();
}

class _WeatherBadgeWidgetState extends State<WeatherBadgeWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final r = widget.report;

    final firstDay = r.dailyForecast.isNotEmpty ? r.dailyForecast.first : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (firstDay?.icon == Icons.wb_sunny_rounded)
                        ? Colors.amber.withAlpha(40)
                        : Colors.blue.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    firstDay?.icon ?? Icons.wb_cloudy_rounded,
                    color: (firstDay?.icon == Icons.wb_sunny_rounded)
                        ? Colors.amber[800]
                        : Colors.blue[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            '${r.currentTemp.round()}°C',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            firstDay?.conditionLabel ?? 'Meteo previsto',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.clothingTip,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: _expanded ? 6 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
          if (_expanded && r.dailyForecast.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: r.dailyForecast.map((d) {
                  final weekday = [
                    'Lun',
                    'Mar',
                    'Mer',
                    'Gio',
                    'Ven',
                    'Sab',
                    'Dom',
                  ][d.date.weekday - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Column(
                      children: [
                        Text(
                          weekday,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          d.icon,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${d.tempMax.round()}°',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${d.tempMin.round()}°',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        if (d.precipitationProbability > 20) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.water_drop,
                                size: 8,
                                color: Colors.blue[400],
                              ),
                              Text(
                                '${d.precipitationProbability}%',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
