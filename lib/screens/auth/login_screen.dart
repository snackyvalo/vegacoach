import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/vega_background.dart';
import '../../widgets/terms_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _termsAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VegaBackground(
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 48),
                      _buildEmailField(context),
                      const SizedBox(height: 16),
                      _buildPasswordField(context),
                      const SizedBox(height: 16),
                      _buildTermsCheckbox(context),
                      const SizedBox(height: 16),
                      _buildLoginButton(context, auth.isLoading),
                      const SizedBox(height: 32),
                      _buildDivider(context),
                      const SizedBox(height: 32),
                      _buildGoogleButton(context, auth),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => context.push('/signup'),
                        child: Text(
                          "Don't have an account? Sign up",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 128,
          height: 128,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                blurRadius: 24,
                spreadRadius: 8,
              ),
            ],
            image: const DecorationImage(
              image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuAHTihoGcQZ1zF0YkkadbxcFLN9q8SDCNuAvSiPQXA9_TzkzRkwDQRzH-zJHfuKiBWRUGrG7NUfeXObSeMnaHC0FAvsI2rszdRGfNEzyGCow_YhsEBe3CxUGJRlnI8j5HMZYocG5u0n-Lp5ImYHP894uD186DQjAI3Bz1rFCqW-1sYT3B8WZUI3a8aifMff1JD4RzMURQQPxEg1iDgXI3JVSBsuRk94mb3wcKf3ND-gSD5ATTdU8gcFPlAwCc2vsHeclI8'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Text(
          'VEGA',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Access your coaching dashboard',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            'EMAIL',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        TextField(
          controller: _emailController,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'coach@vega.gg',
            prefixIcon: Icon(Icons.mail_outline, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PASSWORD',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              GestureDetector(
                onTap: () async {
                  final email = _emailController.text.trim();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your email to reset password.')),
                    );
                    return;
                  }
                  try {
                    await context.read<AuthProvider>().resetPassword(email);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password reset email sent!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: Text(
                  'Forgot Password?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        TextField(
          controller: _passwordController,
          obscureText: true,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7)),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final email = _emailController.text.trim();
          final password = _passwordController.text;
          if (!_termsAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You must accept the Terms of Service to continue.')),
            );
            return;
          }
          if (email.isEmpty || password.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter both email and password.')),
            );
            return;
          }
          try {
            await context.read<AuthProvider>().signInWithEmail(email, password);
            if (context.mounted) {
              context.go('/');
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Login Failed: $e')),
              );
            }
          }
        },
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('LOG IN'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Theme.of(context).colorScheme.surfaceContainerHigh)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'OR',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Expanded(child: Container(height: 1, color: Theme.of(context).colorScheme.surfaceContainerHigh)),
      ],
    );
  }

  Widget _buildGoogleButton(BuildContext context, AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          if (!_termsAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You must accept the Terms of Service to continue.')),
            );
            return;
          }
          try {
            await auth.signInWithGoogle();
            if (context.mounted) {
              context.go('/');
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Failed: $e')));
            }
          }
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: const BorderSide(color: Colors.transparent),
          textStyle: Theme.of(context).textTheme.bodyLarge,
        ),
        icon: const Icon(Icons.g_mobiledata, size: 28), // Simplified Google icon for now
        label: const Text('Continue with Google'),
      ),
    );
  }

  Widget _buildTermsCheckbox(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: _termsAccepted,
          onChanged: (value) {
            setState(() {
              _termsAccepted = value ?? false;
            });
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const TermsDialog(),
              );
            },
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: 'Terms of Service & Privacy Policy',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
