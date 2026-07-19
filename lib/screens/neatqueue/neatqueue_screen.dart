import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/neatqueue_service.dart';
import '../../widgets/glass_container.dart';
import '../../theme/app_theme.dart';

class NeatQueueScreen extends StatefulWidget {
  const NeatQueueScreen({super.key});

  @override
  State<NeatQueueScreen> createState() => _NeatQueueScreenState();
}

class _NeatQueueScreenState extends State<NeatQueueScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Let main_layout's VegaBackground shine through
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Text(
                'NEATQUEUE',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryContainer,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
            ),
            
            // TabBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GlassContainer(
                padding: const EdgeInsets.all(4),
                borderRadius: 16,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryContainer.withOpacity(0.5), width: 1),
                  ),
                  labelColor: AppTheme.primaryContainer,
                  unselectedLabelColor: AppTheme.onSurfaceVariant,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Analytics'),
                    Tab(text: 'Queues'),
                    Tab(text: 'Live Matches'),
                    Tab(text: 'History'),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1, end: 0),
            ),
            
            const SizedBox(height: 16),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _AnalyticsTab(),
                  _QueuesTab(),
                  _LiveMatchesTab(),
                  _HistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 1. Analytics Tab
// ----------------------------------------------------------------------
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: NeatQueueService.fetchServerAnalytics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryContainer));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading analytics: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }

        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return const Center(child: Text('No analytics data available.', style: TextStyle(color: AppTheme.onSurfaceVariant)));
        }

        // Example data structure mapping
        final totalMatches = data['total_matches']?.toString() ?? 'N/A';
        final totalPlayers = data['total_players']?.toString() ?? 'N/A';
        final uniquePlayers = data['unique_players']?.toString() ?? 'N/A';

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            _buildStatCard('Total Matches', totalMatches, Icons.games_rounded),
            const SizedBox(height: 12),
            _buildStatCard('Total Queue Entries', totalPlayers, Icons.people_alt_rounded),
            const SizedBox(height: 12),
            _buildStatCard('Unique Players', uniquePlayers, Icons.person_search_rounded),
          ],
        ).animate().fadeIn();
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryContainer, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(color: AppTheme.onBackground, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 2. Queues Tab
// ----------------------------------------------------------------------
class _QueuesTab extends StatelessWidget {
  const _QueuesTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: NeatQueueService.fetchQueues(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryContainer));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading queues: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }

        final queues = snapshot.data ?? [];
        if (queues.isEmpty) {
          return const Center(child: Text('No active queues at the moment.', style: TextStyle(color: AppTheme.onSurfaceVariant)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: queues.length,
          itemBuilder: (context, index) {
            final queue = queues[index];
            final name = queue['name'] ?? 'Unknown Queue';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.primaryContainer.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.people_alt_rounded, color: AppTheme.primaryContainer),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(name, style: const TextStyle(color: AppTheme.onBackground, fontSize: 18, fontWeight: FontWeight.bold)),
                           const SizedBox(height: 4),
                           const Text('Queue Active', style: TextStyle(color: AppTheme.primaryContainer, fontSize: 13)),
                         ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ).animate().fadeIn();
      },
    );
  }
}

// ----------------------------------------------------------------------
// 3. Live Matches Tab
// ----------------------------------------------------------------------
class _LiveMatchesTab extends StatelessWidget {
  const _LiveMatchesTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: NeatQueueService.fetchMatches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryContainer));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading matches: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }

        final matches = snapshot.data ?? [];
        if (matches.isEmpty) {
          return const Center(child: Text('No live matches currently.', style: TextStyle(color: AppTheme.onSurfaceVariant)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            final gameNum = match['game_num']?.toString() ?? '#?';
            final queueName = match['queue_name'] ?? 'Unknown';
            final state = match['state'] ?? 'Ongoing';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.primaryContainer.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.sports_esports_rounded, color: AppTheme.primaryContainer),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Match $gameNum - $queueName', style: const TextStyle(color: AppTheme.onBackground, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Status: $state', style: const TextStyle(color: AppTheme.primaryContainer, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ).animate().fadeIn();
      },
    );
  }
}

// ----------------------------------------------------------------------
// 4. History Tab
// ----------------------------------------------------------------------
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: NeatQueueService.fetchHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryContainer));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading history: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }

        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return const Center(child: Text('No match history found.', style: TextStyle(color: AppTheme.onSurfaceVariant)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final match = history[index];
            final gameNum = match['game_num']?.toString() ?? '#?';
            final queueName = match['game'] ?? match['queue_name'] ?? 'Match';
            
            String winnerText = 'Draw/Cancelled';
            if (match['winner'] != null && match['team_names'] != null) {
              final winnerIndex = match['winner'] as int;
              final teamNames = match['team_names'] as List;
              if (winnerIndex >= 0 && winnerIndex < teamNames.length) {
                winnerText = teamNames[winnerIndex].toString();
              }
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                      child: const Icon(Icons.history_rounded, color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Match $gameNum - $queueName', style: const TextStyle(color: AppTheme.onBackground, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Winner: $winnerText', style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ).animate().fadeIn();
      },
    );
  }
}
