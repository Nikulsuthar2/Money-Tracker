import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/goals/domain/goal.dart';
import 'package:money_manager/features/goals/data/goals_repository.dart';
import 'package:money_manager/features/accounts/presentation/widgets/icon_selector_modal.dart';
import 'package:money_manager/features/goals/presentation/widgets/goal_icon_widget.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';

class AddGoalPage extends ConsumerStatefulWidget {
  final Goal? goalToEdit;
  const AddGoalPage({super.key, this.goalToEdit});

  @override
  ConsumerState<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends ConsumerState<AddGoalPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetController;

  // Debt specific
  late TextEditingController _remainingBalanceController;
  late TextEditingController _interestRateController;
  late TextEditingController _minimumPaymentController;

  GoalType _type = GoalType.saving;
  int _color = 0xFF2196F3;
  String _iconData = 'emoji:🎯';
  String _frequency = 'Flexible';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final g = widget.goalToEdit;
    _nameController = TextEditingController(text: g?.name ?? '');
    _targetController = TextEditingController(
      text: g != null && g.targetAmount > 0 ? g.targetAmount.toString() : '',
    );
    _remainingBalanceController = TextEditingController(
      text: g?.remainingBalance?.toString() ?? '',
    );
    _interestRateController = TextEditingController(
      text: g?.interestRate?.toString() ?? '',
    );
    _minimumPaymentController = TextEditingController(
      text: g?.minimumPayment?.toString() ?? '',
    );

    if (g != null) {
      _type = g.type;
      _color = g.color;
      _iconData = g.iconData;
      _frequency = g.frequency ?? 'Flexible';
      _startDate = g.startDate;
      _endDate = g.endDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _remainingBalanceController.dispose();
    _interestRateController.dispose();
    _minimumPaymentController.dispose();
    super.dispose();
  }

