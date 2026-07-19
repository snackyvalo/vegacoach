import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_container.dart';
import '../../theme/app_theme.dart';
import '../../widgets/vega_background.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? imageUrl;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, this.imageUrl, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      imageUrl: map['imageUrl'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class AiService {
  String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  Future<String> getCoachResponse(List<ChatMessage> history, String? base64Image) async {
    try {
      final messagesPayload = [];
      
      messagesPayload.add({
        'role': 'system',
        'content': 'You are Vega, an elite, professional esports coach exclusively for Valorant Mobile. You are highly analytical, tactical, and encouraging. Give concise, actionable, and professionally structured advice to help players improve. Format your responses with clear paragraphs or bullet points. DO NOT cut off mid-sentence. If an image is provided, carefully verify that it is a Valorant match scoreboard or Valorant gameplay screenshot. If it is NOT related to Valorant, you MUST strictly reply with: "I can only analyze Valorant match data or gameplay screenshots. Please upload a valid image." and refuse to answer the question.'
      });

      // Add last 5 messages for context
      final recentHistory = history.length > 5 ? history.sublist(history.length - 5) : history;
      for (var i = 0; i < recentHistory.length; i++) {
        final msg = recentHistory[i];
        if (i == recentHistory.length - 1 && msg.isUser && base64Image != null) {
          // Last user message with image
          messagesPayload.add({
            'role': 'user',
            'content': [
              {'type': 'text', 'text': msg.text},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
              }
            ]
          });
        } else {
          messagesPayload.add({
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.text
          });
        }
      }

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://vegacoach.com',
          'X-Title': 'Vega Coach',
        },
        body: jsonEncode({
          'model': 'google/gemini-2.5-flash',
          'max_tokens': 2500,
          'messages': messagesPayload,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "Sorry, I'm having trouble analyzing the data right now. (Error ${response.statusCode})";
      }
    } catch (e) {
      return "Network error. Please check your connection.";
    }
  }
}

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final AiService _aiService = AiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chats')
        .orderBy('timestamp')
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _messages = snapshot.docs.map((doc) => ChatMessage.fromMap(doc.data())).toList();
      });
      _scrollToBottom();
    } else {
      setState(() {
        _messages = [
          ChatMessage(text: "Hello! I am Vega, your elite esports coach. How can I help you improve today?", isUser: false, timestamp: DateTime.now()),
        ];
      });
      _saveMessageToFirestore(_messages.first);
    }
  }

  Future<void> _saveMessageToFirestore(ChatMessage msg) async {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chats')
        .add(msg.toMap());
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    File? imageToSend = _selectedImage;
    String? imageUrl;
    String? base64Image;

    setState(() {
      _isLoading = true;
      _controller.clear();
      _selectedImage = null;
    });

    try {
      final uid = context.read<AuthProvider>().currentUser?.uid;

      if (imageToSend != null) {
        // Read base64 for API
        final bytes = await imageToSend.readAsBytes();
        base64Image = base64Encode(bytes);

        // Upload to storage for history UI
        if (uid != null) {
          final ref = FirebaseStorage.instance.ref().child('chat_images/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
          await ref.putFile(imageToSend);
          imageUrl = await ref.getDownloadURL();
        }
      }

      final userMsg = ChatMessage(text: text, isUser: true, imageUrl: imageUrl, timestamp: DateTime.now());
      setState(() {
        _messages.add(userMsg);
      });
      _saveMessageToFirestore(userMsg);
      _scrollToBottom();

      final responseText = await _aiService.getCoachResponse(_messages, base64Image);
      
      if (mounted) {
        final coachMsg = ChatMessage(text: responseText, isUser: false, timestamp: DateTime.now());
        setState(() {
          _messages.add(coachMsg);
        });
        _saveMessageToFirestore(coachMsg);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to get coach response.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('VEGA ACADEMY')),
      body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildChatBubble(msg);
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            _buildQuickPrompts(),
            _buildMessageInput(),
          ],
        ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: GlassContainer(
          margin: const EdgeInsets.only(bottom: 12.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          color: msg.isUser 
              ? AppTheme.primaryContainer.withValues(alpha: 0.15) 
              : AppTheme.surfaceContainer.withValues(alpha: 0.5),
          borderColor: msg.isUser 
              ? AppTheme.primaryContainer.withValues(alpha: 0.5)
              : Colors.white12,
          borderRadius: 16.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (msg.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(msg.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
              if (msg.text.isNotEmpty)
                MarkdownBody(
                  data: msg.text,
                  styleSheet: MarkdownStyleSheet(
                    p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: msg.isUser ? Theme.of(context).colorScheme.primary : Colors.white,
                    ),
                    strong: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: msg.isUser ? Theme.of(context).colorScheme.primary : AppTheme.primaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (!msg.isUser)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.flag_outlined, size: 16, color: Colors.grey),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message reported to moderators.')),
                      );
                    },
                    tooltip: 'Report inappropriate response',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildQuickPrompts() {
    final prompts = [
      "Analyze my last match",
      "How do I improve my crosshair placement?",
      "Best agents for Ascent?",
      "How to entry frag?",
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            backgroundColor: AppTheme.surfaceContainer.withValues(alpha: 0.5),
            side: BorderSide(color: AppTheme.primaryContainer.withValues(alpha: 0.3)),
            labelStyle: const TextStyle(color: AppTheme.primaryContainer, fontSize: 12),
            label: Text(prompts[index]),
            onPressed: () {
              _controller.text = prompts[index];
              _sendMessage();
            },
          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1, curve: Curves.easeOut);
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return GlassContainer(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 90),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
      child: Column(
        children: [
          if (_selectedImage != null)
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, height: 80, width: 80, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImage = null),
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.image, color: Theme.of(context).colorScheme.primary),
                onPressed: _pickImage,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Ask Vega or attach a screenshot...',
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).scaffoldBackgroundColor),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'AI-generated content may be inaccurate or inappropriate.',
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
