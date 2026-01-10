import 'template_resolver.dart';

class ExpressionEvaluator {
  // Supported operators
  static const List<String> operators = ['==', '!=', '>=', '<=', '>', '<', 'contains'];

  static bool evaluate(String expression, Map<String, dynamic> context) {
    // 1. Resolve variables first
    // Note: TemplateResolver currently returns String. 
    // If the value is roughly numeric, we might want to compare as numbers.
    
    // We can use the resolver to substitute, but strict typing is hard.
    // Let's resolve the whole string first.
    String resolved = TemplateResolver.resolve(expression, context);
    
    // 2. Find operator
    String? op;
    int index = -1;
    
    // Sort operators by length desc to match '>=' before '>'
    for (final candidate in operators) {
       index = resolved.indexOf(' $candidate '); // strict spacing for safety? or just index
       if (index != -1) {
         op = candidate;
         break;
       }
    }
    
    if (op == null) {
      // No operator found. Return true if truthy string (not empty, not "false", not "null", "0")?
      // Or false?
      // Let's default to parsing as boolean
      final trimmed = resolved.trim().toLowerCase();
      return trimmed == 'true' || (trimmed != 'false' && trimmed != '0' && trimmed.isNotEmpty);
    }
    
    // 3. Split operands
    // We only support ONE binary operation for now
    final parts = resolved.split(' $op '); 
    if (parts.length < 2) return false;

    String left = parts[0].trim();
    String right = parts.sublist(1).join(' $op ').trim(); // Join rest in case right side has same string? Unlikely with split.
    
    // 4. Type deduction (Number vs String)
    dynamic leftVal = num.tryParse(left) ?? left;
    dynamic rightVal = num.tryParse(right) ?? right;
    
    // Boolean normalization
    if (leftVal == 'true') leftVal = true;
    if (leftVal == 'false') leftVal = false;
    if (rightVal == 'true') rightVal = true;
    if (rightVal == 'false') rightVal = false;

    switch (op) {
      case '==': return leftVal == rightVal;
      case '!=': return leftVal != rightVal;
      case '>': return (leftVal is num && rightVal is num) ? leftVal > rightVal : false;
      case '<': return (leftVal is num && rightVal is num) ? leftVal < rightVal : false;
      case '>=': return (leftVal is num && rightVal is num) ? leftVal >= rightVal : false;
      case '<=': return (leftVal is num && rightVal is num) ? leftVal <= rightVal : false;
      case 'contains': return left.toString().contains(right.toString());
      default: return false;
    }
  }
}
