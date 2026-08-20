import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<Map<String, String?>> processPriceTag(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    String? itemName;
    String? price;

    // Logic to extract price (usually looking for numbers with decimals or RM prefix)
    final priceRegex = RegExp(r'(?:RM\s*)?(\d+\.\d{2})');
    
    List<String> allLines = [];
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        allLines.add(line.text.trim());
        
        if (price == null) {
          final match = priceRegex.firstMatch(line.text);
          if (match != null) {
            price = match.group(1);
          }
        }
      }
    }

    // Heuristic for Item Name: Usually one of the first lines or lines before the price
    // This is a simple implementation and can be refined
    if (allLines.isNotEmpty) {
      // Filter out RM and purely numeric lines for item name
      final potentialNames = allLines.where((line) => 
        !line.contains('RM') && 
        !RegExp(r'^\d+\.\d{2}$').hasMatch(line) &&
        line.length > 2
      ).toList();

      if (potentialNames.isNotEmpty) {
        itemName = potentialNames.first;
      }
    }

    return {
      'itemName': itemName,
      'price': price,
    };
  }

  void dispose() {
    _textRecognizer.close();
  }
}
