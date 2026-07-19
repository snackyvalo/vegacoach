import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/vega_background.dart';
import '../../widgets/glass_container.dart';
import '../../theme/app_theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _hasPremium = false;

  void _startTrial() {
    setState(() {
      _hasPremium = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Beta Trial Activated! Welcome to Vega Elite.'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        action: SnackBarAction(label: 'OK', textColor: Theme.of(context).colorScheme.onPrimary, onPressed: (){}),
      ),
    );
  }

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
      body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBetaWarning(context),
                const SizedBox(height: 24),
                _buildServiceCard(
                  context: context,
                  title: 'Account Services',
                  description: 'Rank evaluation, MMR fixing, and account security auditing.',
                  price: '\$45.00',
                  icon: Icons.shield_outlined,
                  prefix: 'STARTING AT',
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad),
                const SizedBox(height: 16),
                _buildServiceCard(
                  context: context,
                  title: 'Premium Coaching',
                  description: '1-on-1 live session, VOD review, and personalized training plan.',
                  price: '\$80.00',
                  icon: Icons.sports_esports_outlined,
                  prefix: 'PER SESSION',
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad),
                const SizedBox(height: 16),
                _buildServiceCard(
                  context: context,
                  title: 'V-Points Bundle',
                  description: 'Purchase ecosystem currency for internal transactions and perks.',
                  price: '\$10.00',
                  icon: Icons.diamond_outlined,
                  prefix: '1000 VP',
                  isPopular: true,
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildBetaWarning(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Ecosystem Services', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('BETA', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text('Purchases will be verified manually via WhatsApp', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          color: Colors.redAccent.withOpacity(0.05),
          borderColor: Colors.redAccent.withOpacity(0.3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline, color: Colors.redAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BETA PHASE', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.redAccent)),
                    const SizedBox(height: 4),
                    Text(
                      'The shop is currently in a closed beta. Tap any button to activate a mock trial.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).shimmer(duration: 1000.ms, color: Colors.redAccent.withOpacity(0.2)),
      ],
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required String title,
    required String description,
    required String price,
    required IconData icon,
    required String prefix,
    bool isPopular = false,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderColor: isPopular ? AppTheme.primaryContainer.withOpacity(0.8) : null,
      color: isPopular ? AppTheme.primaryContainer.withOpacity(0.05) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: Theme.of(context).textTheme.headlineSmall),
                        if (isPopular) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('POPULAR', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prefix, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  Text(price, style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _hasPremium ? null : _startTrial,
                icon: Icon(_hasPremium ? Icons.check : Icons.hourglass_empty, size: 16),
                label: Text(_hasPremium ? 'ACTIVE' : 'TEST TRIAL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.background,
                  foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
