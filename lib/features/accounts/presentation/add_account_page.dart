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
  late TextEditingController _reservedLimitController;
  AccountType _type = AccountType.wallet;
  int _color = 0xFF2196F3;
  int _icon = 57522; // wallet



  // Local state for buckets
  List<AccountBucket> _buckets = [];

  @override
  void initState() {
    super.initState();
    final account = widget.accountToEdit;
    _nameController = TextEditingController(text: account?.name ?? '');
    _balanceController = TextEditingController(text: account?.openingBalance.toString() ?? '0.0');
    _reservedLimitController = TextEditingController(text: account?.reservedLimit.toString() ?? '0.0');
    if (account != null) {
      _type = account.type;
      _color = account.color;
      _icon = account.icon;
      if (account.buckets.isNotEmpty) {
        _buckets = List.from(account.buckets);
      }
    }
  }

  void _addBucket() {
      final controller = TextEditingController();
      showDialog(context: context, builder: (c) => AlertDialog(
         title: const Text('Add Fund Category'),
         content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Car Fund')),
         actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
            FilledButton(onPressed: () {
               if (controller.text.isNotEmpty) {
                  setState(() {
                     _buckets.add(AccountBucket()..name = controller.text..balance = 0.0);
                  });
               }
               Navigator.pop(c);
            }, child: const Text('Add'))
         ],
      ));
  }

  void _removeBucket(int index) {
     setState(() {
        _buckets.removeAt(index);
     });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _reservedLimitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final balance = double.tryParse(_balanceController.text) ?? 0.0;
      final reservedLimit = double.tryParse(_reservedLimitController.text) ?? 0.0;
      
      final account = widget.accountToEdit ?? Account();
      account
        ..name = name
        ..type = _type
        ..openingBalance = balance
        ..reservedLimit = reservedLimit
        ..color = _color
        ..color = _color
        ..icon = _icon // Semicolon here
        ..buckets = _buckets;

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
    final inputDecoration = InputDecoration(
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Add Account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: inputDecoration.copyWith(labelText: 'Account Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const Gap(16),
            DropdownButtonFormField<AccountType>(
              initialValue: _type,
              decoration: inputDecoration.copyWith(labelText: 'Type'),
              borderRadius: BorderRadius.circular(12),
              items: AccountType.values.map((t) {
                return DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()));
              }).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const Gap(16),
            TextFormField(
              controller: _balanceController,
              decoration: inputDecoration.copyWith(labelText: 'Opening Balance'),
              keyboardType: TextInputType.number,
              validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid number' : null,
            ),
            const Gap(16),
            TextFormField(
              controller: _reservedLimitController,
              decoration: inputDecoration.copyWith(
                 labelText: 'Reserved Amount Limit',
                 helperText: 'Max amount to keep reserved in this account',
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v != null && v.isNotEmpty && double.tryParse(v) == null ? 'Invalid number' : null,
            ),
            const Gap(24),
            

            const Gap(8),
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  const Text('Fund Allocation Categories', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(onPressed: _addBucket, icon: const Icon(Icons.add_circle, color: Colors.teal)),
               ],
            ),
             if (_buckets.isEmpty)
              const Text('No custom categories added.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            
            ..._buckets.asMap().entries.map((e) => ListTile(
               dense: true,
               contentPadding: EdgeInsets.zero,
               leading: const Icon(Icons.pie_chart, size: 20),
               title: Text(e.value.name ?? 'Unnamed'),
               trailing: IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => _removeBucket(e.key)),
            )),
            const Gap(24),
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

