class TemplateResolver {
  // Replaces {{key.path}} with value from nested context map
  static String resolve(String input, Map<String, dynamic> context) {
    if (input.isEmpty || context.isEmpty) return input;
    
    String result = input;
    // Regex to find {{...}} patterns. Key can contain dots.
    final RegExp regex = RegExp(r'\{\{([a-zA-Z0-9_.]+)\}\}');
    
    result = result.replaceAllMapped(regex, (match) {
      final keyPath = match.group(1);
      if (keyPath != null) {
        final val = _getValueFromPath(keyPath, context);
        if (val != null) {
          return val.toString();
        }
      }
      return match.group(0)!; // Keep original if resolve fails
    });
    
    return result;
  }

  static dynamic _getValueFromPath(String path, Map<String, dynamic> context) {
    final keys = path.split('.');
    dynamic current = context;

    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }
}
