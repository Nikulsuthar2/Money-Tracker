import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:gap/gap.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  CategoryType? _filterType; // null = All

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Column(
        children: [
           // Filters
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             child: SingleChildScrollView(
               scrollDirection: Axis.horizontal,
               child: Row(
                 children: [
                   FilterChip(
                     label: const Text('All'), 
                     selected: _filterType == null,
                     onSelected: (b) => setState(() => _filterType = null),
                     showCheckmark: false,
                   ),
                   const Gap(8),
                   FilterChip(
                     label: const Text('Income'), 
                     selected: _filterType == CategoryType.income,
                     onSelected: (b) => setState(() => _filterType = CategoryType.income),
                     showCheckmark: false,
                     avatar: _filterType == CategoryType.income ? const Icon(Symbols.check, size: 16) : null,
                   ),
                   const Gap(8),
                   FilterChip(
                     label: const Text('Expense'), 
                     selected: _filterType == CategoryType.expense,
                     onSelected: (b) => setState(() => _filterType = CategoryType.expense),
                     showCheckmark: false,
                     avatar: _filterType == CategoryType.expense ? const Icon(Symbols.check, size: 16) : null,
                   ),
                   const Gap(8),
                   FilterChip(
                     label: const Text('Common'), 
                     selected: _filterType == CategoryType.common,
                     onSelected: (b) => setState(() => _filterType = CategoryType.common),
                     showCheckmark: false,
                     avatar: _filterType == CategoryType.common ? const Icon(Symbols.check, size: 16) : null,
                   ),
                 ],
               ),
             ),
           ),
           const Divider(height: 1),

           Expanded(
             child: categoriesAsync.when(
                data: (categories) {
                  var filtered = categories;
                  if (_filterType != null) {
                    filtered = categories.where((c) {
                       if (_filterType == CategoryType.income) {
                          return c.type == CategoryType.income || c.type == CategoryType.common;
                       } else if (_filterType == CategoryType.expense) {
                          return c.type == CategoryType.expense || c.type == CategoryType.common;
                       } else if (_filterType == CategoryType.common) {
                           return c.type == CategoryType.common;
                       }
                       return c.type == _filterType;
                    }).toList();
                  }

                  if (filtered.isEmpty) {
                     return const Center(child: Text('No categories found.'));
                  }
                  
                  // Sort: Type then Name
                  filtered.sort((a,b) {
                     final typeC = a.type.index.compareTo(b.type.index);
                     if (typeC != 0) return typeC;
                     return a.name.compareTo(b.name);
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final cat = filtered[index];
                      return Card(
                         elevation: 0,
                         color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                         margin: const EdgeInsets.only(bottom: 8),
                         child: ListTile(
                           visualDensity: VisualDensity.compact,
                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                           onTap: () {
                             context.push('/add-category', extra: cat);
                           },
                           leading: CircleAvatar(
                             radius: 20,
                             backgroundColor: Color(cat.color == 0 ? 0xFF9E9E9E : cat.color).withOpacity(0.2),
                             child: Icon(IconData(cat.icon, fontFamily: 'MaterialIcons'), size: 22, color: Color(cat.color == 0 ? 0xFF9E9E9E : cat.color)),
                           ),
                           title: Text(cat.name, style: Theme.of(context).textTheme.titleMedium),
                           subtitle: Text(cat.type.name.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.secondary)),
                           trailing: PopupMenuButton(
                             icon: const Icon(Symbols.more_vert, size: 20),
                             padding: EdgeInsets.zero,
                             itemBuilder: (context) => [
                               PopupMenuItem(
                                 child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                 onTap: () {
                                    Future.delayed(Duration.zero, () {
                                      if (context.mounted) {
                                        showDialog(context: context, builder: (d) => AlertDialog(
                                           title: const Text('Delete Category?'),
                                           content: const Text('This will delete the category. Transactions will lose this category.'),
                                           actions: [
                                             TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
                                             TextButton(onPressed: () async {
                                                 await ref.read(categoriesRepositoryProvider).deleteCategory(cat.id);
                                                 if (context.mounted) Navigator.pop(d);
                                             }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                           ],
                                         ));
                                      }
                                    });
                                 },
                               ),
                             ],
                           ),
                         ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
           ),
         ],
       ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/add-category');
        },
        icon: const Icon(Symbols.add),
        label: const Text('New Category'),
      ),
    );
  }
}


