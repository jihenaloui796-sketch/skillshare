import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/messages_provider.dart';
import '../providers/skills_provider.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({super.key});

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _level = 'BEGINNER';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SkillsProvider>().loadMine();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skills = context.watch<SkillsProvider>();
    final mySkills = skills.mySkills;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ajouter une compétence',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Nouvelle compétence',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            prefixIcon: Icon(Icons.auto_awesome),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Le nom est obligatoire'
                              : null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Icons.subject),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _level,
                          decoration: const InputDecoration(
                            labelText: 'Niveau',
                            prefixIcon: Icon(Icons.trending_up),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'BEGINNER', child: Text('Débutant')),
                            DropdownMenuItem(
                                value: 'INTERMEDIATE',
                                child: Text('Intermédiaire')),
                            DropdownMenuItem(
                                value: 'ADVANCED', child: Text('Avancé')),
                          ],
                          onChanged: skills.isLoading
                              ? null
                              : (v) {
                                  if (v == null) return;
                                  setState(() => _level = v);
                                },
                        ),
                        const SizedBox(height: 16),
                        if (skills.error != null) ...[
                          Text(
                            skills.error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                          ),
                          const SizedBox(height: 12),
                        ],
                        FilledButton.icon(
                          onPressed: skills.isLoading
                              ? null
                              : () async {
                                  if (!(_formKey.currentState?.validate() ??
                                      false)) return;
                                  await context.read<SkillsProvider>().addSkill(
                                        name: _nameCtrl.text.trim(),
                                        description:
                                            _descCtrl.text.trim().isEmpty
                                                ? null
                                                : _descCtrl.text.trim(),
                                        level: _level,
                                      );
                                  if (context.mounted &&
                                      context.read<SkillsProvider>().error ==
                                          null) {
                                    await context
                                        .read<MessagesProvider>()
                                        .refreshMe();
                                    _nameCtrl.clear();
                                    _descCtrl.clear();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Compétence ajoutée !')),
                                    );
                                  }
                                },
                          icon: skills.isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Mes compétences',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: skills.isLoading
                        ? null
                        : () => context.read<SkillsProvider>().loadMine(),
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Rafraîchir',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (skills.isLoading && mySkills.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (mySkills.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Tu n\'as pas encore ajouté de compétences.'),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mySkills.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = mySkills[i];

                    String levelLabel;
                    Color chipColor;
                    if (s.level == 'BEGINNER') {
                      levelLabel = 'Débutant';
                      chipColor = const Color(0xFF10B981);
                    } else if (s.level == 'INTERMEDIATE') {
                      levelLabel = 'Intermédiaire';
                      chipColor = const Color(0xFF6366F1);
                    } else {
                      levelLabel = 'Avancé';
                      chipColor = const Color(0xFFEC4899);
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      tileColor: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                          ),
                        ),
                        child: const Icon(Icons.school,
                            color: Colors.white, size: 20),
                      ),
                      title: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: chipColor.withOpacity(0.12),
                                  border: Border.all(
                                      color: chipColor.withOpacity(0.35)),
                                ),
                                child: Text(
                                  levelLabel,
                                  style: TextStyle(
                                    color: chipColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (s.description != null &&
                              s.description!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              s.description!.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ]
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