  void _onDateTapped(bool isStart) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ??
              (_startDate ?? DateTime.now()).add(const Duration(days: 30)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final targetAmount = double.tryParse(_targetController.text) ?? 0.0;

    final goal = Goal()
      ..name = _nameController.text
      ..type = _type
      ..color = _color
      ..iconData = _iconData
      ..targetAmount = targetAmount
      ..frequency = _frequency
      ..startDate = _startDate
      ..endDate = _endDate;

    if (_type == GoalType.debtRepayment) {
      goal.totalDebt = targetAmount; // Target Amount is the Total Debt
      goal.remainingBalance = double.tryParse(_remainingBalanceController.text);
      goal.interestRate = double.tryParse(_interestRateController.text);
      goal.minimumPayment = double.tryParse(_minimumPaymentController.text);
      // Automatically calculate currentAmount if remaining balance is given and currentAmount is not set manually yet
      if (widget.goalToEdit == null &&
          goal.remainingBalance != null &&
          goal.remainingBalance! > 0) {
        goal.currentAmount = targetAmount - goal.remainingBalance!;
      }
    }

    if (widget.goalToEdit != null) {
      goal.id = widget.goalToEdit!.id;
      goal.currentAmount = widget.goalToEdit!.currentAmount;
      goal.createdAt = widget.goalToEdit!.createdAt;
      await ref.read(goalsRepositoryProvider).updateGoal(goal);
    } else {
      await ref.read(goalsRepositoryProvider).addGoal(goal);
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goalToEdit != null;
    final currency = ref.watch(currencyProvider);

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.all(16),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Goal' : 'Create Goal'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete Goal?'),
                    content: const Text(
                      'This will delete the goal and all its contributions. This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await ref
                      .read(goalsRepositoryProvider)
                      .deleteGoal(widget.goalToEdit!.id);
                  if (mounted) {
                    context.pop();
                    context.pop(); // Pop details page if came from there
                  }
                }
              },
            ),
          SizedBox(width: 10),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SegmentedButton<GoalType>(
              segments: const [
                ButtonSegment(value: GoalType.saving, label: Text('Saving')),
                ButtonSegment(
                  value: GoalType.debtRepayment,
                  label: Text('Debt'),
                ),
                ButtonSegment(
                  value: GoalType.purchase,
                  label: Text('Purchase'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (val) => setState(() => _type = val.first),
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const Gap(24),

            // Icon Picker
            const Text(
              'Goal Icon',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  builder: (ctx) => IconSelectorModal(
                    onIconSelected: (val) {
                      setState(() => _iconData = val);
                    },
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    GoalIconWidget(
                      iconData: _iconData,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Icon',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Personalize your goal appearance',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const Gap(24),
            TextFormField(
              controller: _nameController,
              decoration: inputDecoration.copyWith(
                labelText: 'Goal Name',
                hintText: 'e.g. Laptop Purchase',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const Gap(16),
            TextFormField(
              controller: _targetController,
              decoration: inputDecoration.copyWith(
                labelText: _type == GoalType.debtRepayment
                    ? 'Total Debt Amount'
                    : 'Target Amount',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) =>
                  v == null || v.isEmpty || double.tryParse(v) == null
                  ? 'Invalid number'
                  : null,
              onChanged: (_) => setState(() {}),
            ),
            const Gap(16),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _onDateTapped(true),
                    child: InputDecorator(
                      decoration: inputDecoration.copyWith(
                        labelText:
                            'Start Date' +
                            (_type == GoalType.debtRepayment ? ' *' : ''),
                        errorText:
                            _type == GoalType.debtRepayment &&
                                _startDate == null
                            ? 'Required for debt'
                            : null,
                      ),
                      child: Text(
                        _startDate != null
                            ? DateFormat.yMMMd().format(_startDate!)
                            : 'Optional',
                      ),
                    ),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: InkWell(
                    onTap: () => _onDateTapped(false),
                    child: InputDecorator(
                      decoration: inputDecoration.copyWith(
                        labelText:
                            'End Date' +
                            (_type == GoalType.debtRepayment ? ' *' : ''),
                        errorText:
                            _type == GoalType.debtRepayment && _endDate == null
                            ? 'Required for debt'
                            : null,
                      ),
                      child: Text(
                        _endDate != null
                            ? DateFormat.yMMMd().format(_endDate!)
                            : 'Optional',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),

            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: inputDecoration.copyWith(labelText: 'Frequency'),
              items: [
                'Flexible',
                'Daily',
                'Weekly',
                'Bi-weekly',
                'Monthly',
                'Yearly',
              ].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _frequency = val);
              },
            ),
            const Gap(16),

            if (_type == GoalType.debtRepayment) ...[
              TextFormField(
                controller: _remainingBalanceController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Remaining Balance',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _interestRateController,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Interest Rate (%)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: TextFormField(
                      controller: _minimumPaymentController,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Minimum Payment',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(16),
            ],

            if (_frequency != 'Flexible' && _endDate != null)
              Builder(
                builder: (ctx) {
                  final target = double.tryParse(_targetController.text) ?? 0.0;
                  final start = _startDate ?? DateTime.now();
                  final end = _endDate!;
                  final days = end.difference(start).inDays;

                  final current = widget.goalToEdit?.currentAmount ?? 0.0;
                  final remainingAmount = _type == GoalType.debtRepayment
                      ? (double.tryParse(_remainingBalanceController.text) ??
                            (target - current))
                      : (target - current);

                  if (target <= 0) return const SizedBox.shrink();
                  if (remainingAmount <= 0)
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Goal fully achieved!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  if (days <= 0)
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'End date must be after start date',
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    );

                  double perContribution = 0;
                  String freqText = '';

                  switch (_frequency) {
                    case 'Daily':
                      perContribution = remainingAmount / days;
                      freqText = 'day';
                      break;
                    case 'Weekly':
                      perContribution = remainingAmount / (days / 7);
                      freqText = 'week';
                      break;
                    case 'Bi-weekly':
                      perContribution = remainingAmount / (days / 14);
                      freqText = 'two weeks';
                      break;
                    case 'Monthly':
                      perContribution = remainingAmount / (days / 30.44);
                      freqText = 'month';
                      break;
                    case 'Yearly':
                      perContribution = remainingAmount / (days / 365.25);
                      freqText = 'year';
                      break;
                  }

                  return Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Required Contribution to Reach Goal:\n$currency${perContribution.toStringAsFixed(2)} per $freqText',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),

            const Gap(16),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isEditing ? 'Save Changes' : 'Create Goal',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
