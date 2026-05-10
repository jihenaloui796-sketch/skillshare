import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/requests_provider.dart';
import '../providers/skills_provider.dart';
import '../widgets/rating_badge.dart';
import '../models/user_profile.dart';
import '../providers/messages_provider.dart';
import '../providers/ratings_provider.dart';
import '../services/profile_service.dart';
import '../widgets/skill_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _profileService = ProfileService();

  UserProfile? _me;
  bool _bootstrapped = false;

  int? _selectedSkillId;
  final _requestMessageCtrl = TextEditingController();

  @override
  void dispose() {
    _requestMessageCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    try {
      final me = await _profileService.me();
      if (!mounted) return;
      setState(() {
        _me = me;
      });

      await Future.wait([
        context.read<SkillsProvider>().load(excludeOwnerId: me.id),
        context.read<RequestsProvider>().loadAll(),
      ]);
    } catch (_) {
      if (!mounted) return;
      await Future.wait([
        context.read<SkillsProvider>().load(),
        context.read<RequestsProvider>().loadAll(),
      ]);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'OPEN':
        return 'En attente';
      case 'ACCEPTED':
        return 'Acceptée';
      case 'CANCELLED':
        return 'Refusée';
      case 'COMPLETED':
        return 'Terminée';
      default:
        return status;
    }
  }

  Color _statusBg(BuildContext context, String status) {
    switch (status) {
      case 'OPEN':
        return const Color(0xFFFFF4CC);
      case 'ACCEPTED':
        return const Color(0xFFDFF7E7);
      case 'CANCELLED':
        return const Color(0xFFFCE0E0);
      case 'COMPLETED':
        return const Color(0xFFDCEBFF);
      default:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  Color _statusFg(BuildContext context, String status) {
    switch (status) {
      case 'OPEN':
        return const Color(0xFF8B6B00);
      case 'ACCEPTED':
        return const Color(0xFF1B6B38);
      case 'CANCELLED':
        return const Color(0xFF8C1B1B);
      case 'COMPLETED':
        return const Color(0xFF1B3A8C);
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'OPEN':
        return Icons.schedule;
      case 'ACCEPTED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      case 'COMPLETED':
        return Icons.star;
      default:
        return Icons.info;
    }
  }

  Future<void> _openRequestDialog({required int skillId}) async {
    final requestsProvider = context.read<RequestsProvider>();
    final already =
        requestsProvider.myRequests.any((r) => r.skillId == skillId);
    if (already) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vous avez déjà demandé cette compétence')),
      );
      return;
    }

    setState(() {
      _selectedSkillId = skillId;
    });
    _requestMessageCtrl.clear();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Demander une compétence'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ajoutez un message pour expliquer votre demande (optionnel)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _requestMessageCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Pourquoi voulez-vous apprendre cette compétence ?',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Envoyer la demande'),
            ),
          ],
        );
      },
    );

    if (ok != true || _selectedSkillId == null) {
      setState(() {
        _selectedSkillId = null;
      });
      return;
    }

    await requestsProvider.createRequest(
      skillId: _selectedSkillId!,
      message: _requestMessageCtrl.text.trim().isEmpty
          ? null
          : _requestMessageCtrl.text.trim(),
    );
    if (!mounted) return;

    final err = requestsProvider.error;
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ Demande envoyée !')),
      );
    }

    setState(() {
      _selectedSkillId = null;
    });
    await requestsProvider.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final skills = context.watch<SkillsProvider>();
    final requests = context.watch<RequestsProvider>();

    final meName = _me?.fullName ?? 'Utilisateur';

    final requestCountBySkillId = <int, int>{};
    for (final r in [...requests.myRequests, ...requests.incomingRequests]) {
      requestCountBySkillId[r.skillId] =
          (requestCountBySkillId[r.skillId] ?? 0) + 1;
    }
    final trending = [...skills.skills]..sort((a, b) =>
        (requestCountBySkillId[b.id] ?? 0)
            .compareTo(requestCountBySkillId[a.id] ?? 0));
    final trendingTop = trending
        .where((s) => (requestCountBySkillId[s.id] ?? 0) > 0)
        .take(3)
        .toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final skillsProvider = context.read<SkillsProvider>();
          final requestsProvider = context.read<RequestsProvider>();
          await _bootstrap();
          if (!mounted) return;
          await Future.wait([
            skillsProvider.load(excludeOwnerId: _me?.id),
            requestsProvider.loadAll(),
          ]);
        },
        child: DefaultTabController(
          length: 3,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF7C3AED),
                      Color(0xFFD946EF),
                      Color(0xFFEC4899),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Bonjour, $meName !',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.auto_awesome,
                                      color: Color(0xFFFDE047)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Prêt à partager vos talents et découvrir de nouvelles compétences ?',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Colors.white.withOpacity(0.9)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _StatPill(
                          icon: Icons.book,
                          label: 'Compétences',
                          value: '${skills.skills.length}',
                        ),
                        _StatPill(
                          icon: Icons.outbox,
                          label: 'Mes demandes',
                          value: '${requests.myRequests.length}',
                        ),
                        _StatPill(
                          icon: Icons.trending_up,
                          label: 'En cours',
                          value:
                              '${requests.incomingRequests.where((r) => r.status == 'ACCEPTED').length}',
                        ),
                      ],
                    ),
                    if (skills.error != null || requests.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        (skills.error ?? requests.error) ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (trendingTop.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 8),
                    Text(
                      'Compétences tendances',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: trendingTop.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final s = trendingTop[i];
                      final c = requestCountBySkillId[s.id] ?? 0;
                      return _TrendingSkillCard(
                        skillId: s.id,
                        title: s.name,
                        subtitle: s.ownerFullName,
                        level: s.level,
                        count: c,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7C3AED).withOpacity(0.12),
                      const Color(0xFFD946EF).withOpacity(0.12),
                    ],
                  ),
                ),
                child: TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFD946EF)],
                    ),
                  ),
                  dividerColor: Colors.transparent,
                  tabs: [
                    const Tab(text: 'Compétences'),
                    Tab(text: 'Mes demandes (${requests.myRequests.length})'),
                    Tab(text: 'Reçues (${requests.incomingRequests.length})'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: TabBarView(
                  children: [
                    _SkillsTab(
                      isLoading: skills.isLoading,
                      skills: skills.skills,
                      onRequest: (id) => _openRequestDialog(skillId: id),
                    ),
                    _MyRequestsTab(
                      isLoading: requests.isLoading,
                      requests: requests.myRequests,
                      statusLabel: _statusLabel,
                      statusIcon: _statusIcon,
                      statusBg: (s) => _statusBg(context, s),
                      statusFg: (s) => _statusFg(context, s),
                    ),
                    _IncomingRequestsTab(
                      isLoading: requests.isLoading,
                      requests: requests.incomingRequests,
                      statusLabel: _statusLabel,
                      statusIcon: _statusIcon,
                      statusBg: (s) => _statusBg(context, s),
                      statusFg: (s) => _statusFg(context, s),
                      onAccept: (id) => context
                          .read<RequestsProvider>()
                          .updateStatus(id: id, status: 'ACCEPTED'),
                      onReject: (id) => context
                          .read<RequestsProvider>()
                          .updateStatus(id: id, status: 'CANCELLED'),
                      onComplete: (id) async {
                        await context
                            .read<RequestsProvider>()
                            .updateStatus(id: id, status: 'COMPLETED');
                        if (!context.mounted) return;
                        await context.read<MessagesProvider>().refreshMe();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.white.withOpacity(0.9)),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _TrendingSkillCard extends StatelessWidget {
  final int skillId;
  final String title;
  final String subtitle;
  final String level;
  final int count;

  const _TrendingSkillCard({
    required this.skillId,
    required this.title,
    required this.subtitle,
    required this.level,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final ratings = context.watch<RatingsProvider>();
    final stats = ratings.skillStats(skillId);

    if (stats == null && !ratings.isSkillLoading(skillId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.read<RatingsProvider>().ensureSkill(skillId);
      });
    }

    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            const Color(0xFF7C3AED).withOpacity(0.06),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (stats != null) ...[
                const SizedBox(width: 8),
                RatingBadge(average: stats.average, count: stats.count),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(level),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Chip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, size: 16),
                    const SizedBox(width: 4),
                    Text('$count'),
                  ],
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillsTab extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> skills;
  final void Function(int id) onRequest;

  const _SkillsTab({
    required this.isLoading,
    required this.skills,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && skills.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (skills.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.book, size: 54, color: Theme.of(context).hintColor),
              const SizedBox(height: 10),
              Text(
                'Aucune compétence disponible',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Soyez le premier à partager vos connaissances !',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 14),
      itemCount: skills.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final s = skills[i] as dynamic;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkillCard(skill: s),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => onRequest((s.id as num).toInt()),
              icon: const Icon(Icons.message),
              label: const Text('Demander'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: const Color(0xFF7C3AED),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MyRequestsTab extends StatelessWidget {
  final bool isLoading;
  final List requests;
  final String Function(String status) statusLabel;
  final IconData Function(String status) statusIcon;
  final Color Function(String status) statusBg;
  final Color Function(String status) statusFg;

  const _MyRequestsTab({
    required this.isLoading,
    required this.requests,
    required this.statusLabel,
    required this.statusIcon,
    required this.statusBg,
    required this.statusFg,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (requests.isEmpty) {
      return Center(
        child: Text(
          'Vous n\'avez fait aucune demande',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 14),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = requests[i] as dynamic;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      (r.skillName ?? '') as String,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBg((r.status ?? '') as String),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon((r.status ?? '') as String),
                            size: 16,
                            color: statusFg((r.status ?? '') as String),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel((r.status ?? '') as String),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: statusFg((r.status ?? '') as String),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (r.message != null &&
                    (r.message as String).trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '"${r.message}"',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IncomingRequestsTab extends StatelessWidget {
  final bool isLoading;
  final List requests;
  final String Function(String status) statusLabel;
  final IconData Function(String status) statusIcon;
  final Color Function(String status) statusBg;
  final Color Function(String status) statusFg;
  final Future<void> Function(int id) onAccept;
  final Future<void> Function(int id) onReject;
  final Future<void> Function(int id) onComplete;

  const _IncomingRequestsTab({
    required this.isLoading,
    required this.requests,
    required this.statusLabel,
    required this.statusIcon,
    required this.statusBg,
    required this.statusFg,
    required this.onAccept,
    required this.onReject,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (requests.isEmpty) {
      return Center(
        child: Text(
          'Aucune demande reçue',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 14),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = requests[i] as dynamic;
        final status = (r.status ?? '') as String;
        final id = (r.id as num).toInt();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (r.requesterFullName ?? '') as String,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'veut apprendre: ${(r.skillName ?? '') as String}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (r.message != null &&
                    (r.message as String).trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '"${r.message}"',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBg(status),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon(status),
                              size: 16, color: statusFg(status)),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel(status),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: statusFg(status),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (status == 'OPEN') ...[
                      FilledButton.icon(
                        onPressed: () => onAccept(id),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Accepter'),
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => onReject(id),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Refuser'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626)),
                      ),
                    ],
                    if (status == 'ACCEPTED')
                      FilledButton.icon(
                        onPressed: () => onComplete(id),
                        icon: const Icon(Icons.star),
                        label: const Text('Terminer'),
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
