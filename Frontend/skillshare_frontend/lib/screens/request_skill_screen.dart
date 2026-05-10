import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/skill.dart';
import '../providers/auth_provider.dart';
import '../providers/requests_provider.dart';
import '../providers/skills_provider.dart';
import '../services/profile_service.dart';

class RequestSkillScreen extends StatefulWidget {
  const RequestSkillScreen({super.key});

  @override
  State<RequestSkillScreen> createState() => _RequestSkillScreenState();
}

class _RequestSkillScreenState extends State<RequestSkillScreen> {
  final _profileService = ProfileService();

  int? _myUserId;

  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  String _levelFilter = 'Tous';
  String _categoryFilter = 'Toutes';
  final _messageCtrl = TextEditingController();

  bool _bootstrapped = false;

  static const _categories = <String>[
    'Toutes',
    'Programmation',
    'Design',
    'Marketing',
    'Langue',
    'Musique',
    'Sport',
    'Cuisine',
    'Artisanat',
    'Photographie',
    'Autre',
  ];

  static const _levels = <String>[
    'Tous',
    'BEGINNER',
    'INTERMEDIATE',
    'EXPERT',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    try {
      final me = await _profileService.me();
      if (!mounted) return;
      setState(() {
        _myUserId = me.id;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _myUserId = null;
      });
    }

    await _reloadSkills();
  }

  Future<void> _reloadSkills() async {
    final skillsProvider = context.read<SkillsProvider>();

    final search =
        _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim();
    final level = _levelFilter == 'Tous' ? null : _levelFilter;

    await skillsProvider.load(
      excludeOwnerId: _myUserId,
      search: search,
      level: level,
    );
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _reloadSkills();
    });
  }

  Future<void> _openRequestDialog(Skill skill) async {
    final requests = context.read<RequestsProvider>();

    if (_myUserId != null && skill.ownerId == _myUserId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Vous ne pouvez pas demander votre propre compétence')),
      );
      return;
    }

    final alreadyRequested =
        requests.myRequests.any((r) => r.skillId == skill.id);
    if (alreadyRequested) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vous avez déjà demandé cette compétence')),
      );
      return;
    }

    _messageCtrl.clear();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Demander: ${skill.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Expliquez pourquoi vous souhaitez apprendre cette compétence',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageCtrl,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Votre message (optionnel)',
                  hintText: 'Expliquez vos motivations, vos objectifs... ',
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

    if (ok != true) {
      return;
    }

    if (_myUserId == null) {
      try {
        final me = await _profileService.me();
        if (!mounted) return;
        setState(() {
          _myUserId = me.id;
        });
      } catch (_) {
        // ignore
      }
    }

    if (_myUserId != null && skill.ownerId == _myUserId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Vous ne pouvez pas demander votre propre compétence')),
      );
      return;
    }

    await requests.createRequest(
      skillId: skill.id,
      message:
          _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
    );

    if (!mounted) return;

    final err = requests.error;
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande envoyée avec succès !')),
      );
    }

    await requests.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final skillsProvider = context.watch<SkillsProvider>();

    if (!auth.isAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Veuillez vous connecter.')),
      );
    }

    final skills = skillsProvider.skills;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher une compétence'),
      ),
      body: RefreshIndicator(
        onRefresh: _reloadSkills,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Trouvez et apprenez de nouvelles compétences',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Rechercher une compétence...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _categoryFilter,
                            isExpanded: true,
                            items: _categories
                                .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      c,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _categoryFilter = v ?? 'Toutes';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Filtre catégorie indisponible: le backend ne contient pas encore "category" pour les skills.',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            decoration:
                                const InputDecoration(labelText: 'Catégorie'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _levelFilter,
                            isExpanded: true,
                            items: _levels
                                .map((l) => DropdownMenuItem(
                                      value: l,
                                      child: Text(
                                        l == 'Tous' ? 'Tous' : 'Niveau: $l',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) async {
                              setState(() {
                                _levelFilter = v ?? 'Tous';
                              });
                              await _reloadSkills();
                            },
                            decoration:
                                const InputDecoration(labelText: 'Niveau'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.filter_alt, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${skills.length} compétence(s) trouvée(s)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (skillsProvider.error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        skillsProvider.error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (skillsProvider.isLoading && skills.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (skills.isEmpty)
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 14),
                  child: Column(
                    children: [
                      Icon(Icons.menu_book,
                          size: 54, color: Theme.of(context).hintColor),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune compétence trouvée',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Essayez de modifier vos filtres de recherche',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      )
                    ],
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 980
                      ? 3
                      : constraints.maxWidth >= 620
                          ? 2
                          : 1;
                  const gap = 12.0;
                  final w = (constraints.maxWidth - gap * (cols - 1)) / cols;

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final s in skills)
                        SizedBox(
                          width: w,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            const Color(0xFF4F46E5),
                                        foregroundColor: Colors.white,
                                        child: Text(
                                          s.ownerFullName.isEmpty
                                              ? '?'
                                              : s.ownerFullName
                                                  .trim()
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              s.ownerFullName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if ((s.description ?? '').trim().isNotEmpty)
                                    Text(
                                      s.description!,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Chip(
                                        label: Text(_categoryFilter),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      Chip(
                                        label: Text(s.level),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: () => _openRequestDialog(s),
                                    icon: const Icon(Icons.message),
                                    label: const Text('Demander'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      backgroundColor: const Color(0xFF4F46E5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
