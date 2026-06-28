import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/widgets/lumora_button.dart';
import '../../shared/widgets/lumora_card.dart';
import 'auth_controller.dart';

class AuthPlaceholderScreen extends ConsumerStatefulWidget {
  const AuthPlaceholderScreen({super.key});

  @override
  ConsumerState<AuthPlaceholderScreen> createState() => _AuthPlaceholderScreenState();
}

class _AuthPlaceholderScreenState extends ConsumerState<AuthPlaceholderScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegister = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LumoraSpacing.lg),
          children: [
            const SizedBox(height: LumoraSpacing.xl),
            Text(
              'Welcome to Lumora',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: LumoraSpacing.sm),
            Text(
              'Begin with a calm account, then return to one meaningful focus at a time.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: LumoraSpacing.lg),
            LumoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isRegister) ...[
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: LumoraSpacing.md),
                  ],
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: LumoraSpacing.md),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: LumoraSpacing.md),
                    Text(
                      auth.errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: LumoraSpacing.lg),
                  LumoraButton(
                    label: _isRegister ? 'Create account' : 'Log in',
                    onPressed: auth.isLoading ? null : _submit,
                  ),
                  TextButton(
                    onPressed: auth.isLoading ? null : () => setState(() => _isRegister = !_isRegister),
                    child: Text(_isRegister ? 'Use existing account' : 'Create a new account'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final controller = ref.read(authControllerProvider.notifier);
    if (_isRegister) {
      await controller.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      return;
    }
    await controller.login(email: _emailController.text, password: _passwordController.text);
  }
}
