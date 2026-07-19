import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'dart:io';
import '../../widgets/vega_background.dart';
import '../../widgets/terms_dialog.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('VEGA\'S COACH', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('0 VP', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
          ),
          const SizedBox(width: 12),
          Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            final user = auth.currentUser;
            if (user == null) {
              return const Center(child: Text('Not logged in.'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    _buildIdentitySection(context, user),
                    const SizedBox(height: 24),
                    _buildSettingsList(context),
                    const SizedBox(height: 32),
                    
                    if (auth.isLoading)
                      const CircularProgressIndicator()
                    else
                      _buildActions(context, auth),
                  ],
                ),
              ),
            );
          },
        ),
    );
  }

  Widget _buildIdentitySection(BuildContext context, user) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    blurRadius: 20,
                  )
                ],
                image: user.photoURL != null 
                    ? DecorationImage(image: NetworkImage(user.photoURL!), fit: BoxFit.cover)
                    : null,
              ),
              child: user.photoURL == null 
                  ? Icon(Icons.person, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null && context.mounted) {
                    try {
                      final auth = context.read<AuthProvider>();
                      await auth.uploadProfilePicture(File(pickedFile.path));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated successfully!')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update picture: $e')));
                      }
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                  ),
                  child: Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              (user.displayName ?? 'COMMANDER_V').toUpperCase(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showEditNameDialog(context),
              child: Icon(Icons.edit, size: 20, color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'PRO TIER • MEMBER SINCE 2023',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Future<void> _showEditNameDialog(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final controller = TextEditingController(text: auth.currentUser?.displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != auth.currentUser?.displayName) {
      try {
        await auth.updateProfile(displayName: newName);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update name: $e')));
        }
      }
    }
  }



  Widget _buildSettingsList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingsItem(context, 'App Version', Icons.info_outline, trailing: Text('V 2.4.1 (BETA)', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          const Divider(height: 1, color: Colors.white10),
          _buildSettingsItem(
            context, 
            'Terms & Privacy Policy', 
            Icons.policy_outlined, 
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const TermsDialog(),
              );
            },
          ),
          const Divider(height: 1, color: Colors.white10),
          _buildSettingsItem(context, 'Contact Support', Icons.support_agent_outlined, trailing: const Icon(Icons.chevron_right, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, String title, IconData icon, {Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyLarge)),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            await auth.signOut();
            if (context.mounted) context.go('/login');
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
          child: Text('LOG OUT', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18)),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) {
                String confirmText = '';
                return StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      title: const Text('Delete Account?'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('This will permanently delete your account and all associated stats. This action cannot be undone. Type "DELETE" to confirm.'),
                          const SizedBox(height: 16),
                          TextField(
                            onChanged: (val) => setState(() => confirmText = val),
                            decoration: const InputDecoration(
                              hintText: 'DELETE',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                        TextButton(
                          onPressed: confirmText == 'DELETE' ? () => Navigator.pop(context, true) : null,
                          child: Text('DELETE', style: TextStyle(color: confirmText == 'DELETE' ? Colors.redAccent : Colors.grey)),
                        ),
                      ],
                    );
                  },
                );
              },
            );
            if (confirm == true) {
              try {
                await auth.deleteAccount();
                if (context.mounted) context.go('/login');
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
              }
            }
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            side: const BorderSide(color: Colors.redAccent),
            foregroundColor: Colors.redAccent,
          ),
          child: const Text('DELETE ACCOUNT & DATA', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
