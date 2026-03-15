import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_list_item.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  static const _tips = [
    (
      emoji: '🤖',
      title: 'De AI Coach',
      body:
          'Stel vragen over je training, herstel of race-strategie. De coach gebruikt je profiel en trainingsdata als context.',
    ),
    (
      emoji: '📅',
      title: 'Adaptief schema',
      body:
          'Je schema past zich automatisch aan na elke sessie. Bij pijn of een zware training verlaagt de app de belasting de komende weken.',
    ),
    (
      emoji: '📈',
      title: '10% opbouwritme',
      body:
          'Je weekkilometrage stijgt nooit meer dan 10% per week. Dit is de meest bewezen methode om blessures te voorkomen.',
    ),
    (
      emoji: '⚠️',
      title: 'Herstelwaarschuwingen',
      body:
          'Bij aanhoudende pijn of een lage gevoel-score geeft de app een automatisch advies en past het schema aan.',
    ),
    (
      emoji: '😴',
      title: 'Slaap als trainingstool',
      body:
          'Slaap is wanneer je lichaam sterker wordt. Zorg voor 7–9 uur per nacht in de zwaarste trainingsweken.',
    ),
    (
      emoji: '🥾',
      title: 'Trail & wandelstrategie voor ultra\'s',
      body:
          'Bij ultra\'s is wandelen geen falen — het is tactiek. Hike de steile stukken, ren de vlakken.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tips & uitleg')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          ..._tips.asMap().entries.map((e) => AnimatedListItem(
            index: e.key,
            child: _TipCard(
              emoji: e.value.emoji,
              title: e.value.title,
              body:  e.value.body,
            ),
          )),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  const _TipCard({required this.emoji, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(body,
                      style: Theme.of(context).textTheme.bodyMedium,
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
