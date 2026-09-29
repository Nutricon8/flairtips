import 'dart:convert';
import 'package:flairtips/models/tip.dart';
import 'package:flairtips/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

final storage = FlutterSecureStorage();
const String baseUrl = 'https://api.flairtips.com/api/v1';

Future<void> saveLoginData(Map<String, dynamic> json) async {
  final data = json['data'];
  final user = data['user'];
  final accessToken = data['access_token'];
  final refreshToken = json['token_string'];
  final subscriptionActive = json['subscription_active'];

  if (user == null || accessToken == null || refreshToken == null) {
    throw Exception('Invalid login response: Missing required fields');
  }

  // Merge subscription_active into user map
  final mergedUser = {...user, 'subscription_active': subscriptionActive};

  await storage.write(key: 'access_token', value: accessToken);
  await storage.write(key: 'refresh_token', value: refreshToken);
  await storage.write(key: 'user', value: jsonEncode(mergedUser));
}

Future<void> loginUser(String email, String password) async {
  final requestBody = {
    "request": {
      "request_id": DateTime.now().millisecondsSinceEpoch,
      "data": {"identity": email, "password": password},
    },
  };

  final response = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestBody),
  );

  final responseData = jsonDecode(response.body);
  if (response.statusCode == 200 && responseData['status'] == 1) {
    await saveLoginData(responseData);
  } else {
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['message'] ?? 'Login failed');
  }
}

Future<Map<String, dynamic>> registerUser({
  required String fullName,
  required String email,
  required String password,
}) async {
  final url = Uri.parse('$baseUrl/auth/register');

  final requestBody = {
    "request": {
      "request_id": DateTime.now().millisecondsSinceEpoch,
      "data": {"full_name": fullName, "email": email, "password": password},
    },
  };

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestBody),
  );

  final responseData = jsonDecode(response.body);

  if (response.statusCode == 200 && responseData['status'] == 1) {
    return responseData;
  } else {
    throw Exception(responseData['message'] ?? 'Registration failed');
  }
}

Future<User?> getSavedUser() async {
  final userJson = await storage.read(key: 'user');
  if (userJson != null) {
    final decoded = jsonDecode(userJson);
    return User.fromJson(decoded);
  }
  return null;
}

Future<void> logoutUser() async {
  await storage.deleteAll();
}

Future<bool> isLoggedIn() async {
  final token = await storage.read(key: 'access_token');
  return token != null;
}

Future<List<Tip>> getTips(bool isPremiumScreen, String date, int page) async {
  final requestId = DateTime.now().millisecondsSinceEpoch;

  String? token;
  if (isPremiumScreen) {
    token = await storage.read(key: 'access_token');
    if (token == null) throw Exception('User not logged in');
  }

  final requestBody = jsonEncode({
    "request": {
      "request_id": requestId,
      "data": {"date": date, "type": "all", "page": page, "country": ""},
    },
  });

  final headers = {
    'Content-Type': 'application/json',
    if (isPremiumScreen && token != null) 'Authorization': 'Bearer $token',
  };

  final response = await http.post(
    Uri.parse(
      isPremiumScreen
          ? '$baseUrl/fixtures/fixtures'
          : '$baseUrl/fixtures/get_fixtures',
    ),
    headers: headers,
    body: requestBody,
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['status'] == 1) {
      if (body['data'] == null) {
        return [];
      }
      final Map<String, dynamic> data = body['data'];
      final List<Tip> tips = [];

      for (final countryEntry in data.entries) {
        final country = countryEntry.key;
        final Map<String, dynamic> leagues = countryEntry.value;

        for (final leagueEntry in leagues.entries) {
          final leagueName = leagueEntry.key;
          final List<dynamic> matches = leagueEntry.value;

          for (final match in matches) {
            // CORRECTED: Map API field names to your model field names
            tips.add(
              Tip.fromJson({
                'id': match['match_id'],
                'home':
                    match['home_team'] ??
                    '', // Changed from 'home' to 'home_team'
                'away':
                    match['away_team'] ??
                    '', // Changed from 'away' to 'away_team'
                'homeImage':
                    match['home_team_logo'], // Changed from 'homeImage' to 'home_team_logo'
                'awayImage':
                    match['away_team_logo'], // Changed from 'awayImage' to 'away_team_logo'
                'date': match['date'],
                'fixtureDate': match['fixture_date'],
                'time': match['fixture_time'],
                'homeOdd':
                    match['home_team_odd'], // Changed from 'homeOdd' to 'home_team_odd'
                'drawOdd': match['draw_odd'],
                'awayOdd':
                    match['away_team_odd'], // Changed from 'awayOdd' to 'away_team_odd'
                'tip': match['tip'],
                'bestTip': match['best_tip'] ?? '-',
                'homeScore': match['home_score'] ?? '',
                'awayScore': match['away_score'] ?? '',
                'confidence': match['confidence'] ?? '',
                'isPlayed': match['is_played'] ?? 0,
                'isScoreUpdated': match['is_score_updated'] ?? 0,
                'playing': match['playing'] ?? 'UNKNOWN',
                'country': match['country'] ?? country,
                'countryId': match['country_id'] ?? '',
                'leagueLogo': match['league_logo'] ?? '',
                'leagueName':
                    match['league_name'] ??
                    leagueName, // Changed from 'leagueName' to 'league_name'
              }, premium: isPremiumScreen),
            );
          }
        }
      }

      return tips;
    } else if (body['status'] == 0) {
      throw Exception(body['message'] ?? 'There are no pending events');
    } else {
      if (isPremiumScreen && body['status'] == 403) {
        throw UnauthorizedException(body['message'] ?? 'Unauthorized access');
      }
      throw Exception(body['message'] ?? 'Failed to fetch tips');
    }
  } else {
    throw Exception('Failed to fetch tips');
  }
}

