import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
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
  AccountType _type = AccountType.wallet;
  int _color = 0xFF2196F3;
  int _icon = 57522; // wallet

  @override
  void initState() {
    super.initState();
    final account = widget.accountToEdit;
    _nameController = TextEditingController(text: account?.name ?? '');
    _balanceController = TextEditingController(text: account?.openingBalance.toString() ?? '0.0');
    if (account != null) {
      _type = account.type;
      _color = account.color;
      _icon = account.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final balance = double.tryParse(_balanceController.text) ?? 0.0;
      
      final account = widget.accountToEdit ?? Account();
      account
        ..name = name
        ..type = _type
        ..openingBalance = balance
        ..color = _color
        ..icon = _icon;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Account Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const Gap(16),
            DropdownButtonFormField<AccountType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: AccountType.values.map((t) {
                return DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()));
              }).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const Gap(16),
            TextFormField(
              controller: _balanceController,
              decoration: const InputDecoration(labelText: 'Opening Balance'),
              keyboardType: TextInputType.number,
              validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid number' : null,
            ),
            const Gap(24),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save Account'),
            ),
          ],
        ),
      ),
    );
  }
}
