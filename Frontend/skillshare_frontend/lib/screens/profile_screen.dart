import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/ratings_provider.dart';
import '../providers/reviews_provider.dart';
import '../providers/requests_provider.dart';
import '../providers/skills_provider.dart';
import '../services/profile_service.dart';
import '../config/api_config.dart';

import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  final _picker = ImagePicker();

  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveError;

  int? _myUserId;
  bool _bootstrapped = false;

  UserProfile? _me;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      final updated =
          await _profileService.uploadAvatar(file: File(picked.path));
      if (!mounted) return;
      setState(() {
        _me = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil mise à jour !')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saveError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    final skillsProvider = context.read<SkillsProvider>();
    final requestsProvider = context.read<RequestsProvider>();
    final reviewsProvider = context.read<ReviewsProvider>();

    try {
      final me = await _profileService.me();
      if (!mounted) return;

      setState(() {
        _me = me;
        _myUserId = me.id;
        _nameCtrl.text = me.fullName;
        _bioCtrl.text = me.bio ?? '';
      });

      await skillsProvider.load();
      await requestsProvider.loadAll();
      await reviewsProvider.load();

      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final updated = await _profileService.update(
        fullName: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _me = updated;
        _nameCtrl.text = updated.fullName;
        _bioCtrl.text = updated.bio ?? '';
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour !')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saveError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _saveError = null;
    });
    _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final skillsProvider = context.watch<SkillsProvider>();
    final requestsProvider = context.watch<RequestsProvider>();
    final reviewsProvider = context.watch<ReviewsProvider>();
    final ratingsProvider = context.watch<RatingsProvider>();

    final myId = _myUserId;

    final ratingStats = myId == null ? null : ratingsProvider.userStats(myId);
    if (myId != null &&
        ratingStats == null &&
        !ratingsProvider.isUserLoading(myId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.read<RatingsProvider>().ensureUser(myId);
      });
    }

    final mySkills = myId == null
        ? const []
        : skillsProvider.skills.where((s) => s.ownerId == myId).toList();

    final totalSkills = mySkills.length;
    final totalRequests = requestsProvider.myRequests.length;
    final avgRating =
        ratingStats?.average ?? reviewsProvider.averageReceivedRating;
    final totalReviews =
        ratingStats?.count ?? reviewsProvider.receivedReviews.length;

    return RefreshIndicator(
      onRefresh: () async {
        _bootstrapped = false;
        await _bootstrap();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Mon profil',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (!_isEditing)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                )
              else
                Row(
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : _cancelEdit,
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 6),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Enregistrer'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Gérez vos informations personnelles',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          _StatsGrid(
            totalSkills: totalSkills,
            totalRequests: totalRequests,
            averageRating: avgRating,
            totalReviews: totalReviews,
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            backgroundImage: (_me?.avatarUrl != null &&
                                    _me!.avatarUrl!.trim().isNotEmpty)
                                ? NetworkImage(
                                    '${ApiConfig.baseUrl()}${_me!.avatarUrl}',
                                  )
                                : null,
                            child: (_me?.avatarUrl != null &&
                                    _me!.avatarUrl!.trim().isNotEmpty)
                                ? null
                                : Text(
                                    _nameCtrl.text.trim().isEmpty
                                        ? '?'
                                        : _nameCtrl.text
                                            .trim()
                                            .substring(0, 1)
                                            .toUpperCase(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22),
                                  ),
                          ),
                          if (_isEditing)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: InkWell(
                                onTap: _isSaving ? null : _pickAndUploadAvatar,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withOpacity(0.35),
                                    ),
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 18),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _isEditing
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _nameCtrl,
                                    decoration: const InputDecoration(
                                        labelText: 'Nom complet'),
                                  ),
                                  const SizedBox(height: 10),
                                  const TextField(
                                    enabled: false,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      helperText:
                                          "L'email ne peut pas être modifié",
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _nameCtrl.text,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    ' ',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_saveError != null) ...[
                    Text(
                      _saveError!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    'Bio',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  if (_isEditing)
                    TextField(
                      controller: _bioCtrl,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText:
                            'Parlez de vous, vos intérêts, vos objectifs...',
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _bioCtrl.text.trim().isEmpty
                            ? 'Aucune bio ajoutée'
                            : _bioCtrl.text,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).hintColor),
                      ),
                    ),
                  if (_isSaving) ...[
                    const SizedBox(height: 14),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Mes compétences (${mySkills.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Les compétences que vous partagez avec la communauté',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 12),
                  if (skillsProvider.isLoading && mySkills.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (mySkills.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book,
                              size: 54, color: Theme.of(context).hintColor),
                          const SizedBox(height: 10),
                          Text(
                            "Vous n'avez ajouté aucune compétence",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Theme.of(context).hintColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cols = constraints.maxWidth >= 900 ? 2 : 1;
                        const gap = 12.0;
                        final w =
                            (constraints.maxWidth - gap * (cols - 1)) / cols;

                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final s in mySkills)
                              SizedBox(
                                width: w,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Theme.of(context)
                                            .dividerColor
                                            .withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        s.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        (s.description ?? '').trim().isEmpty
                                            ? '—'
                                            : s.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: Theme.of(context)
                                                    .hintColor),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _Chip(
                                            label: 'Level: ${s.level}',
                                            bg: _levelColorBg(s.level),
                                            fg: _levelColorFg(s.level),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Compte',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Déconnecté.')),
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Déconnexion'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _levelColorBg(String level) {
    switch (level) {
      case 'BEGINNER':
        return const Color(0xFFDCFCE7);
      case 'INTERMEDIATE':
        return const Color(0xFFFEF9C3);
      case 'EXPERT':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  static Color _levelColorFg(String level) {
    switch (level) {
      case 'BEGINNER':
        return const Color(0xFF166534);
      case 'INTERMEDIATE':
        return const Color(0xFF92400E);
      case 'EXPERT':
        return const Color(0xFF991B1B);
      default:
        return const Color(0xFF374151);
    }
  }
}

class _StatsGrid extends StatelessWidget {
  final int totalSkills;
  final int totalRequests;
  final double averageRating;
  final int totalReviews;

  const _StatsGrid({
    required this.totalSkills,
    required this.totalRequests,
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        const gap = 12.0;
        final w = (constraints.maxWidth - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _StatCard(
                width: w,
                icon: Icons.menu_book,
                iconBg: const Color(0xFFE0E7FF),
                iconFg: const Color(0xFF4F46E5),
                value: '$totalSkills',
                label: 'Compétences'),
            _StatCard(
                width: w,
                icon: Icons.message,
                iconBg: const Color(0xFFDBEAFE),
                iconFg: const Color(0xFF2563EB),
                value: '$totalRequests',
                label: 'Demandes'),
            _StatCard(
                width: w,
                icon: Icons.star,
                iconBg: const Color(0xFFFEF9C3),
                iconFg: const Color(0xFFCA8A04),
                value: averageRating == 0
                    ? '0.0'
                    : averageRating.toStringAsFixed(1),
                label: 'Note moyenne'),
            _StatCard(
                width: w,
                icon: Icons.person,
                iconBg: const Color(0xFFDCFCE7),
                iconFg: const Color(0xFF16A34A),
                value: '$totalReviews',
                label: 'Avis reçus'),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String value;
  final String label;

  const _StatCard({
    required this.width,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                    BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconFg),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).hintColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Chip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}
