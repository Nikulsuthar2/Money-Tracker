import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/accounts/presentation/widgets/icon_selector_modal.dart';
import 'package:gap/gap.dart';

class AddAccountPage extends ConsumerStatefulWidget {
  const AddAccountPage({super.key, this.accountToEdit});

  final Account? accountToEdit;

  @override
  ConsumerState<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends ConsumerState<AddAccountPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _interestRateController;
  late TextEditingController _customEmojiController;
  
  AccountType _type = AccountType.cash;
  int _color = 0xFF2196F3;
  String _iconData = 'emoji:💵';

  final Map<AccountType, List<String>> _suggestedIcons = {
    AccountType.cash: ['emoji:💵', 'emoji:💰', 'emoji:🪙', 'emoji:💶'],
    AccountType.bank: ['emoji:🏦', 'emoji:🏛️', 'emoji:🏧', 'emoji:🏢'],
    AccountType.creditCard: ['emoji:💳', 'emoji:🛍️', 'emoji:💳'],
    AccountType.pf: ['emoji:🗄️', 'emoji:📜', 'emoji:☂️'],
    AccountType.investment: ['emoji:📈', 'emoji:💹', 'emoji:📊', 'emoji:🚀'],
    AccountType.loan: ['emoji:💸', 'emoji:📉', 'emoji:🤝'],
    AccountType.eWallet: ['emoji:📱', 'emoji:📲', 'emoji:🤑'],
    AccountType.other: ['emoji:💼', 'emoji:📁', 'emoji:📦'],
  };

  @override
  void initState() {
    super.initState();
    final account = widget.accountToEdit;
    _nameController = TextEditingController(text: account?.name ?? '');
    _balanceController = TextEditingController(text: account?.openingBalance.toString() ?? '');
    _interestRateController = TextEditingController(text: account?.interestRate?.toString() ?? '');
    _customEmojiController = TextEditingController();

    if (account != null) {
      _type = account.type;
      _color = account.color;
      _iconData = account.iconData;
      if (_iconData.startsWith('emoji:')) {
        _customEmojiController.text = _iconData.replaceFirst('emoji:', '');
      }
    } else {
      _iconData = _suggestedIcons[_type]!.first;
      _customEmojiController.text = _iconData.replaceFirst('emoji:', '');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _interestRateController.dispose();
    _customEmojiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final balance = double.tryParse(_balanceController.text) ?? 0.0;
      final interestRate = double.tryParse(_interestRateController.text);
      
      final account = widget.accountToEdit ?? Account();
      account
        ..name = name
        ..type = _type
        ..openingBalance = balance
        ..interestRate = interestRate
        ..color = _color
        ..iconData = _iconData;

      if (widget.accountToEdit != null) {
        await ref.read(accountsRepositoryProvider).updateAccount(account);
      } else {
        await ref.read(accountsRepositoryProvider).addAccount(account);
      }

      if (mounted) {
        context.pop();
      }
    }
  }

  String _formatType(AccountType type) {
    switch (type) {
      case AccountType.cash: return 'Cash (Wallet)';
      case AccountType.bank: return 'Bank Account';
      case AccountType.creditCard: return 'Credit Card';
      case AccountType.pf: return 'PF Account';
      case AccountType.investment: return 'Investment';
      case AccountType.loan: return 'Loan';
      case AccountType.eWallet: return 'E-Wallet';
      case AccountType.other: return 'Other';
    }
  }

  Widget _buildIcon(String iconStr) {
    if (iconStr.startsWith('emoji:')) {
      final emoji = iconStr.replaceFirst('emoji:', '');
      return Text(emoji, style: const TextStyle(fontSize: 28));
    } else if (iconStr.startsWith('material:')) {
      final code = int.tryParse(iconStr.replaceFirst('material:', ''));
      if (code != null) return Icon(IconData(code, fontFamily: 'MaterialIcons'), size: 28, color: Theme.of(context).colorScheme.primary);
    } else if (iconStr.startsWith('asset:')) {
      final assetPath = iconStr.replaceFirst('asset:', '');
      return Image.asset(assetPath, width: 28, height: 28, fit: BoxFit.contain);
    }
    return Icon(Symbols.account_balance_wallet, size: 28, color: Theme.of(context).colorScheme.primary);
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    final isInvestment = _type == AccountType.investment;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountToEdit == null ? 'Add Account' : 'Edit Account'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Account Type
            DropdownButtonFormField<AccountType>(
              value: _type,
              decoration: inputDecoration.copyWith(labelText: 'Account Type'),
              borderRadius: BorderRadius.circular(12),
              items: AccountType.values.map((t) {
                return DropdownMenuItem(value: t, child: Text(_formatType(t)));
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _type = v;
                    // Auto-select first suggested icon
                    _iconData = _suggestedIcons[_type]!.first;
                    _customEmojiController.text = _iconData.replaceFirst('emoji:', '');
                  });
                }
              },
            ),
            const Gap(24),

            // Icon Picker
            const Text('Account Icon', style: TextStyle(fontWeight: FontWeight.bold)),
            const Gap(8),
            Row(
              children: [
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                      builder: (ctx) => IconSelectorModal(
                        onIconSelected: (val) {
                          setState(() => _iconData = val);
                        }
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Theme.of(context).colorScheme.surfaceContainerHighest,
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                     ),
                     child: _buildIcon(_iconData),
                  ),
                ),
                const Gap(16),
                Text('Tap to change icon', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]
            ),
            const Gap(24),

            // Name & Balance
            TextFormField(
              controller: _nameController,
              decoration: inputDecoration.copyWith(labelText: 'Account Name', hintText: 'e.g. SBI Savings'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const Gap(16),
            TextFormField(
              controller: _balanceController,
              decoration: inputDecoration.copyWith(labelText: 'Opening Balance'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v!.isNotEmpty && double.tryParse(v) == null ? 'Invalid number' : null,
            ),
            const Gap(16),

            // Interest Rate / P&L
            TextFormField(
              controller: _interestRateController,
              decoration: inputDecoration.copyWith(
                labelText: isInvestment ? 'Profit/Loss (%)' : 'Interest Rate (%)',
                hintText: isInvestment ? 'e.g. 12.5' : 'e.g. 4.5',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v != null && v.isNotEmpty && double.tryParse(v) == null ? 'Invalid number' : null,
            ),
            const Gap(32),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Account', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

