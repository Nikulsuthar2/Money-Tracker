import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/accounts/presentation/widgets/icon_selector_modal.dart';
import 'package:gap/gap.dart';

class AddCategoryPage extends ConsumerStatefulWidget {
  const AddCategoryPage({super.key, this.categoryToEdit});
  
  final Category? categoryToEdit;

  @override
  ConsumerState<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends ConsumerState<AddCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  CategoryType _type = CategoryType.expense;
  int _color = 0xFF4CAF50;
  String _iconData = 'material:57522';

  final List<Color> _colors = [
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
    Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
    Colors.redAccent, Colors.pinkAccent, Colors.purpleAccent, Colors.deepPurpleAccent,
    Colors.blueAccent, Colors.lightBlueAccent, Colors.cyanAccent, Colors.tealAccent,
    Colors.greenAccent, Colors.limeAccent, Colors.amberAccent, Colors.orangeAccent,
    Colors.deepOrangeAccent,
    Colors.red.shade900, Colors.green.shade900, Colors.blue.shade900, Colors.purple.shade900,
    Colors.orange.shade900, Colors.teal.shade900, Colors.grey.shade800,
    Colors.pink.shade100, Colors.blue.shade100, Colors.green.shade100, Colors.orange.shade100, 
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.categoryToEdit;
    _nameController = TextEditingController(text: c?.name ?? '');
    if (c != null) {
      _type = c.type;
      _color = c.color;
      _iconData = c.iconData;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final cat = widget.categoryToEdit ?? Category();
      cat
        ..name = _nameController.text.trim()
        ..type = _type
        ..color = _color
        ..icon = _iconData.startsWith('material:') ? (int.tryParse(_iconData.replaceFirst('material:', '')) ?? 57522) : 57522
        ..iconData = _iconData;
      
      if (widget.categoryToEdit != null) {
        await ref.read(categoriesRepositoryProvider).updateCategory(cat);
      } else {
        await ref.read(categoriesRepositoryProvider).addCategory(cat);
      }
      
      if (mounted) context.pop();
    }
  }

  Widget _buildSelectedIcon() {
    if (_iconData.startsWith('emoji:')) {
      return Text(_iconData.replaceFirst('emoji:', ''), style: const TextStyle(fontSize: 24));
    } else if (_iconData.startsWith('asset:')) {
      return Image.asset(_iconData.replaceFirst('asset:', ''), width: 24, height: 24);
    } else {
      final code = int.tryParse(_iconData.replaceFirst('material:', '')) ?? Icons.category.codePoint;
      return Icon(IconData(code, fontFamily: 'MaterialIcons'), size: 24, color: Color(_color));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryToEdit == null ? 'Add Category' : 'Edit Category')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<CategoryType>(
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                segments: const [
                  ButtonSegment(value: CategoryType.expense, label: Text('Expense')),
                  ButtonSegment(value: CategoryType.income, label: Text('Income')),
                  ButtonSegment(value: CategoryType.common, label: Text('Common')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
                showSelectedIcon: false,
              ),
            ),
            const Gap(24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name', 
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                )
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const Gap(24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => FractionallySizedBox(
                          heightFactor: 0.8,
                          child: IconSelectorModal(
                            onIconSelected: (val) {
                              setState(() {
                                _iconData = val;
                              });
                            },
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
                            width: 44, height: 44, 
                            decoration: BoxDecoration(
                              color: Color(_color).withOpacity(0.2), 
                              shape: BoxShape.circle
                            ),
                            child: Center(child: _buildSelectedIcon()),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Icon', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                const Gap(2),
                                const Text('Change', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ]
                            )
                          )
                        ]
                      )
                    )
                  )
                ),
                const Gap(16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                       await showDialog(
                         context: context,
                         builder: (context) => AlertDialog(
                           title: const Text('Select Color'),
                           content: SingleChildScrollView(
                             child: Wrap(
                               spacing: 12,
                               runSpacing: 12,
                               children: _colors.map((c) => InkWell(
                                 onTap: () {
                                     setState(() => _color = c.value);
                                     Navigator.pop(context);
                                 },
                                 child: Container(
                                   width: 42,
                                   height: 42,
                                   decoration: BoxDecoration(
                                     color: c,
                                     shape: BoxShape.circle,
                                     border: _color == c.value ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                                     boxShadow: [
                                       BoxShadow(color: c.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)
                                     ]
                                   ),
                                   child: _color == c.value ? const Icon(Icons.check, color: Colors.white, size: 24) : null,
                                 ),
                               )).toList(),
                             ),
                           ),
                           actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
                         )
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
                            width: 44, height: 44, 
                            decoration: BoxDecoration(color: Color(_color), shape: BoxShape.circle)
                          ),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Color', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                const Gap(2),
                                Text('#${_color.toRadixString(16).toUpperCase().substring(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                              ]
                            )
                          )
                        ]
                      )
                    )
                  )
                ),
              ],
            ),
            const Gap(32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                elevation: 0,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Category'),
            ),
          ],
        ),
      ),
    );
  }
}


