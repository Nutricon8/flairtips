import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flairtips/models/user.dart';
import 'package:flairtips/utils/api_service.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  User? get user => _user;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  Future<void> loadUser() async {
    final savedUser = await getSavedUser(); // comes from api_service.dart
    if (savedUser != null) {
      _user = savedUser;
      notifyListeners();
      // Also check current subscription status in background
      _checkCurrentUserSubscription();
    }
  }

  Future<void> _checkCurrentUserSubscription() async {
    try {
      await updateSubscriptionStatus();
    } catch (e) {
      print('Background subscription check failed: $e');
      // Silently fail - user can still use the app
    }
  }

  Future<void> logout() async {
    _user = null;
    await logoutUser(); // centralized cleanup from api_service.dart
    notifyListeners();
  }

  // In UserProvider class, add this method:
  Future<void> updateSubscriptionStatus() async {
    try {
      final status = await checkSubscriptionStatus();

      if (status['status'] == 1 && _user != null) {
        final data = status['data'];
        final isSubscribed = data['is_subscribed'] == 1;

        // Create a new user with updated subscription status
        final updatedUser = User(
          id: _user!.id,
          email: _user!.email,
          firstName: _user!.firstName,
          lastName: _user!.lastName,
          isPremium: isSubscribed, // Update this field
          avatar: _user!.avatar,
        );

        _user = updatedUser;

        // Also update in storage
        await storage.write(
          key: 'user',
          value: jsonEncode(updatedUser.toJson()),
        );

        notifyListeners();
        print('Subscription status updated: $isSubscribed');
      }
    } catch (e) {
      print('Error updating subscription: $e');
    }
  }
}