/*
Future<List<Tip>> getTips(bool isPremiumScreen, String date, int page) async {
  final requestId = DateTime.now().millisecondsSinceEpoch;

  String? token;
  if (isPremiumScreen) {
    token = await storage.read(key: 'access_token');
    if (token == null) throw Exception('User not logged in');
  }

  final requestBody = jsonEncode({
    "request": {
      "request_id": requestId,
      "data": {"date": date, "type": "all", "page": page, "country": ""},
    },
  });

  final headers = {
    'Content-Type': 'application/json',
    if (isPremiumScreen && token != null) 'Authorization': 'Bearer $token',
  };

  final response = await http.post(
    Uri.parse(
      isPremiumScreen
          ? '$baseUrl/fixtures/fixtures'
          : '$baseUrl/fixtures/get_fixtures',
    ),
    headers: headers,
    body: requestBody,
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['status'] == 1) {
      if (body['data'] == null) {
        return [];
      }
      final Map<String, dynamic> data = body['data'];
      final List<Tip> tips = [];

      for (final countryEntry in data.entries) {
        final country = countryEntry.key;
        final Map<String, dynamic> leagues = countryEntry.value;

        for (final leagueEntry in leagues.entries) {
          final leagueName = leagueEntry.key;
          final List<dynamic> matches = leagueEntry.value;

          for (final match in matches) {
            // Get the ACTUAL league name and country ID from the match data
            final actualLeagueName =
                match['league_name']?.toString() ?? leagueName;
            final actualCountry = match['country']?.toString() ?? country;
            final countryId = match['country_id']?.toString() ?? '';

            // Use the ACTUAL data from the match, not the outer loop
            tips.add(
              Tip.fromJson({
                'id': match['match_id'],
                'home': match['home_team'] ?? '',  // Changed from 'home' to 'home_team'
                'away': match['away_team'] ?? '',  // Changed from 'away' to 'away_team'
                'homeImage': match['home_team_logo'],  // Changed from 'homeImage' to 'home_team_logo'
                'awayImage': match['away_team_logo'],  // Changed from 'awayImage' to 'away_team_logo'
                'date': match['date'],
                'fixtureDate': match['fixture_date'],
                'time': match['fixture_time'],
                'homeOdd': match['home_team_odd'],  // Changed from 'homeOdd' to 'home_team_odd'
                'drawOdd': match['draw_odd'],
                'awayOdd': match['away_team_odd'],  // Changed from 'awayOdd' to 'away_team_odd'
                'tip': match['tip'],
                'bestTip': match['best_tip'] ?? '-',
                'homeScore': match['home_score'] ?? '',
                'awayScore': match['away_score'] ?? '',
                'confidence': match['confidence'] ?? '',
                'isPlayed': match['is_played'] ?? 0,
                'isScoreUpdated': match['is_score_updated'] ?? 0,
                'playing': match['playing'] ?? 'UNKNOWN',
                'country': match['country'] ?? country,
                'countryId': match['country_id'] ?? '',
                'leagueLogo': match['league_logo'] ?? '',
                'leagueName': match['league_name'] ?? leagueName,  // Changed from 'leagueName' to 'league_name'
              }, premium: isPremiumScreen),
            );
          }
        }
      }

      return tips;
    } else if (body['status'] == 0) {
      throw Exception(body['message'] ?? 'There are no pending events');
    } else {
      if (isPremiumScreen && body['status'] == 403) {
        throw UnauthorizedException(body['message'] ?? 'Unauthorized access');
      }
      throw Exception(body['message'] ?? 'Failed to fetch tips');
    }
  } else {
    throw Exception('Failed to fetch tips');
  }
}

Future<List<Tip>> getTips(bool isPremiumScreen, String date, int page) async {
  final requestId = DateTime.now().millisecondsSinceEpoch;

  String? token;
  if (isPremiumScreen) {
    token = await storage.read(key: 'access_token');
    if (token == null) throw Exception('User not logged in');
  }

  final requestBody = jsonEncode({
    "request": {
      "request_id": requestId,
      "data": {"date": date, "type": "all", "page": page, "country": ""},
    },
  });

  final headers = {
    'Content-Type': 'application/json',
    if (isPremiumScreen && token != null) 'Authorization': 'Bearer $token',
  };

  final response = await http.post(
    Uri.parse(
      isPremiumScreen
          ? '$baseUrl/fixtures/fixtures'
          : '$baseUrl/fixtures/get_fixtures',
    ),
    headers: headers,
    body: requestBody,
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['status'] == 1) {
      if (body['data'] == null) {
        return [];
      }
      final Map<String, dynamic> data = body['data'];
      final List<Tip> tips = [];

      for (final countryEntry in data.entries) {
        final country = countryEntry.key;
        final Map<String, dynamic> leagues = countryEntry.value;

        for (final leagueEntry in leagues.entries) {
          final league = leagueEntry.key;
          final List<dynamic> matches = leagueEntry.value;

          for (final match in matches) {
            // Augment each match with league/country info for parsing
            match['leagueName'] = league;
            match['country'] = country;

            tips.add(
              Tip.fromJson({
                'id': match['match_id'],
                'home': match['home_team'],
                'away': match['away_team'],
                'homeImage': match['home_team_logo'],
                'awayImage': match['away_team_logo'],
                'date': match['date'],
                'fixtureDate': match['fixture_date'],
                'time': match['fixture_time'],
                'homeOdd': match['home_team_odd'],
                'drawOdd': match['draw_odd'],
                'awayOdd': match['away_team_odd'],
                'tip': match['tip'],
                'bestTip': match['best_tip'],
                'homeScore': match['home_score'],
                'awayScore': match['away_score'],
                'confidence': match['confidence'],
                'isPlayed': match['is_played'],
                'isScoreUpdated': match['is_score_updated'],
                'playing': match['playing'],
                'country': match['country'],
                'countryId': match['country_id'],
                'leagueLogo': match['league_logo'],
                'leagueName': match['league_name'],
              }, premium: isPremiumScreen),
            );
          }
        }
      }

      return tips;
    } else if (body['status'] == 0) {
      throw Exception(body['message'] ?? 'There are no pending events');
    } else {
      // If it's a premium screen and the token is invalid, throw
      if (isPremiumScreen && body['status'] == 403) {
        throw UnauthorizedException(body['message'] ?? 'Unauthorized access');
      }
      throw Exception(body['message'] ?? 'Failed to fetch tips');
    }
  } else {
    throw Exception('Failed to fetch tips');
  }
}*/

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}

