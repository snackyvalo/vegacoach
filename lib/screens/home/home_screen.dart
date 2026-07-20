import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/vega_background.dart';
import '../../widgets/glass_container.dart';
import '../../theme/app_theme.dart';
import '../../services/neatqueue_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by main_layout or VegaBackground
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('VEGA\'S COACH', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant) : null,
          ),
        ),
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
      body: user == null
            ? const Center(child: Text('Please log in.'))
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.hasData && snapshot.data!.exists 
                      ? snapshot.data!.data() as Map<String, dynamic>
                      : <String, dynamic>{};
                  final stats = data['stats'] as Map<String, dynamic>? ?? {};
                  final unlockedAchievements = data['unlockedAchievements'] as List<dynamic>? ?? [];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 120.0), // Extra bottom padding for floating dock
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTierCard(context, data),
                        const SizedBox(height: 24),
                        _buildScanCTA(context).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, curve: Curves.easeOut),
                        const SizedBox(height: 16),
                        _buildPartyCTA(context).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1, curve: Curves.easeOut),
                        const SizedBox(height: 32),
                        _buildStatsSection(context, stats),
                        const SizedBox(height: 32),
                        _buildAchievementsGrid(context, unlockedAchievements),
                        const SizedBox(height: 32),
                        _buildRecentMatches(context),
                        const SizedBox(height: 32),
                        _buildDailyQuests(context),
                        const SizedBox(height: 32),
                        _buildLeaderboards(context),
                      ],
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildTierCard(BuildContext context, Map<String, dynamic> data) {
    int level = data['level'] ?? 1;
    int currentXp = data['currentXp'] ?? 0;
    double progress = currentXp / 1000.0;
    if (progress > 1.0) progress = 1.0;

    return GlassContainer(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CURRENT RANK', style: Theme.of(context).textTheme.labelLarge),
              Text('TIER $level', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${1000 - currentXp} XP to Tier ${level + 1}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildScanCTA(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.go('/scan'),
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('SCAN NEW MATCH'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPartyCTA(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.push('/party'),
      icon: const Icon(Icons.headset_mic),
      label: const Text('JOIN VOICE LOBBY'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        backgroundColor: AppTheme.surfaceContainerHigh,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, Map<String, dynamic> stats) {
    final kd = stats['kd']?.toString() ?? '0.0';
    final acs = stats['acs']?.toString() ?? '0';
    final winPercentage = stats['winRate']?.toString() ?? '0'; // Changed to winRate
    final hsPercentage = stats['hsPercentage']?.toString() ?? '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PERFORMANCE STATS', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(context, 'K/D Ratio', kd, Icons.stacked_bar_chart),
            _buildStatCard(context, 'ACS', acs, Icons.score),
            _buildStatCard(context, 'Win Rate', '$winPercentage%', Icons.stars),
            _buildStatCard(context, 'Headshot', '$hsPercentage%', Icons.my_location),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return GlassContainer(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8), size: 28),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack).fadeIn(delay: 200.ms);
  }

  Widget _buildAchievementsGrid(BuildContext context, List<dynamic> unlocked) {
    final allAchievements = [
      {'id': 'first_scan', 'name': 'First Scan', 'icon': Icons.qr_code_scanner},
      {'id': 'top_fragger', 'name': 'Top Fragger', 'icon': Icons.sports_esports},
      {'id': 'clutch_king', 'name': 'Clutch King', 'icon': Icons.bolt},
      {'id': 'grinder', 'name': 'Grinder', 'icon': Icons.fitness_center},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ACHIEVEMENTS', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: allAchievements.length,
          itemBuilder: (context, index) {
            final ach = allAchievements[index];
            final isUnlocked = unlocked.contains(ach['id']);
            
            return Tooltip(
              message: ach['name'] as String,
              child: GlassContainer(
                padding: const EdgeInsets.all(8),
                color: isUnlocked ? AppTheme.primaryContainer.withValues(alpha: 0.1) : Colors.transparent,
                borderColor: isUnlocked ? AppTheme.primaryContainer.withValues(alpha: 0.5) : Colors.white12,
                child: Center(
                  child: Icon(
                    ach['icon'] as IconData,
                    color: isUnlocked ? AppTheme.primaryContainer : Colors.grey.shade700,
                    size: 28,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildRecentMatches(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECENT MATCHES', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              _buildMatchTile(context, 'Ascent', 'Victory', '13 - 11', Colors.greenAccent),
              const Divider(color: Colors.white12, height: 1),
              _buildMatchTile(context, 'Bind', 'Defeat', '10 - 13', Colors.redAccent),
              const Divider(color: Colors.white12, height: 1),
              _buildMatchTile(context, 'Haven', 'Victory', '13 - 5', Colors.greenAccent),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad),
      ],
    );
  }

  Widget _buildMatchTile(BuildContext context, String map, String result, String score, Color resultColor) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: resultColor.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(result == 'Victory' ? Icons.check_circle_outline : Icons.close, color: resultColor, size: 20),
      ),
      title: Text(map, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text(result, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: resultColor)),
      trailing: Text(score, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      onTap: () {},
    );
  }

  Widget _buildDailyQuests(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DAILY QUESTS', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.primaryContainer.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.stars, color: AppTheme.primaryContainer, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upload 2 Match Screenshots', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('+500 XP Reward', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryContainer)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad),
      ],
    );
  }

  Widget _buildLeaderboards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('GLOBAL LEADERBOARDS', style: Theme.of(context).textTheme.labelLarge),
            Text('NEATQUEUE MMR', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.primaryContainer)),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: NeatQueueService.leaderboardStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text('Error loading leaderboard.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.redAccent)),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text('No leaderboard data yet.', style: Theme.of(context).textTheme.bodyMedium),
                ),
              );
            }

            // Only take top 5
            final docs = snapshot.data!.take(5).toList();

            return GlassContainer(
              padding: const EdgeInsets.all(0),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                itemBuilder: (context, index) {
                  final data = docs[index];
                  final name = (data['name'] ?? 'Unknown').toString().trim();
                  final stats = data['stats'] as Map<String, dynamic>? ?? {};
                  final mmrRaw = stats['mmr'] ?? 0;
                  final mmr = (mmrRaw is num) ? mmrRaw.toInt().toString() : mmrRaw.toString();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                      child: Text('#${index + 1}', style: const TextStyle(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(
                      name.replaceAll('\n', ' '), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis, 
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)
                    ),
                    trailing: Text('$mmr MMR', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primaryContainer)),
                  );
                },
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 700.ms);
  }
}
