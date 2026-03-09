import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PDFHistoryItem {
  final String path;
  final String name;
  final DateTime lastOpened;

  PDFHistoryItem({
    required this.path,
    required this.name,
    required this.lastOpened,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'lastOpened': lastOpened.toIso8601String(),
  };

  factory PDFHistoryItem.fromJson(Map<String, dynamic> json) => PDFHistoryItem(
    path: json['path'],
    name: json['name'],
    lastOpened: DateTime.parse(json['lastOpened']),
  );
}

class HistoryService {
  static const String _key = 'pdf_history';
  static const int _maxItems = 10;

  Future<List<PDFHistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_key);
      if (historyJson == null) return [];

      final List<dynamic> decoded = jsonDecode(historyJson);
      return decoded.map((item) => PDFHistoryItem.fromJson(item)).toList()
        ..sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
    } catch (e) {
      debugPrint('Error loading history: $e');
      return [];
    }
  }

  Future<void> removeFromHistory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    List<PDFHistoryItem> history = await getHistory();
    history.removeWhere((item) => item.path == path);
    final String encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  Future<void> addToHistory(String path, String name) async {
    final prefs = await SharedPreferences.getInstance();
    List<PDFHistoryItem> history = await getHistory();

    // Remove if already exists to update its position
    history.removeWhere((item) => item.path == path);

    // Add to start
    history.insert(
      0,
      PDFHistoryItem(path: path, name: name, lastOpened: DateTime.now()),
    );

    // Keep only last N items
    if (history.length > _maxItems) {
      history = history.sublist(0, _maxItems);
    }

    final String encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
