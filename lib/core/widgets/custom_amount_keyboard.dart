import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:money_manager/core/utils/math_evaluator.dart';

class CustomAmountKeyboard extends StatefulWidget {
  final String initialValue;
  const CustomAmountKeyboard({super.key, this.initialValue = ''});

  static Future<String?> show(BuildContext context, {String initialValue = ''}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomAmountKeyboard(initialValue: initialValue),
    );
  }

  @override
  State<CustomAmountKeyboard> createState() => _CustomAmountKeyboardState();
}

class _CustomAmountKeyboardState extends State<CustomAmountKeyboard> {
  late String _expression;

  @override
  void initState() {
    super.initState();
    _expression = widget.initialValue;
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'C') {
        _expression = '';
      } else if (key == 'DEL') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (key == '=') {
        _evaluate();
      } else {
        final isOperator = ['+', '-', '*', '/'].contains(key);
        
        // Prevent starting with operator other than minus
        if (isOperator && _expression.isEmpty && key != '-') {
          return;
        }

        if (isOperator && _expression.isNotEmpty) {
          final lastChar = _expression[_expression.length - 1];
          if (['+', '-', '*', '/'].contains(lastChar)) {
            // Replace the last operator with the new one
            _expression = _expression.substring(0, _expression.length - 1) + key;
            
            // Clean up any other consecutive operators just in case
            _expression = _expression.replaceAll(RegExp(r'[\+\-\*/]{2,}'), key);
            return;
          }
        }
        
        _expression += key;
        
        // Fallback cleanup
        if (isOperator) {
            _expression = _expression.replaceAll(RegExp(r'[\+\-\*/]{2,}'), key);
        }
      }
    });
  }

  void _evaluate() {
    if (_expression.isEmpty) {
      Navigator.pop(context, '');
      return;
    }
    
    // Check if it's already a plain number
    if (double.tryParse(_expression) != null && !_expression.contains(RegExp(r'[\+\-\*/]'))) {
      Navigator.pop(context, _expression);
      return;
    }

    final result = MathEvaluator.evaluate(_expression);
    if (result != null) {
      setState(() {
        // Remove decimal if it's a whole number
        _expression = result == result.toInt() ? result.toInt().toString() : result.toStringAsFixed(2);
      });
    } else {
      // Invalid expression flash or something
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid mathematical expression')),
      );
    }
  }

  void _onSubmit() {
    // Evaluate if there are operators, otherwise return
    if (_expression.contains(RegExp(r'[\+\-\*/]'))) {
      _evaluate();
    } else {
      Navigator.pop(context, _expression);
    }
  }

  Widget _buildKey(String label, {Color? color, Color? textColor, VoidCallback? onTap, IconData? icon, int flex = 1}) {
    final theme = Theme.of(context);
    final isOperator = ['/', '*', '-', '+', '='].contains(label);
    
    final bgColor = color ?? (isOperator ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHigh);
    final txtColor = textColor ?? (isOperator ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface);

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap ?? () => _onKeyPress(label),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 60,
              alignment: Alignment.center,
              child: icon != null
                  ? Icon(icon, color: txtColor, size: 24)
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: isOperator ? FontWeight.bold : FontWeight.w500,
                        color: txtColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(16),
          // Display Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      _expression.isEmpty ? '0' : _expression,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _onKeyPress('DEL'),
                  icon: const Icon(Icons.backspace_outlined),
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          const Gap(16),
          // Keypad
          Row(
            children: [
              _buildKey('C', color: theme.colorScheme.errorContainer, textColor: theme.colorScheme.onErrorContainer),
              _buildKey('/'),
              _buildKey('*'),
              _buildKey('DEL', icon: Icons.backspace, onTap: () => _onKeyPress('DEL')),
            ],
          ),
          Row(
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
              _buildKey('-'),
            ],
          ),
          Row(
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
              _buildKey('+'),
            ],
          ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildKey('1'),
                        _buildKey('2'),
                        _buildKey('3'),
                      ],
                    ),
                    Row(
                      children: [
                        _buildKey('0', flex: 2),
                        _buildKey('.'),
                      ],
                    ),
                  ],
                ),
              ),
              // Big Enter / Equals button
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Material(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _onSubmit,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 128, // Matches two rows
                        alignment: Alignment.center,
                        child: _expression.contains(RegExp(r'[\+\-\*/]'))
                            ? Icon(Icons.drag_handle, color: theme.colorScheme.onPrimary) // Equal icon
                            : Icon(Icons.check, color: theme.colorScheme.onPrimary, size: 32),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
