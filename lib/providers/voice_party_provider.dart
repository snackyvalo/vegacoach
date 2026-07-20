import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VoicePartyProvider extends ChangeNotifier {
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isDeafened = false;
  String? _currentRoomId;
  List<String> _remoteUsers = [];

  bool get isJoined => _isJoined;
  bool get isMuted => _isMuted;
  bool get isDeafened => _isDeafened;
  String? get currentRoomId => _currentRoomId;
  List<String> get remoteUsers => _remoteUsers;

  Future<void> initEngine() async {
    final appIdStr = dotenv.env['ZEGO_APP_ID'] ?? '0';
    final appId = int.tryParse(appIdStr) ?? 0;
    final appSign = dotenv.env['ZEGO_APP_SIGN'] ?? '';
    
    if (appId == 0 || appSign.isEmpty) {
      debugPrint('ZEGO_APP_ID or ZEGO_APP_SIGN is missing in .env');
      throw Exception('Please add ZEGO_APP_ID and ZEGO_APP_SIGN to your .env file to use Voice Chat.');
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      debugPrint('Microphone permission denied');
      return;
    }

    ZegoEngineProfile profile = ZegoEngineProfile(
      appId == 0 ? 123456789 : appId, // mock for UI if missing
      ZegoScenario.HighQualityChatroom,
      appSign: appSign.isEmpty ? 'mock_sign' : appSign,
    );

    await ZegoExpressEngine.createEngineWithProfile(profile);

    ZegoExpressEngine.onRoomUserUpdate = (String roomID, ZegoUpdateType updateType, List<ZegoUser> userList) {
      if (updateType == ZegoUpdateType.Add) {
        for (var user in userList) {
          if (!_remoteUsers.contains(user.userID)) {
            _remoteUsers.add(user.userID);
          }
        }
      } else {
        for (var user in userList) {
          _remoteUsers.remove(user.userID);
        }
      }
      notifyListeners();
    };

    ZegoExpressEngine.onRoomStateUpdate = (String roomID, ZegoRoomState state, int errorCode, Map<String, dynamic> extendedData) {
      if (state == ZegoRoomState.Connected) {
        _isJoined = true;
      } else if (state == ZegoRoomState.Disconnected) {
        _isJoined = false;
        _remoteUsers.clear();
        _currentRoomId = null;
      }
      notifyListeners();
    };
  }

  Future<void> joinParty(String roomId) async {
    await initEngine();

    ZegoUser user = ZegoUser.id('user_${DateTime.now().millisecondsSinceEpoch}');
    await ZegoExpressEngine.instance.loginRoom(roomId, user);
    await ZegoExpressEngine.instance.startPublishingStream('stream_${user.userID}');
    
    _currentRoomId = roomId;
    notifyListeners();
  }

  Future<void> leaveParty() async {
    await ZegoExpressEngine.instance.stopPublishingStream();
    if (_currentRoomId != null) {
      await ZegoExpressEngine.instance.logoutRoom(_currentRoomId!);
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    ZegoExpressEngine.instance.muteMicrophone(_isMuted);
    notifyListeners();
  }

  void toggleDeafen() {
    _isDeafened = !_isDeafened;
    ZegoExpressEngine.instance.muteSpeaker(_isDeafened);
    notifyListeners();
  }

  @override
  void dispose() {
    ZegoExpressEngine.destroyEngine();
    super.dispose();
  }
}
