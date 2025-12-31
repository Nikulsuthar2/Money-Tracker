class MathEvaluator {
  /// Evaluates a simple mathematical expression string (e.g., "10+5", "50-20*2").
  /// Returns the result as a double, or null if invalid.
  /// Supports +, -, *, /. 
  /// Does NOT support parentheses or complex order of operations beyond standard left-to-right or simple precedence if we use a library, 
  /// but for this simple version we will handle basic operators.
  /// Actually, full expression evaluation is better served by a small recursive descent parser or similar
  /// to handle order of operations correctly (e.g. 10 + 5 * 2 = 20, not 30).
  
  static double? evaluate(String expression) {
    // Remove whitespace
    final clean = expression.replaceAll(' ', '');
    if (clean.isEmpty) return null;
    
    try {
      return _parseExpression(clean);
    } catch (e) {
      return null;
    }
  }

  static double _parseExpression(String expression) {
    // We can use a simple technique:
    // 1. Tokenize numbers and operators
    // 2. Handle * and / first
    // 3. Handle + and - next
    
    final tokens = <String>[];
    String numberBuffer = '';
    
    for (int i = 0; i < expression.length; i++) {
      final char = expression[i];
      if ('+-*/'.contains(char)) {
        if (numberBuffer.isNotEmpty) {
          tokens.add(numberBuffer);
          numberBuffer = '';
        }
        // Handle negative numbers at start or after operator
        if (char == '-' && (tokens.isEmpty || '+-*/'.contains(tokens.last))) {
           numberBuffer += '-';
        } else {
           tokens.add(char);
        }
      } else {
        numberBuffer += char;
      }
    }
    if (numberBuffer.isNotEmpty) {
      tokens.add(numberBuffer);
    }

    // Now process * and /
    final intermediate = <String>[];
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token == '*' || token == '/') {
         final prev = double.parse(intermediate.removeLast());
         final next = double.parse(tokens[++i]);
         if (token == '*') intermediate.add((prev * next).toString());
         if (token == '/') intermediate.add((prev / next).toString());
      } else {
         intermediate.add(token);
      }
    }

    // Now process + and -
    double result = double.parse(intermediate[0]);
    for (int i = 1; i < intermediate.length; i += 2) {
       final op = intermediate[i];
       final val = double.parse(intermediate[i+1]);
       if (op == '+') result += val;
       if (op == '-') result -= val;
    }
    
    return result;
  }
}
