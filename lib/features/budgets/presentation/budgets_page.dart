import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:money_manager/core/widgets/custom_refresh_indicator.dart';
import 'package:money_manager/features/categories/presentation/category_icon_widget.dart';
import 'package:money_manager/features/budgets/domain/budget.dart';
import 'package:money_manager/features/budgets/data/budget_allocation_repository.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/budgets/providers/budget_providers.dart';
import 'package:money_manager/features/budgets/data/budget_repository.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  void _prevMonth(WidgetRef ref) {
    final current = ref.read(budgetSelectedDateProvider);
    final period = ref.read(budgetPeriodFilterProvider);
    DateTime nextDate;
    if (period == BudgetPeriod.weekly) {
      nextDate = current.subtract(const Duration(days: 7));
    } else if (period == BudgetPeriod.yearly) {
      nextDate = DateTime(current.year - 1, current.month);
    } else {
      nextDate = DateTime(current.year, current.month - 1);
    }
    ref.read(budgetSelectedDateProvider.notifier).state = nextDate;
  }

  void _nextMonth(WidgetRef ref) {
    final current = ref.read(budgetSelectedDateProvider);
    final period = ref.read(budgetPeriodFilterProvider);
    DateTime nextDate;
    if (period == BudgetPeriod.weekly) {
      nextDate = current.add(const Duration(days: 7));
    } else if (period == BudgetPeriod.yearly) {
      nextDate = DateTime(current.year + 1, current.month);
    } else {
      nextDate = DateTime(current.year, current.month + 1);
    }
    ref.read(budgetSelectedDateProvider.notifier).state = nextDate;
  }

  void _showPeriodSelectorSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Select Period', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.view_week),
              title: const Text('Weekly'),
              onTap: () {
                ref.read(budgetPeriodFilterProvider.notifier).state = BudgetPeriod.weekly;
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Monthly'),
              onTap: () {
                ref.read(budgetPeriodFilterProvider.notifier).state = BudgetPeriod.monthly;
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Yearly'),
              onTap: () {
                ref.read(budgetPeriodFilterProvider.notifier).state = BudgetPeriod.yearly;
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date, BudgetPeriod period) {
    if (period == BudgetPeriod.weekly) {
      final diff = date.weekday - DateTime.monday;
      final start = date.subtract(Duration(days: diff));
      final end = start.add(const Duration(days: 6));
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
    } else if (period == BudgetPeriod.yearly) {
      return DateFormat('yyyy').format(date);
    }
    return DateFormat('MMMM yyyy').format(date);
  }

  void _showAllocationDialog(BuildContext context, WidgetRef ref, double currentAllocation) {
    final period = ref.read(budgetPeriodFilterProvider);
    final date = ref.read(budgetSelectedDateProvider);
    final key = getPeriodKey(period, date);
    final controller = TextEditingController(text: currentAllocation > 0 ? currentAllocation.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Total Allocated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the total amount of money you want to allocate for this period.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0.0;
              ref.read(budgetAllocationRepositoryProvider).saveAllocation(period, key, val);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsWithConsumptionProvider);
    final selectedDate = ref.watch(budgetSelectedDateProvider);
    final selectedPeriod = ref.watch(budgetPeriodFilterProvider);
    final summary = ref.watch(budgetSummaryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/budgets/add'),
          ),
        ],
      ),
      body: budgetsAsync.when(
        data: (budgets) {
          return Column(
            children: [
              // Combined Date & Period Selector
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => _prevMonth(ref),
                      icon: const Icon(Icons.chevron_left),
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showPeriodSelectorSheet(context, ref),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${selectedPeriod.name[0].toUpperCase()}${selectedPeriod.name.substring(1)}',
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                ),
                                const Gap(2),
                                Text(
                                  _formatDate(selectedDate, selectedPeriod),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => _nextMonth(ref),
                      icon: const Icon(Icons.chevron_right),
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
              // Summary Cards
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: _SummaryCard(
                      title: 'Total Allocated', 
                      amount: summary.income, 
                      color: Colors.blue,
                      onTap: () => _showAllocationDialog(context, ref, summary.income),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryCard(title: 'Assigned', amount: summary.assigned, color: Colors.purple)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryCard(title: 'To Assign', amount: summary.toAssign, color: summary.toAssign < 0 ? Colors.redAccent : Colors.green)),
                  ],
                ),
              ),
              Expanded(
                child: budgets.isEmpty
                  ? CustomRefreshIndicator(
                      onRefresh: () async {
                         ref.invalidate(budgetsWithConsumptionProvider);
                         await Future.delayed(const Duration(milliseconds: 300));
                      },
                      child: ListView(
                        children: [
                          const SizedBox(height: 60),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('No budgets yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
                                const SizedBox(height: 8),
                                Text('Set spending limits to keep your finances on track.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => context.push('/budgets/add'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Budget'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                )
                              ],
                            ),
                          )
                        ]
                      )
                    )
                  : CustomRefreshIndicator(
                      onRefresh: () async {
                         ref.invalidate(budgetsWithConsumptionProvider);
                         await Future.delayed(const Duration(milliseconds: 300));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: budgets.length,
                        itemBuilder: (context, index) {
                          final budget = budgets[index];
                          return _BudgetCard(budget: budget);
                        },
                      ),
                    ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  final BudgetWithConsumption budget;

  const _BudgetCard({required this.budget});

  void _showEditAmountDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: budget.amountLimit.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Budget Amount'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                final updated = budget.budget..amount = val;
                await ref.read(budgetRepositoryProvider).updateBudget(updated);
                // Also invalidate budgets if needed
                ref.invalidate(budgetsWithConsumptionProvider);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isExceeded = budget.isExceeded;
    final progressColor = isExceeded ? Colors.redAccent : Colors.green;
    
    // Format currency
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/budgets/details/${budget.budget.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(budget.budget.categoryColor).withOpacity(0.2),
                    child: CategoryIconWidget(
                      iconData: budget.budget.categoryIconData,
                      color: budget.budget.categoryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              budget.budget.categoryName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const Spacer(),
                            Text(
                              '${currencyFormatter.format(budget.amountLimit - budget.spent >= 0 ? budget.amountLimit - budget.spent : 0)} left',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isExceeded ? Colors.redAccent : Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _showEditAmountDialog(context, ref),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(Icons.edit, size: 16, color: theme.colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${currencyFormatter.format(budget.spent)} of ${currencyFormatter.format(budget.amountLimit)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: budget.progress > 1 ? 1.0 : budget.progress,
                  minHeight: 4,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              if (isExceeded) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Budget exceeded by ${currencyFormatter.format(budget.spent - budget.amountLimit)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final VoidCallback? onTap;

  const _SummaryCard({required this.title, required this.amount, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.compactCurrency(symbol: '₹', decimalDigits: 0);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis,),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.edit, size: 12, color: color.withOpacity(0.8)),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormatter.format(amount),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
