import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/skill.dart';
import '../providers/ratings_provider.dart';
import 'rating_badge.dart';

class SkillCard extends StatelessWidget {
  final Skill skill;

  const SkillCard({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    final ratings = context.watch<RatingsProvider>();
    final stats = ratings.skillStats(skill.id);

    if (stats == null && !ratings.isSkillLoading(skill.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.read<RatingsProvider>().ensureSkill(skill.id);
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    skill.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (stats != null) ...[
                  const SizedBox(width: 10),
                  RatingBadge(average: stats.average, count: stats.count),
                ],
              ],
            ),
            const SizedBox(height: 6),
            if ((skill.description ?? '').isNotEmpty)
              Text(
                skill.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(skill.level)),
                Chip(label: Text('by ${skill.ownerFullName}')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
