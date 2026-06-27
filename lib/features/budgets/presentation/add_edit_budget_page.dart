import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/budgets/domain/budget.dart';
import 'package:money_manager/features/budgets/data/budget_repository.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/categories/presentation/category_icon_widget.dart';

class AddEditBudgetPage extends ConsumerStatefulWidget {
  final Budget? budget;

  const AddEditBudgetPage({super.key, this.budget});

  @override
  ConsumerState<AddEditBudgetPage> createState() => _AddEditBudgetPageState();
}

class _AddEditBudgetPageState extends ConsumerState<AddEditBudgetPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  int? _selectedCategoryId;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _amountController.text = widget.budget!.amount.toString();
      _selectedCategoryId = widget.budget!.categoryId;
      _selectedPeriod = widget.budget!.period;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      if (widget.budget != null) {
        final updatedBudget = widget.budget!
          ..categoryId = _selectedCategoryId!
          ..amount = amount
          ..period = _selectedPeriod;
        await ref.read(budgetRepositoryProvider).updateBudget(updatedBudget);
      } else {
        final budget = Budget()
          ..categoryId = _selectedCategoryId!
          ..amount = amount
          ..period = _selectedPeriod;
        await ref.read(budgetRepositoryProvider).addBudget(budget);
      }
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving budget: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesRepositoryProvider).watchExpenseCategories();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget != null ? 'Edit Budget' : 'Add Budget'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Set a Spending Limit', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Choose a category and set a limit to track your spending.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
              const SizedBox(height: 32),
              
              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Budget Limit',
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                ),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an amount';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Category Selection
              StreamBuilder<List<Category>>(
                stream: categoriesAsync,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  
                  final categories = snapshot.data!;
                  return DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                    ),
                    value: _selectedCategoryId,
                    items: categories.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Row(
                        children: [
                          CategoryIconWidget(iconData: c.iconData, fallbackIcon: c.icon, color: c.color),
                          const SizedBox(width: 12),
                          Text(c.name),
                        ],
                      ),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    validator: (val) => val == null ? 'Please select a category' : null,
                  );
                }
              ),
              const SizedBox(height: 24),
              
              // Period Selection
              DropdownButtonFormField<BudgetPeriod>(
                decoration: InputDecoration(
                  labelText: 'Period',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                ),
                value: _selectedPeriod,
                items: BudgetPeriod.values.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p.displayName),
                )).toList(),
                onChanged: (val) => setState(() => _selectedPeriod = val!),
              ),
              
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveBudget,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
