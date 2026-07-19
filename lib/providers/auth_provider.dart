import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '885213017005-sg082r46vqrqd1rp2fn5nuhch2a6ugol.apps.googleusercontent.com',
  );

  User? get currentUser => _auth.currentUser;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      notifyListeners();
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return; // User canceled
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      await _syncUserToFirestore(userCredential.user);
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _syncUserToFirestore(userCredential.user);
    } catch (e) {
      debugPrint('Email Sign In Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUpWithEmail(String name, String email, String password) async {
    _setLoading(true);
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user?.updateDisplayName(name);
      await _syncUserToFirestore(userCredential.user);
    } catch (e) {
      debugPrint('Email Sign Up Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password Reset Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _syncUserToFirestore(User? user) async {
    if (user == null) return;
    
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    
    if (!doc.exists) {
      await docRef.set({
        'displayName': user.displayName ?? 'New Player',
        'email': user.email ?? '',
        'profilePic': user.photoURL ?? '',
        'currentXp': 0,
        'level': 1,
        'unlockedAchievements': <String>[],
        'stats': {
          'kd': 0.0,
          'acs': 0.0,
          'winRate': 0.0,
          'hsPercentage': 0.0,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    _setLoading(true);
    try {
      if (currentUser != null) {
        if (displayName != null) {
          await currentUser!.updateDisplayName(displayName);
        }
        if (photoURL != null) {
          await currentUser!.updatePhotoURL(photoURL);
        }
        await _firestore.collection('users').doc(currentUser!.uid).update({
          if (displayName != null) 'displayName': displayName,
          if (photoURL != null) 'profilePic': photoURL,
        });
        // Reload user to propagate changes
        await currentUser!.reload();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update Profile Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> uploadProfilePicture(dynamic imageFile) async {
    _setLoading(true);
    try {
      if (currentUser == null) return;
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(currentUser!.uid)
          .child('avatar.jpg');
          
      // Upload file
      // Note: we accept dynamic so we can pass dart:io File without importing it here
      await storageRef.putFile(imageFile);
      
      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();
      
      // Update profile
      await updateProfile(photoURL: downloadUrl);
      
    } catch (e) {
      debugPrint('Upload Profile Picture Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    if (currentUser == null) return;
    try {
      _setLoading(true);
      String uid = currentUser!.uid;
      
      // Delete from Firestore
      await _firestore.collection('users').doc(uid).delete();
      
      // Delete Auth
      await currentUser!.delete();
      
      // Also sign out from Google to revoke access
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Delete Account Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
