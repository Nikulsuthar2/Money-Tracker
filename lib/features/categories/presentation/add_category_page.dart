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
    Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
    // Accents
    Colors.redAccent, Colors.pinkAccent, Colors.purpleAccent, Colors.deepPurpleAccent,
    Colors.blueAccent, Colors.lightBlueAccent, Colors.cyanAccent, Colors.tealAccent,
    Colors.greenAccent, Colors.limeAccent, Colors.amberAccent, Colors.orangeAccent,
    Colors.deepOrangeAccent,
  ];

  final List<IconData> _icons = [
    // General
    Icons.category, Icons.label, Icons.star, Icons.favorite, Icons.bookmark,
    // Transport
    Icons.directions_car, Icons.train, Icons.flight, Icons.directions_bus, 
    Icons.directions_bike, Icons.directions_boat, Icons.local_taxi,
    // Food
    Icons.restaurant, Icons.shopping_cart, Icons.local_cafe, Icons.local_bar, 
    Icons.fastfood, Icons.icecream, Icons.local_pizza, Icons.bakery_dining,
    Icons.lunch_dining, Icons.kitchen, 
    // Health & Personal
    Icons.local_hospital, Icons.healing, Icons.medication, Icons.fitness_center,
    Icons.spa, Icons.pool, Icons.content_cut, Icons.shower,
    // Education & Work
    Icons.school, Icons.work, Icons.business_center, Icons.computer, 
    Icons.library_books, Icons.attach_file,
    // Entertainment
    Icons.movie, Icons.music_note, Icons.sports_esports, Icons.sports_soccer, 
    Icons.sports_basketball, Icons.sports_tennis, Icons.theater_comedy, Icons.casino,
    // Home & Family
    Icons.home, Icons.child_care, Icons.pets, Icons.stroller, Icons.family_restroom,
    Icons.chair, Icons.bed, Icons.local_laundry_service, Icons.build,
    // Tech & Bills
    Icons.smartphone, Icons.wifi, Icons.electric_bolt, Icons.water_drop, 
    Icons.description, Icons.receipt, Icons.credit_card, Icons.account_balance,
    Icons.savings, Icons.attach_money, Icons.security, Icons.shield,
    // Shopping
    Icons.shopping_bag, Icons.card_giftcard, Icons.diamond, Icons.watch,
    Icons.checkroom, Icons.local_offer,
    // Travel
    Icons.map, Icons.public, Icons.language, Icons.camera_alt, Icons.photo_camera,
    Icons.hotel, Icons.beach_access, Icons.park,
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
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: CategoryType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const Gap(16),
            InkWell(
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
              child: InputDecorator(
                 decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                 child: Row(
                   children: [
                      Container(
                        width: 24, height: 24, 
                        decoration: BoxDecoration(color: Color(_color), shape: BoxShape.circle)
                      ),
                      const Gap(12),
                      Text('#${_color.toRadixString(16).toUpperCase().substring(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                   ],
                 ),
              ),
            ),
            const Gap(16),
            
            InkWell(
              onTap: () async {
                 await showDialog(
                   context: context,
                   builder: (context) => AlertDialog(
                     title: const Text('Select Icon'),
                     content: SingleChildScrollView(
                       child: Wrap(
                         spacing: 12,
                         runSpacing: 12,
                         children: _icons.map((icon) => InkWell(
                           onTap: () {
                               setState(() => _icon = icon.codePoint);
                               Navigator.pop(context);
                           },
                           borderRadius: BorderRadius.circular(12),
                           child: Container(
                             width: 56,
                             height: 56,
                             decoration: BoxDecoration(
                               color: _icon == icon.codePoint ? Color(_color).withOpacity(0.2) : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                               borderRadius: BorderRadius.circular(16),
                               border: _icon == icon.codePoint ? Border.all(color: Color(_color), width: 2) : null,
                             ),
                             child: Icon(icon, color: _icon == icon.codePoint ? Color(_color) : Theme.of(context).colorScheme.onSurfaceVariant, size: 28),
                           ),
                         )).toList(),
                       ),
                     ),
                     actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
                   )
                 );
              },
              child: InputDecorator(
                 decoration: const InputDecoration(labelText: 'Icon', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                 child: Row(
                   children: [
                      Icon(IconData(_icon, fontFamily: 'MaterialIcons'), size: 24, color: Color(_color)),
                      const Gap(12),
                      const Text('Selected Icon', style: TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                   ],
                 ),
              ),
            ),
             const Gap(32),
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
