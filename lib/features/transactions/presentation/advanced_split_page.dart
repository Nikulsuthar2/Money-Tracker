import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:money_manager/features/people/domain/person.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/people/data/people_repository.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/features/transactions/presentation/add_transaction_page.dart' show ExpenseSplitInput;

class AdvancedExpenseItem {
  double amount;
  String note;
  int? categoryId;
  int paidByPersonId;
  List<ExpenseSplitInput> splits;

  AdvancedExpenseItem({
    this.amount = 0.0,
    this.note = '',
    this.categoryId,
    this.paidByPersonId = 0, // 0 = me
    List<ExpenseSplitInput>? splits,
  }) : splits = splits ?? [ExpenseSplitInput()];
}

class AdvancedSplitPage extends ConsumerStatefulWidget {
  final List<AdvancedExpenseItem> initialItems;
  final List<Person> people;
  final List<Category> categories;

  const AdvancedSplitPage({
    super.key,
    required this.initialItems,
    required this.people,
    required this.categories,
  });

  @override
  ConsumerState<AdvancedSplitPage> createState() => _AdvancedSplitPageState();
}

class _AdvancedSplitPageState extends ConsumerState<AdvancedSplitPage> {
  late List<AdvancedExpenseItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.initialItems.isNotEmpty 
        ? widget.initialItems 
        : [AdvancedExpenseItem()];
  }

  void _addItem() {
    setState(() {
      _items.add(AdvancedExpenseItem());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _submit() {
    // Validate
    for (var item in _items) {
      if (item.amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All items must have an amount > 0')));
        return;
      }
      double splitTotal = 0;
      for (var s in item.splits) {
        splitTotal += double.tryParse(s.amountController.text) ?? 0.0;
      }
      if ((splitTotal - item.amount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Splits for item "${item.note}" must equal ${item.amount}')));
        return;
      }
    }
    Navigator.pop(context, _items);
  }

  Widget _buildIcon(String iconStr, Color color, {double size = 32}) {
    if (iconStr.startsWith('emoji:')) {
      final emoji = iconStr.replaceFirst('emoji:', '');
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
      );
    } else if (iconStr.startsWith('asset:')) {
      final assetPath = iconStr.replaceFirst('asset:', '');
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Image.asset(assetPath, width: size * 0.5, height: size * 0.5, fit: BoxFit.contain),
      );
    }
    final code = int.tryParse(iconStr.replaceFirst('material:', '')) ?? Icons.category.codePoint;
    return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(IconData(code, fontFamily: 'MaterialIcons'), color: color, size: size * 0.5),
      );
  }

  Widget _buildSelector({
    required String label,
    required Widget leading,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            leading,
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]
              )
            ),
            Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ]
        )
      )
    );
  }

  void _showCategoryPicker(int itemIndex) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Category'),
        contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.categories.length + 1,
            itemBuilder: (ctx, index) {
              if (index == 0) {
                 return ListTile(
                    leading: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.surfaceContainerHighest), child: const Icon(Icons.do_not_disturb_alt)),
                    title: const Text('None'),
                    onTap: () {
                      setState(() => _items[itemIndex].categoryId = null);
                      Navigator.pop(ctx);
                    },
                 );
              }
              final c = widget.categories[index - 1];
              return ListTile(
                leading: _buildIcon(c.iconData, Color(c.color), size: 40),
                title: Text(c.name),
                onTap: () {
                  setState(() => _items[itemIndex].categoryId = c.id);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPersonPicker(int itemIndex, bool isWhoPaid, int? splitIndex) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isWhoPaid ? 'Who Paid?' : 'Split For'),
        contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.people.length + 1,
            itemBuilder: (ctx, index) {
              if (index == 0) {
                 return ListTile(
                    leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: const Icon(Icons.account_balance_wallet)),
                    title: const Text('Me (My Account)'),
                    onTap: () {
                      setState(() {
                         if (isWhoPaid) {
                           _items[itemIndex].paidByPersonId = 0;
                         } else if (splitIndex != null) {
                           _items[itemIndex].splits[splitIndex].personId = 0;
                         }
                      });
                      Navigator.pop(ctx);
                    },
                 );
              }
              final p = widget.people[index - 1];
              return ListTile(
                leading: CircleAvatar(
                   backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                   child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?'),
                ),
                title: Text(p.name),
                onTap: () {
                  setState(() {
                     if (isWhoPaid) {
                       _items[itemIndex].paidByPersonId = p.id;
                     } else if (splitIndex != null) {
                       _items[itemIndex].splits[splitIndex].personId = p.id;
                     }
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showAddPersonDialog(context, ref);
            },
            child: const Text('Create New Person'),
          )
        ],
      ),
    );
  }

  Future<void> _showAddPersonDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Friend'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final person = Person()..name = name;
                await ref.read(peopleRepositoryProvider).addPerson(person);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $name')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Split Items'),
        centerTitle: true,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _submit,
          ),
          const Gap(8),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: FilledButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Another Item'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            );
          }

          final item = _items[index];
          final category = item.categoryId != null ? widget.categories.where((c) => c.id == item.categoryId).firstOrNull : null;
          final whoPaid = item.paidByPersonId == 0 ? null : widget.people.where((p) => p.id == item.paidByPersonId).firstOrNull;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Item ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
                      ),
                      if (_items.length > 1)
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _removeItem(index)),
                    ],
                  ),
                  const Gap(16),
                  TextFormField(
                    initialValue: item.amount > 0 ? item.amount.toString() : '',
                    decoration: InputDecoration(
                       labelText: 'Amount',
                       prefixText: currency,
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                       filled: true,
                       fillColor: theme.colorScheme.surface,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => item.amount = double.tryParse(v) ?? 0.0,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Gap(12),
                  TextFormField(
                    initialValue: item.note,
                    decoration: InputDecoration(
                       labelText: 'Item Name / Note',
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                       filled: true,
                       fillColor: theme.colorScheme.surface,
                       prefixIcon: const Icon(Icons.notes),
                    ),
                    onChanged: (v) => item.note = v,
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelector(
                          label: 'Category',
                          title: category?.name ?? 'None',
                          leading: category != null 
                             ? _buildIcon(category.iconData, Color(category.color), size: 36)
                             : Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.surfaceContainerHighest), child: const Icon(Icons.do_not_disturb_alt, size: 18)),
                          onTap: () => _showCategoryPicker(index),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: _buildSelector(
                          label: 'Paid By',
                          title: whoPaid?.name ?? 'Me',
                          leading: CircleAvatar(
                             radius: 18,
                             backgroundColor: whoPaid != null ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primaryContainer,
                             child: whoPaid != null 
                               ? Text(whoPaid.name[0].toUpperCase())
                               : const Icon(Icons.account_balance_wallet, size: 18),
                          ),
                          onTap: () => _showPersonPicker(index, true, null),
                        ),
                      ),
                    ],
                  ),
                  const Gap(24),
                  const Divider(),
                  const Gap(8),
                  const Text('Split Between', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Gap(12),
                  ...item.splits.asMap().entries.map((entry) {
                    final splitIndex = entry.key;
                    final split = entry.value;
                    final splitPerson = split.personId == 0 ? null : widget.people.where((p) => p.id == split.personId).firstOrNull;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildSelector(
                              label: 'Person',
                              title: splitPerson?.name ?? 'Me',
                              leading: CircleAvatar(
                                 radius: 16,
                                 backgroundColor: splitPerson != null ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primaryContainer,
                                 child: splitPerson != null 
                                   ? Text(splitPerson.name[0].toUpperCase(), style: const TextStyle(fontSize: 14))
                                   : const Icon(Icons.account_balance_wallet, size: 16),
                              ),
                              onTap: () => _showPersonPicker(index, false, splitIndex),
                            ),
                          ),
                          const Gap(8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: split.amountController,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                prefixText: currency,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                isDense: true,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          if (item.splits.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  item.splits.removeAt(splitIndex);
                                });
                              },
                            ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Person to Split'),
                      onPressed: () {
                        setState(() {
                          item.splits.add(ExpenseSplitInput());
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
