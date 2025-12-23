import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';
import 'package:money_manager/features/categories/domain/category.dart';
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
  int _icon = 57522; // wallet

  final List<Color> _colors = [
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
    Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    Colors.brown, Colors.grey, Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.categoryToEdit;
    _nameController = TextEditingController(text: c?.name ?? '');
    if (c != null) {
      _type = c.type;
      _color = c.color;
      _icon = c.icon;
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
        ..icon = _icon;
      
      if (widget.categoryToEdit != null) {
        await ref.read(categoriesRepositoryProvider).updateCategory(cat);
      } else {
        await ref.read(categoriesRepositoryProvider).addCategory(cat);
      }
      
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Category')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const Gap(16),
            DropdownButtonFormField<CategoryType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: CategoryType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const Gap(16),
            const Text('Color'),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((c) => InkWell(
                onTap: () => setState(() => _color = c.value),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: _color == c.value ? Border.all(color: Colors.white, width: 3) : null,
                  ),
                  child: _color == c.value ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                ),
              )).toList(),
            ),
             const Gap(24),
             ElevatedButton(
               onPressed: _save,
               style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
               child: const Text('Save Category'),
             ),
          ],
        ),
      ),
    );
  }
}
