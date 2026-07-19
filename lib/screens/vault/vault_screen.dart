import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/vega_background.dart';
import '../../widgets/glass_container.dart';
import '../../theme/app_theme.dart';

class LineupModel {
  final String id;
  final String title;
  final String agent;
  final String category;
  final String calloutLocation;
  final String map;
  final String videoUrl;
  bool isFavorite;

  LineupModel({
    required this.id,
    required this.title,
    required this.agent,
    required this.category,
    required this.calloutLocation,
    required this.map,
    required this.videoUrl,
    this.isFavorite = false,
  });
}

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  final List<String> _categories = ['All', 'Smokes', 'Flashes', 'Entry', 'Post-Plant'];
  
  final List<LineupModel> _allLineups = [
    LineupModel(id: '1', title: 'Ultimate Sova Lineups', agent: 'Sova', category: 'Post-Plant', map: 'Ascent', calloutLocation: 'A & B Sites', videoUrl: 'https://www.youtube.com/watch?v=5rE2t38S68o'),
    LineupModel(id: '2', title: 'Top Omen One-Way Smokes', agent: 'Omen', category: 'Smokes', map: 'Ascent', calloutLocation: 'Mid & A Main', videoUrl: 'https://www.youtube.com/watch?v=9g2k6Xm9nKk'),
    LineupModel(id: '3', title: 'Flexinja Omen Attack/Defend', agent: 'Omen', category: 'Smokes', map: 'Ascent', calloutLocation: 'All Map', videoUrl: 'https://www.youtube.com/watch?v=kYJvYc-V3bY'),
    LineupModel(id: '4', title: 'God Arrows 2025', agent: 'Sova', category: 'Entry', map: 'Ascent', calloutLocation: 'Mid Control', videoUrl: 'https://www.youtube.com/watch?v=6-1J5w2yJ8U'),
    LineupModel(id: '5', title: 'Viper A Site Executes', agent: 'Viper', category: 'Post-Plant', map: 'Bind', calloutLocation: 'A Short & Showers', videoUrl: 'https://www.youtube.com/watch?v=1oW_W1QhE7g'),
    LineupModel(id: '6', title: 'KAY/O Flashes for Entry', agent: 'KAY/O', category: 'Flashes', map: 'Bind', calloutLocation: 'B Long', videoUrl: 'https://www.youtube.com/watch?v=r_t9kZt1qE0'),
    LineupModel(id: '7', title: 'Jett Dash Spots', agent: 'Jett', category: 'Entry', map: 'Haven', calloutLocation: 'C Long', videoUrl: 'https://www.youtube.com/watch?v=P9U5uF0R9b4'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('STRATEGY VAULT', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryContainer,
          labelColor: AppTheme.primaryContainer,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'ASCENT'),
            Tab(text: 'BIND'),
            Tab(text: 'HAVEN'),
          ],
        ),
      ),
      body: Column(
          children: [
            _buildStickyHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLineupList('Ascent'),
                  _buildLineupList('Bind'),
                  _buildLineupList('Haven'),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildStickyHeader() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 0,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search callouts, agents...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedCategory = category),
                  selectedColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                  backgroundColor: Colors.black26,
                  side: BorderSide(color: isSelected ? AppTheme.primaryContainer : Colors.transparent),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineupList(String mapName) {
    // Filter lineups
    final filtered = _allLineups.where((l) {
      final matchesSearch = l.title.toLowerCase().contains(_searchQuery.toLowerCase()) || l.agent.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || l.category == _selectedCategory;
      return matchesSearch && matchesCategory && l.map == mapName;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildVideoCard(filtered[index]).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildVideoCard(LineupModel lineup) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: _VideoPlayerPlaceholder(videoUrl: lineup.videoUrl),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                            child: Text(lineup.agent, style: Theme.of(context).textTheme.labelSmall),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.primaryContainer.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text(lineup.category, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.primaryContainer)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(lineup.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(lineup.calloutLocation, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(lineup.isFavorite ? Icons.bookmark : Icons.bookmark_border, color: lineup.isFavorite ? AppTheme.primaryContainer : Colors.grey),
                  onPressed: () {
                    setState(() {
                      lineup.isFavorite = !lineup.isFavorite;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerPlaceholder extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerPlaceholder({required this.videoUrl});

  @override
  State<_VideoPlayerPlaceholder> createState() => _VideoPlayerPlaceholderState();
}

class _VideoPlayerPlaceholderState extends State<_VideoPlayerPlaceholder> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final String videoId = widget.videoUrl.contains('v=') 
        ? widget.videoUrl.split('v=').last.substring(0, 11) 
        : 'dQw4w9WgXcQ';
    
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _controller,
    );
  }
}
