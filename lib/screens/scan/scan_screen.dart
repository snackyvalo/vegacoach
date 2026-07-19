import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_container.dart';
import '../../theme/app_theme.dart';
import '../../widgets/vega_background.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _isScanning = false;
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;
  Map<String, dynamic>? _latestInsights;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut));
    _loadLatestInsights();
  }

  Future<void> _loadLatestInsights() async {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && doc.data()!.containsKey('latestInsights')) {
      setState(() {
        _latestInsights = doc.data()!['latestInsights'];
      });
    }
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndScanImage() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in to scan.')));
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      setState(() {
        _isScanning = true;
      });

      await _processOCR(File(image.path), user.uid);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _processOCR(File image, String uid) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Missing API Key. Please check your .env file.');
    }

    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://vegacoach.com',
        'X-Title': 'Vega Coach',
      },
      body: jsonEncode({
        'model': 'google/gemini-2.5-flash',
        'max_tokens': 1000,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Analyze this scoreboard image. If it is NOT a Valorant match scoreboard, reply EXACTLY with: {"error": "INVALID_IMAGE"}. If it IS a Valorant scoreboard, extract the stats and reply with a JSON object containing: {"stats": {"kd": float, "acs": float, "winRate": float, "hsPercentage": float}, "insights": {"pros": ["pro1", "pro2"], "cons": ["con1", "con2"]}}. DO NOT return any markdown, just raw JSON.'
              },
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to connect to AI service. Code: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'].toString().trim();

    String cleanContent = content;
    if (cleanContent.startsWith('```json')) {
      cleanContent = cleanContent.replaceAll('```json', '').replaceAll('```', '').trim();
    }

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(cleanContent);
    } catch (_) {
      throw Exception('Failed to parse AI response. Try another image.');
    }

    if (parsed.containsKey('error')) {
      if (parsed['error'] == 'INVALID_IMAGE') {
        throw Exception('Invalid Image. Please upload a valid Valorant scoreboard.');
      } else {
        throw Exception(parsed['error']);
      }
    }

    final stats = parsed['stats'];
    final insights = parsed['insights'];

    if (stats == null || insights == null) {
      throw Exception('Incomplete data extracted.');
    }

    final currentDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    int currentXp = 0;
    int currentLevel = 1;
    if (currentDoc.exists && currentDoc.data()!.containsKey('currentXp')) {
        currentXp = currentDoc.data()!['currentXp'];
        currentLevel = currentDoc.data()!['level'] ?? 1;
    }
    
    currentXp += 500; // Add 500 XP for scanning
    if (currentXp >= 1000) {
        currentLevel++;
        currentXp -= 1000;
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'stats': stats,
        'latestInsights': insights,
        'currentXp': currentXp,
        'level': currentLevel,
        'lastScannedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (mounted) {
      setState(() {
        _latestInsights = insights;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scan complete! +500 XP')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('VEGA\'S COACH', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Analyze Match Data', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Upload a valid Valorant scoreboard to extract tactical insights.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              
              // Compact horizontal layout for Dropzone + Reference
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildInteractiveDropzone(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildReferenceBox(),
                  ),
                ],
              ),
              
              if (_latestInsights != null) ...[
                const SizedBox(height: 24),
                _buildInsightsSection(),
              ],
              
              const SizedBox(height: 100), // Bottom padding for dock
            ],
          ),
        ),
    );
  }

  Widget _buildReferenceBox() {
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      borderRadius: 12,
      child: Column(
        children: [
          Text('Example Format', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.primaryContainer)),
          const SizedBox(height: 8),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/reference_stats.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ensure names and stats are clearly visible.',
            style: TextStyle(fontSize: 9, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveDropzone() {
    return GestureDetector(
      onTap: _isScanning ? null : _pickAndScanImage,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isScanning ? _buildScanningState() : _buildDefaultState(),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultState() {
    return Column(
      key: const ValueKey('default'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(Icons.add_photo_alternate, size: 24, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 12),
        Text('UPLOAD', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
      ],
    );
  }

  Widget _buildScanningState() {
    return Column(
      key: const ValueKey('scanning'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            children: [
              _buildReticles(),
              AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: _scanAnimation.value * 70,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary, blurRadius: 4)],
                      ),
                    ),
                  );
                },
              ),
              Center(child: Icon(Icons.sports_esports, size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3)))
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }

  Widget _buildReticles() {
    final color = Theme.of(context).colorScheme.primary.withOpacity(0.6);
    return Stack(
      children: [
        Positioned(top: 0, left: 0, child: Container(width: 8, height: 8, decoration: BoxDecoration(border: Border(top: BorderSide(color: color, width: 2), left: BorderSide(color: color, width: 2))))),
        Positioned(top: 0, right: 0, child: Container(width: 8, height: 8, decoration: BoxDecoration(border: Border(top: BorderSide(color: color, width: 2), right: BorderSide(color: color, width: 2))))),
        Positioned(bottom: 0, left: 0, child: Container(width: 8, height: 8, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: color, width: 2), left: BorderSide(color: color, width: 2))))),
        Positioned(bottom: 0, right: 0, child: Container(width: 8, height: 8, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: color, width: 2), right: BorderSide(color: color, width: 2))))),
      ],
    );
  }

  Widget _buildInsightsSection() {
    final pros = List<String>.from(_latestInsights!['pros'] ?? []);
    final cons = List<String>.from(_latestInsights!['cons'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Match Insights', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (pros.isNotEmpty)
          GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            borderColor: Colors.greenAccent.withOpacity(0.3),
            color: Colors.greenAccent.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
                    const SizedBox(width: 8),
                    Text('Pros', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                ...pros.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('• $p', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                )),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (cons.isNotEmpty)
          GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            borderColor: Colors.redAccent.withOpacity(0.3),
            color: Colors.redAccent.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Text('Areas to Improve', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                ...cons.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('• $c', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                )),
              ],
            ),
          ),
      ],
    );
  }
}
