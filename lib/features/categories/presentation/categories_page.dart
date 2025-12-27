import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
             return const Center(child: Text('No categories.'));
          }
          // Group by Type? Or just list with icon.
          return ListView.separated(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), // Added bottom padding
            itemCount: categories.length,
            separatorBuilder: (_,__) => const Divider(height: 1, indent: 64),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ListTile(
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onTap: () {
                  context.push('/add-category', extra: cat);
                },
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(cat.color == 0 ? 0xFF9E9E9E : cat.color).withOpacity(0.2),
                  child: Icon(IconData(cat.icon, fontFamily: 'MaterialIcons'), size: 20, color: Color(cat.color == 0 ? 0xFF9E9E9E : cat.color)),
                ),
                title: Text(cat.name, style: Theme.of(context).textTheme.bodyLarge),
                subtitle: Text(cat.type.name.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                trailing: PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 20),
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
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/add-category');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
    );
  }
}
