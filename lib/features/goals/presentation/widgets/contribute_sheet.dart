import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/goals/domain/goal.dart';
import 'package:money_manager/features/goals/domain/goal_contribution.dart';
import 'package:money_manager/features/goals/data/goals_repository.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:gap/gap.dart';

class ContributeSheet extends ConsumerStatefulWidget {
  final Goal goal;
  final int? preselectedAccountId;
  const ContributeSheet({super.key, required this.goal, this.preselectedAccountId});

  @override
  ConsumerState<ContributeSheet> createState() => _ContributeSheetState();
}

class _ContributeSheetState extends ConsumerState<ContributeSheet> {
  final _amountController = TextEditingController();
  Account? _selectedAccount;
  int _tabIndex = 0; // 0 = Contribute, 1 = Withdraw

  @override
  void initState() {
    super.initState();
    if (widget.preselectedAccountId != null) {
      // Need to find the account from the provider, but we are in initState and can't use ref.watch.
      // We will initialize _selectedAccount in the build method once.
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _save() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || _selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount and select an account')));
      return;
    }

    final isWithdrawal = _tabIndex == 1;

    final contribution = GoalContribution()
      ..goalId = widget.goal.id
      ..accountId = _selectedAccount!.id
      ..amount = isWithdrawal ? -amount : amount
      ..date = DateTime.now();

    await ref.read(goalsRepositoryProvider).addContribution(contribution);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final accountsList = ref.watch(accountsWithBalanceProvider).valueOrNull ?? [];
    
    // Only cash accounts can contribute to goals
    final cashAccounts = accountsList.where((s) => s.account.isCash).toList();

    // Set preselected account if not already set
    if (_selectedAccount == null && widget.preselectedAccountId != null) {
      final match = cashAccounts.where((s) => s.account.id == widget.preselectedAccountId).firstOrNull;
      if (match != null) {
        _selectedAccount = match.account;
      }
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(24),
            Text(_tabIndex == 0 ? 'Contribute to ${widget.goal.name}' : 'Withdraw from ${widget.goal.name}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Gap(16),
            
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Contribute'), icon: Icon(Icons.add)),
                ButtonSegment(value: 1, label: Text('Withdraw'), icon: Icon(Icons.remove)),
              ],
              selected: {_tabIndex},
              onSelectionChanged: (set) => setState(() => _tabIndex = set.first),
            ),
            const Gap(24),

            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: ref.watch(currencyProvider) + ' ',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
            const Gap(16),

            DropdownButtonFormField<Account>(
              value: _selectedAccount,
              decoration: InputDecoration(
                labelText: _tabIndex == 0 ? 'From Account' : 'Return to Account',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              items: cashAccounts.map((stats) {
                return DropdownMenuItem<Account>(
                  value: stats.account,
                  child: Text('${stats.account.name} (Spendable: ${ref.watch(currencyProvider)}${stats.spendableBalance.toStringAsFixed(0)})'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedAccount = val);
              },
            ),
            const Gap(32),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _tabIndex == 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                foregroundColor: _tabIndex == 0 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onError,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_tabIndex == 0 ? 'Add Contribution' : 'Withdraw Amount', style: const TextStyle(fontSize: 16)),
            ),
            const Gap(24),
          ],
        ),
      ),
    );
  }
}
