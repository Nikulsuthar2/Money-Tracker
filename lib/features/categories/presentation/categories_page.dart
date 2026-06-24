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

class _CategoriesPageState extends ConsumerState<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildIcon(Category cat, double size) {
    if (cat.iconData.startsWith('emoji:')) {
      return Text(
        cat.iconData.replaceFirst('emoji:', ''),
        style: TextStyle(fontSize: size),
      );
    } else if (cat.iconData.startsWith('asset:')) {
      return Image.asset(
        cat.iconData.replaceFirst('asset:', ''),
        width: size,
        height: size,
      );
    } else {
      final code =
          int.tryParse(cat.iconData.replaceFirst('material:', '')) ?? cat.icon;
      return Icon(
        IconData(code, fontFamily: 'MaterialIcons'),
        size: size,
        color: Color(cat.color == 0 ? 0xFF9E9E9E : cat.color),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Category',
            onPressed: () {
              context.push('/add-category');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Categories',
            onPressed: () {
              ref.invalidate(categoriesStreamProvider);
            },
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Stylish TabBar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(22),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.circular(22),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Theme.of(context).colorScheme.primary,
              ),
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Income'),
                Tab(text: 'Expense'),
                Tab(text: 'Common'),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                var filtered = categories;
                if (_tabController.index == 1) {
                  filtered = categories
                      .where(
                        (c) =>
                            c.type == CategoryType.income ||
                            c.type == CategoryType.common,
                      )
                      .toList();
                } else if (_tabController.index == 2) {
                  filtered = categories
                      .where(
                        (c) =>
                            c.type == CategoryType.expense ||
                            c.type == CategoryType.common,
                      )
                      .toList();
                } else if (_tabController.index == 3) {
                  filtered = categories
                      .where((c) => c.type == CategoryType.common)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        Gap(16),
                        Text(
                          'No categories found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Sort: Type then Name
                filtered.sort((a, b) {
                  final typeC = a.type.index.compareTo(b.type.index);
                  if (typeC != 0) return typeC;
                  return a.name.compareTo(b.name);
                });

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 80,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final cat = filtered[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            context.push('/add-category', extra: cat);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      cat.color == 0 ? 0xFF9E9E9E : cat.color,
                                    ).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(child: _buildIcon(cat, 24)),
                                ),
                                const Gap(16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Gap(4),
                                      Text(
                                        cat.type.name.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
                                    PopupMenuItem(
                                      child: const Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 20),
                                          Gap(12),
                                          Text('Edit'),
                                        ],
                                      ),
                                      onTap: () {
                                        Future.delayed(Duration.zero, () {
                                          if (context.mounted) {
                                            context.push(
                                              '/add-category',
                                              extra: cat,
                                            );
                                          }
                                        });
                                      },
                                    ),
                                    const PopupMenuDivider(),
                                    PopupMenuItem(
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          Gap(12),
                                          Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        Future.delayed(Duration.zero, () {
                                          if (context.mounted) {
                                            showDialog(
                                              context: context,
                                              builder: (d) => AlertDialog(
                                                title: const Text(
                                                  'Delete Category?',
                                                ),
                                                content: const Text(
                                                  'This will permanently delete the category. Past transactions will lose this category reference.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(d),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    onPressed: () async {
                                                      await ref
                                                          .read(
                                                            categoriesRepositoryProvider,
                                                          )
                                                          .deleteCategory(
                                                            cat.id,
                                                          );
                                                      if (context.mounted)
                                                        Navigator.pop(d);
                                                    },
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
        heroTag: null,
        onPressed: () {
          context.push('/add-category');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
    );
  }
}
