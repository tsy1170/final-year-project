import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  // Matches prices like $5.50, RM 5.50, 5.50, R M 5.50, or Price: 5.50
  // Group 1 captures the numeric value.
  static final _priceRegex = RegExp(
    r'(?:\$|RM|RN|R\s*M|PRICE|P\s*R\s*I\s*C\s*E|Total)?\s*[:\s]*(\d{1,5}(?:[.,]\d{1,2})?)\b',
    caseSensitive: false,
  );

  // Common labels/noise that shouldn't be picked as an item name.
  static final _ignoredNameRegex = RegExp(
    r'^(total|subtotal|tax|date|cash|change|quantity|qty|price|amount|rm|rn|net|weight|unit|per|kg|g|ml|l|inc|excl)$',
    caseSensitive: false,
  );

  Future<Map<String, String?>> processPriceTag(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final allLines = recognizedText.blocks
          .expand((block) => block.lines)
          .where((line) => line.text.trim().isNotEmpty)
          .toList();

      if (allLines.isEmpty) return {'itemName': null, 'price': null};

      // 1. Find the most likely price line
      final priceMatch = _findPriceMatch(allLines);
      if (priceMatch == null) return {'itemName': null, 'price': null};

      // 2. Find the most likely item name relative to that price
      final itemName = _findItemName(allLines, priceMatch);

      return {
        'itemName': itemName,
        'price': priceMatch.value,
      };
    } catch (e) {
      // ignore: avoid_print
      print('OCR processing error: $e');
      return {'itemName': null, 'price': null};
    }
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
            final formattedValue = parsed.toStringAsFixed(2);
            
            // Heuristic: Explicit currency labels ($, RM, etc) make it very likely to be a price.
            final hasCurrency = line.text.contains(RegExp(r'\$|RM|RN|R\s*M|PRICE', caseSensitive: false));
            
            // Heuristic: Most price tags use exactly 2 decimal places.
            final hasTwoDecimals = cleanValue.contains('.') && cleanValue.split('.')[1].length == 2;
            
            candidates.add(_PriceMatch(line, formattedValue, hasCurrency, hasTwoDecimals));
          }
        }
      }
    }

    if (candidates.isEmpty) return null;

    // Sorting: Confidence-based
    candidates.sort((a, b) {
      // 1. Currency labels are top priority
      if (a.hasCurrency != b.hasCurrency) return a.hasCurrency ? -1 : 1;
      // 2. 2-decimal format is high priority
      if (a.hasTwoDecimals != b.hasTwoDecimals) return a.hasTwoDecimals ? -1 : 1;
      // 3. Larger text (calculated by area) is likely the main price
      final areaA = a.line.boundingBox.width * a.line.boundingBox.height;
      final areaB = b.line.boundingBox.width * b.line.boundingBox.height;
      return areaB.compareTo(areaA);
    });

    return candidates.first;
  }

  String? _findItemName(List<TextLine> lines, _PriceMatch priceMatch) {
    final priceLine = priceMatch.line;
    
    // Layout A: Same Line (e.g., "COKE 1.5L RM3.50")
    // Remove the price match and any trailing/leading colons/symbols
    final sameLineText = priceLine.text.replaceAll(_priceRegex, '').trim();
    if (_isValidItemName(sameLineText)) {
      return _cleanItemName(sameLineText);
    }

    // Layout B: Multi-line
    final candidates = lines
        .where((line) => line != priceLine && _isValidItemName(line.text))
        .toList();

    if (candidates.isEmpty) return null;

    // Sort by a combination of proximity and font size (height)
    candidates.sort((a, b) {
      final scoreA = _calculateProximityScore(a, priceLine);
      final scoreB = _calculateProximityScore(b, priceLine);
      return scoreA.compareTo(scoreB);
    });

    final primaryCandidate = candidates.first;
    String finalName = primaryCandidate.text;

    // Multi-line Merging Logic: 
    // Check if the next best candidate is directly above/below and vertically aligned
    if (candidates.length > 1) {
      final secondary = candidates[1];
      final primaryBox = primaryCandidate.boundingBox;
      final secondaryBox = secondary.boundingBox;

      // Check if they are stacked and have similar widths/alignment
      final isStacked = (primaryBox.top - secondaryBox.bottom).abs() < primaryBox.height * 0.8 ||
                        (secondaryBox.top - primaryBox.bottom).abs() < primaryBox.height * 0.8;
      
      final hasSimilarX = (primaryBox.left - secondaryBox.left).abs() < primaryBox.width * 0.5;

      if (isStacked && hasSimilarX) {
        if (secondaryBox.top < primaryBox.top) {
          finalName = "${secondary.text} ${primaryCandidate.text}";
        } else {
          finalName = "${primaryCandidate.text} ${secondary.text}";
        }
      }
    }

    return _cleanItemName(finalName);
  }

  bool _isValidItemName(String text) {
    final clean = text.trim();
    if (clean.length < 2) return false;
    
    // Density Check: Item names should have more letters than digits.
    // This filters out barcodes, long dates, and unit prices.
    final letterCount = RegExp(r'[A-Za-z]').allMatches(clean).length;
    final digitCount = RegExp(r'[0-9]').allMatches(clean).length;
    if (letterCount <= digitCount && digitCount > 0) return false;

    // Must contain at least some letters
    if (!RegExp(r'[A-Za-z]').hasMatch(clean)) return false;

    // Exclude strings that are mostly dates (e.g., 20/12/24)
    if (RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(clean)) return false;

    // Must not be a generic metadata keyword
    if (_ignoredNameRegex.hasMatch(clean.toLowerCase())) return false;
    return true;
  }

  String _cleanItemName(String text) {
    // Remove leading/trailing punctuation often left by OCR (like colons)
    return text.trim()
        .replaceAll(RegExp(r'^[:\-\s\.]+'), '')
        .replaceAll(RegExp(r'[:\-\s\.]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  double _calculateProximityScore(TextLine candidate, TextLine priceLine) {
    final candCenter = candidate.boundingBox.center;
    final priceCenter = priceLine.boundingBox.center;
    
    final dx = (candCenter.dx - priceCenter.dx).abs();
    final dy = candCenter.dy - priceCenter.dy; // Positive if candidate is BELOW price

    double verticalDist = dy.abs();
    
    // Stronger penalty for text BELOW the price (often unit prices/weights)
    if (dy > 0) {
      verticalDist *= 1.5; 
    }

    // FONT SIZE BONUS: 
    // Even if the price is much larger, item names are typically larger than 
    // other secondary labels (like weight). We favor larger text but cap 
    // the bonus at 1.2x the price height to avoid huge store headers.
    double heightBonus = candidate.boundingBox.height;
    final maxBonus = priceLine.boundingBox.height * 1.2;
    if (heightBonus > maxBonus) heightBonus = maxBonus;

    // Vertical alignment is significantly more important than horizontal
    // Height bonus subtracts from the score (lower score = better)
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
