import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/gradient_logo.dart';
import 'root_shell_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fullNameCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: AuthBackground(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          builder: (context, t, child) {
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 20),
                child: child,
              ),
            );
          },
          child: FrostedCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),
                      const Center(child: GradientLogo()),
                      const SizedBox(height: 18),
                      Center(
                        child: GradientText(
                          'Créer un compte',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rejoignez la communauté SkillShare',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).hintColor),
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _fullNameCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Nom complet', hintText: 'Jean Dupont'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nom complet requis'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            labelText: 'Email', hintText: 'votre@email.com'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Email requis'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Mot de passe', hintText: '••••••••'),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Mot de passe requis';
                          }
                          if (v.length < 8) {
                            return 'Le mot de passe doit contenir au moins 8 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmPasswordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Confirmer le mot de passe',
                            hintText: '••••••••'),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirmation requise';
                          }
                          if (v != _passwordCtrl.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      if (auth.error != null) ...[
                        Text(
                          auth.error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                      ],
                      GradientButton(
                        isLoading: auth.isLoading,
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                if (!(_formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }
                                await context.read<AuthProvider>().register(
                                      email: _emailCtrl.text.trim(),
                                      password: _passwordCtrl.text,
                                      fullName: _fullNameCtrl.text.trim(),
                                    );

                                if (!context.mounted) {
                                  return;
                                }
                                if (context
                                    .read<AuthProvider>()
                                    .isAuthenticated) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Bienvenue dans la communauté !')),
                                  );
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const RootShellScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                        child: const Text("S'inscrire"),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Déjà un compte ? ',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const GradientText('Se connecter'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
