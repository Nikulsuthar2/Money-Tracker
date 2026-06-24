import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/accounts/presentation/widgets/icon_selector_modal.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:circle_flags/circle_flags.dart';
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
  String _currency = 'INR';

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
    _balanceController = TextEditingController(text: account?.openingBalance.toString() ?? '0');
    _interestRateController = TextEditingController(text: account?.interestRate?.toString() ?? '0');
    _customEmojiController = TextEditingController();

    if (account != null) {
      _type = account.type;
      _color = account.color;
      _iconData = account.iconData;
      _currency = account.currency;
      if (_iconData.startsWith('emoji:')) {
        _customEmojiController.text = _iconData.replaceFirst('emoji:', '');
      }
    } else {
      _iconData = _suggestedIcons[_type]!.first;
      _customEmojiController.text = _iconData.replaceFirst('emoji:', '');
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) setState(() => _currency = ref.read(currencyProvider));
      });
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
      final interestRate = double.tryParse(_interestRateController.text) ?? 0.0;
      
      final account = widget.accountToEdit ?? Account();
      account
        ..name = name
        ..type = _type
        ..currency = _currency
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
      case AccountType.cash: return '💵 Cash (Wallet)';
      case AccountType.bank: return '🏦 Bank Account';
      case AccountType.creditCard: return '💳 Credit Card';
      case AccountType.pf: return '🗄️ PF Account';
      case AccountType.investment: return '📈 Investment';
      case AccountType.loan: return '💸 Loan';
      case AccountType.eWallet: return '📱 E-Wallet';
      case AccountType.other: return '💼 Other';
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
    return Icon(Icons.account_balance_wallet, size: 28, color: Theme.of(context).colorScheme.primary);
  }

  Widget _buildFlag(String cur, double size) {
    final flagCode = currencyFlags[cur] ?? 'us';
    if (flagCode == 'eu') {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF003399)),
        child: Center(
          child: Icon(Icons.euro, color: const Color(0xFFFFCC00), size: size * 0.65),
        ),
      );
    }
    return CircleFlag(flagCode, size: size);
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      filled: false,
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
            const Text('Account Type', style: TextStyle(fontWeight: FontWeight.bold)),
            const Gap(8),
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Select Account Type'),
                    contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: AccountType.values.length,
                        itemBuilder: (ctx, index) {
                          final t = AccountType.values[index];
                          return ListTile(
                            leading: Text(_formatType(t).split(' ')[0], style: const TextStyle(fontSize: 24)),
                            title: Text(_formatType(t).substring(_formatType(t).indexOf(' ') + 1)),
                            selected: _type == t,
                            selectedTileColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                            onTap: () {
                              setState(() {
                                _type = t;
                                _iconData = _suggestedIcons[_type]!.first;
                                _customEmojiController.text = _iconData.replaceFirst('emoji:', '');
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(_formatType(_type).split(' ')[0], style: const TextStyle(fontSize: 24)),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Account Type', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          Text(_formatType(_type).substring(_formatType(_type).indexOf(' ') + 1), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
                        ]
                      )
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ]
                )
              )
            ),
            const Gap(24),

            // Icon Picker
            const Text('Account Icon', style: TextStyle(fontWeight: FontWeight.bold)),
            const Gap(8),
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
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: _buildIcon(_iconData),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Icon', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
                          Text('Personalize your account appearance', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ]
                      )
                    ),
                    Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ]
                )
              )
            ),
            const Gap(24),

            // Name & Balance
            TextFormField(
              controller: _nameController,
              decoration: inputDecoration.copyWith(labelText: 'Account Name', hintText: 'e.g. SBI Savings'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const Gap(16),

            // Currency Selector
            InkWell(
              onTap: () {
                 showDialog(context: context, builder: (c) => SimpleDialog(
                   title: const Text('Select Currency'),
                   children: supportedCurrencies.map((cur) => SimpleDialogOption(
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                     onPressed: () {
                       setState(() => _currency = cur);
                       Navigator.pop(c);
                     },
                     child: Row(
                       children: [
                         _buildFlag(cur, 24),
                         const Gap(16),
                         Text(cur, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                         const Gap(16),
                         Expanded(child: Text(currencyNames[cur] ?? '', style: const TextStyle(fontSize: 16))),
                       ],
                     ),
                   )).toList(),
                 ));
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildFlag(_currency, 24),
                    const Gap(16),
                    Text(_currency, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Gap(8),
                    Expanded(child: Text(currencyNames[_currency] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14), overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
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
                elevation: 0,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
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

