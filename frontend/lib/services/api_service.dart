import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class ApiService {
  // For Android Emulator: http://10.0.2.2:8001/api
  // For Web/Desktop/iOS Sim: http://127.0.0.1:8001/api
  // For Physical Device: http://<YOUR_HOST_IP>:8001/api
  static const String baseUrl = 'http://10.0.2.2:8001/api';

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      // Generate a fast random UUID-like string since 'uuid' package isn't installed
      final random = Random();
      deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(100000)}';
      await prefs.setString('device_id', deviceId);
    }
    return deviceId;
  }

  static Future<List<dynamic>> getPersonalizedFeed(
      String persona, List<String> interests) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/news/feed'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'persona': persona, 'interests': interests}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['feed'] ?? [];
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      print('API Error (Feed): $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getStoryArc(
      String queryTerms, String articlesContext, String persona) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/news/story/arc'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'queryTerms': queryTerms,
          'articlesContext': articlesContext,
          'persona': persona
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['arc'];
      }
      return null;
    } catch (e) {
      print('API Error (Story Arc): $e');
      return null;
    }
  }

  static Future<List<dynamic>> getTrackedStories(String userId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/news/tracked/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['tracked_stories'] ?? [];
      }
      return [];
    } catch (e) {
      print('API Error (Get Tracked): $e');
      return [];
    }
  }

  static Future<String?> toggleTrackStory(
      String userId, String storyId, Map<String, dynamic> storyData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/news/tracked/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'user_id': userId, 'story_id': storyId, 'story_data': storyData}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'];
      }
      return null;
    } catch (e) {
      print('API Error (Toggle Track): $e');
      return null;
    }
  }

  static Future<String> askQuestion(
      String queryTerms, String question, String persona) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/ask'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query_terms': queryTerms,
          'question': question,
          'persona': persona
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? 'No answer available';
      }
      return 'Failed to get an answer.';
    } catch (e) {
      return 'Error connecting to the AI.';
    }
  }
}
