import '../../features/request/models/request_model.dart';
import '../../features/request/models/key_value_item.dart';
import 'package:uuid/uuid.dart';

class CurlParser {
  // Very basic parser for MVP. 
  // Supports: curl -X METHOD URL -H "Header" -d "Body"
  static RequestModel? parse(String curlCommand) {
    if (!curlCommand.trim().toLowerCase().startsWith('curl')) return null;

    final args = _splitArgs(curlCommand);
    
    String method = 'GET';
    String url = '';
    final List<KeyValueItem> headers = [];
    String? body;
    
    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      
      if (arg == 'curl') continue;
      
      // Method
      if (arg == '-X' || arg == '--request') {
        if (i + 1 < args.length) {
          method = args[++i].toUpperCase();
        }
        continue;
      }
      
      // Header
      if (arg == '-H' || arg == '--header') {
         if (i + 1 < args.length) {
           final parts = args[++i].split(':');
           if (parts.length >= 2) {
             headers.add(KeyValueItem(
               id: const Uuid().v4(),
               key: parts[0].trim(),
               value: parts.sublist(1).join(':').trim(),
               isEnabled: true,
             ));
           }
         }
         continue;
      }
      
      // Body
      if (arg == '-d' || arg == '--data' || arg == '--data-raw') {
         if (i + 1 < args.length) {
           body = args[++i];
           // If method was implicitly POST (default for -d), set it if still GET
           if (method == 'GET') method = 'POST';
         }
         continue;
      }
      
      // URL (Assumed if not starting with -)
      if (!arg.startsWith('-') && url.isEmpty) {
        // Strip quotes if any
        url = arg.replaceAll('"', '').replaceAll("'", '');
      }
    }
    
    // Fallback if URL still empty? (Maybe checking args[last]?)
    
    return RequestModel.initial().copyWith(
      method: method,
      url: url,
      headers: headers,
      body: body,
      bodyType: body != null ? RequestBodyType.json : RequestBodyType.none, // Basic assumption
    );
  }

  // Helper to split string respecting quotes
  static List<String> _splitArgs(String text) {
    final List<String> result = [];
    final pattern = RegExp(r'[^\s"]+|"[^"]*"');
    
    final matches = pattern.allMatches(text);
    for (var match in matches) {
      String str = match.group(0)!;
      if (str.startsWith('"') && str.endsWith('"')) {
        str = str.substring(1, str.length - 1);
      }
      result.add(str);
    }
    return result;
  }
}
