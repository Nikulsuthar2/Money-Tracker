import 'package:material_symbols_icons/symbols.dart';
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
    // Shades
    Colors.red.shade900, Colors.green.shade900, Colors.blue.shade900, Colors.purple.shade900,
    Colors.orange.shade900, Colors.teal.shade900, Colors.grey.shade800,
    Colors.pink.shade100, Colors.blue.shade100, Colors.green.shade100, Colors.orange.shade100, 
  ];

  final List<IconData> _icons = [
    // General
    Symbols.category, Symbols.label, Symbols.star, Symbols.favorite, Symbols.bookmark,
    // Transport
    Symbols.directions_car, Symbols.train, Symbols.flight, Symbols.directions_bus, 
    Symbols.directions_bike, Symbols.directions_boat, Symbols.local_taxi,
    // Food
    Symbols.restaurant, Symbols.shopping_cart, Symbols.local_cafe, Symbols.local_bar, 
    Symbols.fastfood, Symbols.icecream, Symbols.local_pizza, Symbols.bakery_dining,
    Symbols.lunch_dining, Symbols.kitchen, 
    // Health & Personal
    Symbols.local_hospital, Symbols.healing, Symbols.medication, Symbols.fitness_center,
    Symbols.spa, Symbols.pool, Symbols.content_cut, Symbols.shower,
    // Education & Work
    Symbols.school, Symbols.work, Symbols.business_center, Symbols.computer, 
    Symbols.library_books, Symbols.attach_file,
    // Entertainment
    Symbols.movie, Symbols.music_note, Symbols.sports_esports, Symbols.sports_soccer, 
    Symbols.sports_basketball, Symbols.sports_tennis, Symbols.theater_comedy, Symbols.casino,
    // Home & Family
    Symbols.home, Symbols.child_care, Symbols.pets, Symbols.stroller, Symbols.family_restroom,
    Symbols.chair, Symbols.bed, Symbols.local_laundry_service, Symbols.build,
    // Tech & Bills
    Symbols.smartphone, Symbols.wifi, Symbols.electric_bolt, Symbols.water_drop, 
    Symbols.description, Symbols.receipt, Symbols.credit_card, Symbols.account_balance,
    Symbols.savings, Symbols.attach_money, Symbols.security, Symbols.shield,
    // Shopping
    Symbols.shopping_bag, Symbols.card_giftcard, Symbols.diamond, Symbols.watch,
    Symbols.checkroom, Symbols.local_offer,
    // Travel
    Symbols.map, Symbols.public, Symbols.language, Symbols.camera_alt, Symbols.photo_camera,
    Symbols.hotel, Symbols.beach_access, Symbols.park,
    // Subscriptions & Services (New)
    Symbols.subscriptions, Symbols.video_library, Symbols.live_tv, Symbols.ondemand_video,
    Symbols.cloud, Symbols.vpn_key, Symbols.storage, Symbols.settings_remote,
    // Medical (Expanded)
    Symbols.medical_services, Symbols.bloodtype, Symbols.masks, Symbols.vaccines,
    // Others
    Symbols.emoji_events, Symbols.extension, Symbols.palette, Symbols.brush,
    Symbols.auto_stories, Symbols.psychology, Symbols.volunteer_activism,
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
                             child: _color == c.value ? const Icon(Symbols.check, color: Colors.white, size: 24) : null,
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
                      const Icon(Symbols.arrow_drop_down, color: Colors.grey),
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
                      const Icon(Symbols.arrow_drop_down, color: Colors.grey),
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


