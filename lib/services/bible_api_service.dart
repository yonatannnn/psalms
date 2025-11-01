import 'dart:convert';
import 'package:http/http.dart' as http;

class BibleApiService {
  static const String _baseUrl = 'https://api.scripture.api.bible/v1';
  static const String _apiKey = 'ZRQQEKJf9gLl5EkCigVxn';
  
  // Get available Bible versions
  static Future<List<BibleVersion>> getBibleVersions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bibles'),
        headers: {
          'api-key': _apiKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> bibles = data['data'];
        return bibles.map((bible) => BibleVersion.fromJson(bible)).toList();
      } else {
        throw Exception('Failed to load Bible versions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching Bible versions: $e');
    }
  }

  // Get specific Bible content (Psalms)
  static Future<BibleContent> getBibleContent(String bibleId, String chapterId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bibles/$bibleId/chapters/$chapterId'),
        headers: {
          'api-key': _apiKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BibleContent.fromJson(data['data']);
      } else {
        throw Exception('Failed to load Bible content: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching Bible content: $e');
    }
  }

  // Get multiple chapters (for Psalms range)
  static Future<List<BibleContent>> getPsalmsRange(String bibleId, int startChapter, int endChapter) async {
    try {
      List<BibleContent> chapters = [];
      
      for (int chapter = startChapter; chapter <= endChapter; chapter++) {
        final chapterId = 'PSA.$chapter';
        final content = await getBibleContent(bibleId, chapterId);
        chapters.add(content);
      }
      
      return chapters;
    } catch (e) {
      throw Exception('Error fetching Psalms range: $e');
    }
  }
}

class BibleVersion {
  final String id;
  final String name;
  final String language;
  final String abbreviation;

  BibleVersion({
    required this.id,
    required this.name,
    required this.language,
    required this.abbreviation,
  });

  factory BibleVersion.fromJson(Map<String, dynamic> json) {
    return BibleVersion(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      language: json['language']['name'] ?? '',
      abbreviation: json['abbreviation'] ?? '',
    );
  }
}

class BibleContent {
  final String id;
  final String reference;
  final String content;
  final int verseCount;

  BibleContent({
    required this.id,
    required this.reference,
    required this.content,
    required this.verseCount,
  });

  factory BibleContent.fromJson(Map<String, dynamic> json) {
    return BibleContent(
      id: json['id'] ?? '',
      reference: json['reference'] ?? '',
      content: json['content'] ?? '',
      verseCount: json['verseCount'] ?? 0,
    );
  }
}
