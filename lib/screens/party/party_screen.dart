import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../../providers/voice_party_provider.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/vega_background.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class PartyScreen extends StatefulWidget {
  final String? initialRoomId;

  const PartyScreen({super.key, this.initialRoomId});

  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
  final TextEditingController _joinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If opened via deep link with a room ID, automatically try to join
    if (widget.initialRoomId != null && widget.initialRoomId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<VoicePartyProvider>().joinParty(widget.initialRoomId!);
      });
    }
  }

  @override
  void dispose() {
    _joinController.dispose();
    super.dispose();
  }

  void _createParty() async {
    final roomId = (100000 + Random().nextInt(900000)).toString();
    try {
      await context.read<VoicePartyProvider>().joinParty(roomId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  void _joinParty() async {
    final roomId = _joinController.text.trim();
    if (roomId.isNotEmpty) {
      try {
        await context.read<VoicePartyProvider>().joinParty(roomId);
        _joinController.clear();
        if (mounted) FocusScope.of(context).unfocus();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ));
        }
      }
    }
  }

  void _shareLink(String roomId) {
    Share.share('Join my Vega Coach Voice Party! Tap here to join: vegacoach://party/$roomId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('VOICE LOBBY'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Consumer<VoicePartyProvider>(
        builder: (context, provider, child) {
          if (provider.isJoined) {
            return _buildActiveParty(context, provider);
          }
          return _buildPartySetup(context);
        },
      ),
    );
  }

  Widget _buildPartySetup(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.headphones, size: 80, color: AppTheme.primaryContainer),
          const SizedBox(height: 24),
          Text(
            'Squad Up!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a private voice channel or join your teammates to coordinate in real-time.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: _createParty,
            icon: const Icon(Icons.add),
            label: const Text('CREATE NEW PARTY'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: Theme.of(context).textTheme.labelLarge),
              ),
              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
            ],
          ),
          const SizedBox(height: 32),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _joinController,
                  decoration: const InputDecoration(
                    labelText: 'Party Code',
                    hintText: 'Enter 6-digit code',
                    prefixIcon: Icon(Icons.dialpad),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _joinParty,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('JOIN PARTY'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveParty(BuildContext context, VoicePartyProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'PARTY CODE',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.primaryContainer),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      provider.currentRoomId ?? '',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(letterSpacing: 4),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.ios_share, color: AppTheme.primaryContainer),
                      onPressed: () => _shareLink(provider.currentRoomId ?? ''),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PARTICIPANTS (${provider.remoteUsers.length + 1})', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildParticipantTile(context, 'You', isLocal: true, isMuted: provider.isMuted),
                        ...provider.remoteUsers.map((uid) => _buildParticipantTile(context, 'User $uid', isLocal: false)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                context,
                icon: provider.isMuted ? Icons.mic_off : Icons.mic,
                label: provider.isMuted ? 'Unmute' : 'Mute',
                isActive: provider.isMuted,
                onTap: provider.toggleMute,
              ),
              _buildControlButton(
                context,
                icon: provider.isDeafened ? Icons.headset_off : Icons.headset,
                label: provider.isDeafened ? 'Undeafen' : 'Deafen',
                isActive: provider.isDeafened,
                onTap: provider.toggleDeafen,
              ),
              _buildControlButton(
                context,
                icon: Icons.call_end,
                label: 'Leave',
                isActive: true,
                activeColor: Colors.redAccent,
                onTap: provider.leaveParty,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildParticipantTile(BuildContext context, String name, {bool isLocal = false, bool isMuted = false}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
        child: Icon(Icons.person, color: isLocal ? AppTheme.primaryContainer : Colors.white),
      ),
      title: Text(name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      trailing: isMuted ? const Icon(Icons.mic_off, color: Colors.redAccent, size: 20) : const Icon(Icons.graphic_eq, color: AppTheme.primaryContainer, size: 20),
    );
  }

  Widget _buildControlButton(BuildContext context, {required IconData icon, required String label, required bool isActive, required VoidCallback onTap, Color activeColor = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? activeColor.withValues(alpha: 0.2) : AppTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(color: isActive ? activeColor : Colors.transparent, width: 2),
            ),
            child: Icon(icon, color: isActive ? activeColor : Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: isActive ? activeColor : Colors.white54)),
        ],
      ),
    );
  }
}
