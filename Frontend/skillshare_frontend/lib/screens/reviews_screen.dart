import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/request_item.dart';
import '../models/review.dart';
import '../providers/reviews_provider.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  bool _bootstrapped = false;

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
    await context.read<ReviewsProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReviewsProvider>();
    final avg = p.averageReceivedRating;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Évaluations'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Donner (${p.completedRequests.length})'),
              Tab(text: 'Mes avis (${p.myReviews.length})'),
              Tab(text: 'Reçus (${p.receivedReviews.length})'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: p.isLoading
                  ? null
                  : () => context.read<ReviewsProvider>().load(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Rafraîchir',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => context.read<ReviewsProvider>().load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                'Gérez vos avis et consultez vos évaluations',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (p.error != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      p.error!,
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (p.receivedReviews.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEFF6FF), Color(0xFFE0E7FF)],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            avg.toStringAsFixed(1),
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF4F46E5),
                                ),
                          ),
                          const SizedBox(height: 8),
                          StarRating(rating: avg.round(), readonly: true),
                          const SizedBox(height: 8),
                          Text(
                            '${p.receivedReviews.length} avis reçu(s)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: TabBarView(
                  children: [
                    _GiveTab(
                      isLoading: p.isLoading,
                      requests: p.completedRequests,
                      hasReviewed: p.hasReviewedRequest,
                      onCreate: (req) => _openCreateDialog(req),
                    ),
                    _MyReviewsTab(
                      isLoading: p.isLoading,
                      reviews: p.myReviews,
                      onEdit: (r) => _openEditDialog(r),
                      onDelete: (r) => _confirmDelete(r),
                    ),
                    _ReceivedTab(
                      isLoading: p.isLoading,
                      reviews: p.receivedReviews,
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

  Future<void> _openCreateDialog(RequestItem req) async {
    final provider = context.read<ReviewsProvider>();

    int rating = 5;
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Laisser un avis'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Note'),
                    const SizedBox(height: 8),
                    StarRating(
                      rating: rating,
                      onRate: (v) => setLocal(() => rating = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ctrl,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Votre avis (optionnel)',
                        hintText: 'Décrivez votre expérience...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Publier'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) {
      ctrl.dispose();
      return;
    }

    final success = await provider.createReview(
      requestId: req.id,
      rating: rating,
      comment: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
    );

    if (!mounted) {
      ctrl.dispose();
      return;
    }

    ctrl.dispose();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avis ajouté !')),
      );
      await provider.load();
    }
  }

  Future<void> _openEditDialog(Review review) async {
    final provider = context.read<ReviewsProvider>();

    int rating = review.rating;
    final ctrl = TextEditingController(text: review.comment ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Modifier votre avis'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Note'),
                    const SizedBox(height: 8),
                    StarRating(
                      rating: rating,
                      onRate: (v) => setLocal(() => rating = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ctrl,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Votre avis (optionnel)',
                        hintText: 'Décrivez votre expérience...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Mettre à jour'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) {
      ctrl.dispose();
      return;
    }

    final success = await provider.updateReview(
      id: review.id,
      rating: rating,
      comment: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
    );

    if (!mounted) {
      ctrl.dispose();
      return;
    }

    ctrl.dispose();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avis mis à jour !')),
      );
      await provider.load();
    }
  }

  Future<void> _confirmDelete(Review review) async {
    final provider = context.read<ReviewsProvider>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Supprimer cet avis ?'),
          content: const Text('Êtes-vous sûr de vouloir supprimer cet avis ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final success = await provider.deleteReview(id: review.id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avis supprimé')),
      );
      await provider.load();
    }
  }
}

class StarRating extends StatelessWidget {
  final int rating;
  final bool readonly;
  final void Function(int value)? onRate;

  const StarRating({
    super.key,
    required this.rating,
    this.onRate,
    this.readonly = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = const Color(0xFFF59E0B);
    final inactive = Theme.of(context).hintColor;

    return Wrap(
      spacing: 2,
      children: [
        for (int i = 1; i <= 5; i++)
          InkWell(
            onTap: readonly ? null : () => onRate?.call(i),
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                i <= rating ? Icons.star : Icons.star_border,
                size: 26,
                color: i <= rating ? active : inactive,
              ),
            ),
          ),
      ],
    );
  }
}

class _GiveTab extends StatelessWidget {
  final bool isLoading;
  final List<RequestItem> requests;
  final bool Function(int requestId) hasReviewed;
  final void Function(RequestItem req) onCreate;

  const _GiveTab({
    required this.isLoading,
    required this.requests,
    required this.hasReviewed,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 44),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 54, color: Theme.of(context).hintColor),
              const SizedBox(height: 12),
              Text(
                'Aucune session terminée à évaluer',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = requests[i];
        final reviewed = hasReviewed(r.id);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  child: Text(
                    r.skillName.trim().isEmpty
                        ? '?'
                        : r.skillName.trim().substring(0, 1).toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.skillName,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Terminé le ${r.createdAt.toLocal().toString().split(' ').first}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: reviewed ? null : () => onCreate(r),
                  icon: const Icon(Icons.star),
                  label: Text(reviewed ? 'Déjà évalué' : 'Évaluer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MyReviewsTab extends StatelessWidget {
  final bool isLoading;
  final List<Review> reviews;
  final void Function(Review r) onEdit;
  final void Function(Review r) onDelete;

  const _MyReviewsTab({
    required this.isLoading,
    required this.reviews,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reviews.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 44),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.message, size: 54, color: Theme.of(context).hintColor),
              const SizedBox(height: 12),
              Text(
                "Vous n'avez laissé aucun avis",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = reviews[i];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  child: Text(r.reviewerFullName.isEmpty
                      ? '?'
                      : r.reviewerFullName.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StarRating(rating: r.rating, readonly: true),
                      const SizedBox(height: 4),
                      if ((r.comment ?? '').trim().isNotEmpty)
                        Text(
                          '"${r.comment}"',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        r.createdAt.toLocal().toString().split(' ').first,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onEdit(r),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Modifier',
                ),
                IconButton(
                  onPressed: () => onDelete(r),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReceivedTab extends StatelessWidget {
  final bool isLoading;
  final List<Review> reviews;

  const _ReceivedTab({
    required this.isLoading,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reviews.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 44),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 54, color: Theme.of(context).hintColor),
              const SizedBox(height: 12),
              Text(
                "Aucun avis reçu pour le moment",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = reviews[i];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF6B7280),
                  foregroundColor: Colors.white,
                  child: Text(r.reviewerFullName.isEmpty
                      ? '?'
                      : r.reviewerFullName.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.reviewerFullName,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      StarRating(rating: r.rating, readonly: true),
                      const SizedBox(height: 6),
                      if ((r.comment ?? '').trim().isNotEmpty)
                        Text(
                          '"${r.comment}"',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        r.createdAt.toLocal().toString().split(' ').first,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
