import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  static final Set<String> _stopWords = {
    'a', 'an', 'the', 'and', 'or', 'but', 'is', 'if', 'then', 'else', 'when', 'at',
    'from', 'by', 'for', 'with', 'in', 'out', 'on', 'off', 'over', 'under', 'again',
    'further', 'once', 'dan', 'yang', 'itu', 'ini', 'untuk', 'dengan', 'dari',
    'ke', 'di', 'ada', 'adalah', 'sebagai', 'pada', 'oleh', 'rm', 'price', 'harga'
  };

  static final _priceRegex = RegExp(
    r'(?:\$|RM|RN|R\s*M|PRICE|P\s*R\s*I\s*C\s*E|Total)?\s*[:\s]*(\d{1,5}(?:[.,]\d{1,2})?)\b',
    caseSensitive: false,
  );

  static final _ignoredNameRegex = RegExp(
    r'^(total|subtotal|tax|date|cash|change|quantity|qty|price|amount|rm|rn|net|weight|unit|per|kg|g|ml|l|inc|excl)$',
    caseSensitive: false,
  );

  /// Pre-processing logic for OCR enhancement
  /// Bypassed custom Dart loops. Google ML Kit handles raw color images 
  /// natively with highly-optimized internal hardware thresholding.
  Future<String> preprocessImage(String imagePath) async {
    // Ensure the file completely exists on disk cache before passing to native ML Kit
    final file = File(imagePath);
    if (await file.exists()) {
      return imagePath;
    }
    return imagePath;
  }

  /// Existing function for price tag scanner
  Future<Map<String, String?>> processPriceTag(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final allLines = recognizedText.blocks
          .expand((block) => block.lines)
          .where((line) => line.text.trim().isNotEmpty)
          .toList();

      if (allLines.isEmpty) return {'itemName': null, 'price': null};

      final priceMatch = _findPriceMatch(allLines);
      if (priceMatch == null) return {'itemName': null, 'price': null};

      final itemName = _findItemName(allLines, priceMatch);

      return {
        'itemName': itemName,
        'price': priceMatch.value,
      };
    } catch (e) {
      debugPrint('Error processing price tag: $e');
      return {'itemName': null, 'price': null};
    }
  }

  /// Recognizes all text in an image
  Future<String> recognizeFullText(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return "";
      
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      debugPrint('Full text recognition error: $e');
      return "";
    }
  }

  /// Normalized keywords
  List<String> normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .where((word) => !_stopWords.contains(word))
        .where((word) => !RegExp(r'^\d+[a-z]*$').hasMatch(word))
        .toList();
  }

  /// TF-IDF + Cosine Similarity calculation
  double calculateSimilarity(String text1, String text2) {
    final words1 = normalize(text1);
    final words2 = normalize(text2);

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final allWords = (words1 + words2).toSet().toList();
    
    final tf1 = _getTF(words1, allWords);
    final tf2 = _getTF(words2, allWords);

    final idf = allWords.map((w) {
      int df = 0;
      if (words1.contains(w)) df++;
      if (words2.contains(w)) df++;
      return log(3.0 / (df + 1.0)) + 1.0;
    }).toList();

    final tfidf1 = List<double>.generate(allWords.length, (i) => tf1[i] * idf[i]);
    final tfidf2 = List<double>.generate(allWords.length, (i) => tf2[i] * idf[i]);

    return _cosineSimilarity(tfidf1, tfidf2);
  }

  List<double> _getTF(List<String> words, List<String> allWords) {
    final counts = <String, int>{};
    for (var w in words) {
      counts[w] = (counts[w] ?? 0) + 1;
    }
    return allWords.map((w) => (counts[w] ?? 0).toDouble()).toList();
  }

  double _cosineSimilarity(List<double> v1, List<double> v2) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      normA += pow(v1[i], 2);
      normB += pow(v2[i], 2);
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  _PriceMatch? _findPriceMatch(List<TextLine> lines) {
    final candidates = <_PriceMatch>[];
    for (final line in lines) {
      final match = _priceRegex.firstMatch(line.text);
      if (match != null) {
        final rawValue = match.group(1);
        if (rawValue != null) {
          final cleanValue = rawValue.replaceAll(',', '.');
          final parsed = double.tryParse(cleanValue);
          if (parsed != null) {
            final hasCurrency = line.text.contains(RegExp(r'\$|RM|RN|R\s*M|PRICE', caseSensitive: false));
            final hasTwoDecimals = cleanValue.contains('.') && cleanValue.split('.')[1].length == 2;
            candidates.add(_PriceMatch(line, parsed.toStringAsFixed(2), hasCurrency, hasTwoDecimals));
          }
        }
      }
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      if (a.hasCurrency != b.hasCurrency) return a.hasCurrency ? -1 : 1;
      if (a.hasTwoDecimals != b.hasTwoDecimals) return a.hasTwoDecimals ? -1 : 1;
      return (b.line.boundingBox.width * b.line.boundingBox.height)
          .compareTo(a.line.boundingBox.width * a.line.boundingBox.height);
    });
    return candidates.first;
  }

  String? _findItemName(List<TextLine> lines, _PriceMatch priceMatch) {
    final priceLine = priceMatch.line;
    final sameLineText = priceLine.text.replaceAll(_priceRegex, '').trim();
    if (_isValidItemName(sameLineText)) return _cleanItemName(sameLineText);

    final candidates = lines.where((line) => line != priceLine && _isValidItemName(line.text)).toList();
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => _calculateProximityScore(a, priceLine).compareTo(_calculateProximityScore(b, priceLine)));
    return _cleanItemName(candidates.first.text);
  }

  bool _isValidItemName(String text) {
    final clean = text.trim();
    if (clean.length < 2) return false;
    final letterCount = RegExp(r'[A-Za-z]').allMatches(clean).length;
    final digitCount = RegExp(r'[0-9]').allMatches(clean).length;
    if (letterCount <= digitCount && digitCount > 0) return false;
    if (!RegExp(r'[A-Za-z]').hasMatch(clean)) return false;
    if (RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(clean)) return false;
    if (_ignoredNameRegex.hasMatch(clean.toLowerCase())) return false;
    return true;
  }

  String _cleanItemName(String text) => text.trim().replaceAll(RegExp(r'^[:\-\s\.]+'), '').replaceAll(RegExp(r'[:\-\s\.]+$'), '').replaceAll(RegExp(r'\s+'), ' ');

  double _calculateProximityScore(TextLine candidate, TextLine priceLine) {
    final candCenter = candidate.boundingBox.center;
    final priceCenter = priceLine.boundingBox.center;
    final dx = (candCenter.dx - priceCenter.dx).abs();
    final dy = candCenter.dy - priceCenter.dy;
    double verticalDist = dy.abs();
    if (dy > 0) verticalDist *= 1.5; 
    double heightBonus = min(candidate.boundingBox.height, priceLine.boundingBox.height * 1.2);
    return (verticalDist + (dx * 0.5)) - (heightBonus * 0.4);
  }

  Future<void> dispose() => _textRecognizer.close();
}

class _PriceMatch {
  final TextLine line;
  final String value;
  final bool hasCurrency;
  final bool hasTwoDecimals;
  _PriceMatch(this.line, this.value, this.hasCurrency, this.hasTwoDecimals);
}