// Add this function to api_service.dart
Future<Map<String, dynamic>> checkSubscriptionStatus() async {
  final token = await storage.read(key: 'access_token');
  if (token == null) throw Exception('User not logged in');

  final url = Uri.parse('$baseUrl/billing/get_subscription_status');

  final requestBody = {
    "request": {"request_id": "1", "data": {}},
  };

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(requestBody),
  );

  final responseData = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return responseData;
  } else if (response.statusCode == 403) {
    throw Exception('Authorization token expired. Please login again');
  } else {
    throw Exception(responseData['message'] ?? 'Failed to check subscription');
  }
}

// Add this to api_service.dart (after checkSubscriptionStatus):
Future<List<dynamic>> getRecentPayments() async {
  final token = await storage.read(key: 'access_token');
  if (token == null) throw Exception('User not logged in');

  final url = Uri.parse('$baseUrl/deposits/get_my_recent_payments');

  final requestBody = {
    "request": {
      "request_id": "1",
      "data": {"page": 0},
    },
  };

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(requestBody),
  );

  final responseData = jsonDecode(response.body);

  if (response.statusCode == 200) {
    if (responseData['status'] == 1) {
      return responseData['items'] ?? [];
    } else {
      return []; // No payments found
    }
  } else {
    throw Exception('Failed to fetch payments');
  }
}

