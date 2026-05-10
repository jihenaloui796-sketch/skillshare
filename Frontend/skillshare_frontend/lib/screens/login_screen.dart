import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/gradient_logo.dart';
import 'register_screen.dart';
import 'root_shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),
                      const Center(child: GradientLogo()),
                      const SizedBox(height: 18),
                      Center(
                        child: GradientText(
                          'SkillShare',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connectez-vous pour échanger vos compétences',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).hintColor),
                      ),
                      const SizedBox(height: 22),
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
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Mot de passe requis'
                            : null,
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
                                await context.read<AuthProvider>().login(
                                      email: _emailCtrl.text.trim(),
                                      password: _passwordCtrl.text,
                                    );

                                if (!context.mounted) {
                                  return;
                                }
                                final err = context.read<AuthProvider>().error;
                                if (err == null) {
                                  _showMessage('Bienvenue !');
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const RootShellScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                        child: const Text('Se connecter'),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Pas encore de compte ? ',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen()),
                                    );
                                  },
                            child:
                                const GradientText('S\'inscrire gratuitement'),
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