int generatePaymentId() =>
    DateTime.now().millisecondsSinceEpoch.remainder(1000000);

// Update the initiatePayment function in api_service.dart
Future<Map<String, dynamic>> initiatePayment({
  required int planId,
  required String phone,
  required int userId,
}) async {
  final token = await storage.read(key: 'access_token');
  if (token == null) throw Exception('User not logged in');

  final paymentId = generatePaymentId();
  final url = Uri.parse('$baseUrl/deposits/initiate_payment');

  final requestBody = {
    "request": {
      "request_id": "1",
      "data": {
        "plan_id": planId,
        "phone": phone,
        "payment_id": paymentId,
        "user_id": userId,
      },
    },
  };

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(requestBody),
  );

  final responseData = jsonDecode(response.body);

  if (response.statusCode == 200) {
    if (responseData['status'] == 1) {
      return responseData; // Return success data
    } else {
      // Handle API-specific error messages
      throw Exception(responseData['message'] ?? 'Payment initiation failed');
    }
  } else {
    throw Exception(
      responseData['message'] ?? 'Request failed: ${response.statusCode}',
    );
  }
}

// Add this function to api_service.dart
Future<Map<String, dynamic>> checkTransactionStatus({
  required String merchantRequestId,
  required String checkoutRequestId,
}) async {
  final token = await storage.read(key: 'access_token');
  if (token == null) throw Exception('User not logged in');

  final url = Uri.parse('$baseUrl/transactions/online_payment');

  final requestBody = {
    "Body": {
      "stkCallback": {
        "MerchantRequestID": merchantRequestId,
        "CheckoutRequestID": checkoutRequestId,
      },
    },
  };

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(requestBody),
  );

  final responseData = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return responseData;
  } else {
    throw Exception(
      responseData['message'] ?? 'Failed to check transaction status',
    );
  }
}

//not used
Future<void> getFixtureDetail(String id) async {
  final token = await storage.read(key: 'access_token');
  if (token == null) throw Exception('User not logged in');

  final requestId = DateTime.now().millisecondsSinceEpoch;

  final requestBody = {
    "request": {
      "request_id": requestId,
      "data": {"id": id},
    },
  };

  final url = Uri.parse('$baseUrl/fixtures/fixture_details');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(requestBody),
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Request failed: ${response.statusCode} - ${response.body}',
    );
  }
}

// Add to api_service.dart after existing functions

// Forgot Password - Send code to email
Future<Map<String, dynamic>> forgotPassword(String email) async {
  final requestBody = {
    "request": {
      "request_id": DateTime.now().millisecondsSinceEpoch,
      "data": {"identity": email},
    },
  };

  final response = await http.post(
    Uri.parse('$baseUrl/auth/forgot_password'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestBody),
  );

  final responseData = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return responseData;
  } else {
    throw Exception(responseData['message'] ?? 'Failed to send reset code');
  }
}

// Verify reset code
Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
  final requestBody = {
    "request": {
      "request_id": DateTime.now().millisecondsSinceEpoch,
      "data": {"identity": email, "code": code},
    },
  };

  final response = await http.post(
    Uri.parse('$baseUrl/auth/confirm_code'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestBody),
  );

  final responseData = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return responseData;
  } else {
    throw Exception(responseData['message'] ?? 'Failed to verify code');
  }
}

// Reset password with code
Future<Map<String, dynamic>> resetPasswordWithCode({
  required String code,
  required String password,
  required String confirmPassword,
}) async {
  final requestBody = {
    "request": {
      "request_id": DateTime.now().millisecondsSinceEpoch,
      "data": {
        "code": code,
        "password": password,
        "confirm_password": confirmPassword,
      },
    },
  };

  final response = await http.post(
    Uri.parse('$baseUrl/auth/reset_password'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestBody),
  );

  final responseData = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return responseData;
  } else {
    throw Exception(responseData['message'] ?? 'Failed to reset password');
  }
}

// Update password while logged in
Future<Map<String, dynamic>> updatePassword({
  required String oldPassword,
  required String newPassword,
  required String confirmPassword,
}) async {
  final token = await storage.read(key: 'access_token');
  if (token == null) throw Exception('User not logged in');

  final requestBody = {
    "request": {
      "request_id": "1",
      "data": {
        "old_password": oldPassword,
        "password": newPassword,
        "confirm_password": confirmPassword,
      },
    },
  };

  final response = await http.post(
    Uri.parse('$baseUrl/users/update_my_password'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(requestBody),
  );

  final responseData = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return responseData;
  } else {
    throw Exception(responseData['message'] ?? 'Failed to update password');
  }
}
