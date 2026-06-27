import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class IconSelectorModal extends StatefulWidget {
  const IconSelectorModal({super.key, required this.onIconSelected});
  final ValueChanged<String> onIconSelected;

  @override
  State<IconSelectorModal> createState() => _IconSelectorModalState();
}

class _IconSelectorModalState extends State<IconSelectorModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _customEmojiController = TextEditingController();

  final List<IconData> _symbols = [
    Icons.account_balance_wallet,
    Icons.account_balance,
    Icons.credit_card,
    Icons.savings,
    Icons.payments,
    Icons.attach_money,
    Icons.currency_rupee,
    Icons.currency_exchange,
    Icons.trending_up,
    Icons.trending_down,
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.local_gas_station,
    Icons.flight,
    Icons.movie,
    Icons.health_and_safety,
    Icons.school,
    Icons.home,
    Icons.directions_car,
    Icons.work,
    Icons.card_giftcard,
    Icons.fastfood,
    Icons.receipt,
    Icons.category,
    Icons.star,
    Icons.favorite,
    Icons.bolt,
    Icons.water_drop,
    Icons.emoji_objects,
    Icons.wallet_giftcard,
    Icons.monetization_on,
    Icons.store,
    Icons.train,
    Icons.pedal_bike,
    Icons.medical_services,
    Icons.child_care,
    Icons.pets,
    Icons.fitness_center,
    Icons.sports_esports,
    Icons.local_cafe,
    Icons.local_dining,
    Icons.local_grocery_store,
    Icons.local_mall,
    Icons.local_hospital,
    Icons.directions_transit,
    Icons.directions_bus,
    Icons.account_tree,
    Icons.pie_chart,
    Icons.bar_chart,
    Icons.show_chart,
    Icons.stacked_line_chart,
    Icons.price_change,
    Icons.request_quote,
    Icons.label,
    Icons.bookmark,
    Icons.directions_boat,
    Icons.local_taxi,
    Icons.local_bar,
    Icons.icecream,
    Icons.local_pizza,
    Icons.bakery_dining,
    Icons.lunch_dining,
    Icons.kitchen,
    Icons.healing,
    Icons.medication,
    Icons.spa,
    Icons.pool,
    Icons.content_cut,
    Icons.shower,
    Icons.business_center,
    Icons.computer,
    Icons.library_books,
    Icons.attach_file,
    Icons.music_note,
    Icons.sports_soccer,
    Icons.sports_basketball,
    Icons.sports_tennis,
    Icons.theater_comedy,
    Icons.casino,
    Icons.stroller,
    Icons.family_restroom,
    Icons.chair,
    Icons.bed,
    Icons.local_laundry_service,
    Icons.build,
    Icons.smartphone,
    Icons.wifi,
    Icons.electric_bolt,
    Icons.description,
    Icons.security,
    Icons.shield,
    Icons.shopping_bag,
    Icons.diamond,
    Icons.watch,
    Icons.checkroom,
    Icons.local_offer,
    Icons.map,
    Icons.public,
    Icons.language,
    Icons.camera_alt,
    Icons.photo_camera,
    Icons.hotel,
    Icons.beach_access,
    Icons.park,
    Icons.subscriptions,
    Icons.video_library,
    Icons.live_tv,
    Icons.ondemand_video,
    Icons.cloud,
    Icons.vpn_key,
    Icons.storage,
    Icons.settings_remote,
    Icons.bloodtype,
    Icons.masks,
    Icons.vaccines,
    Icons.emoji_events,
    Icons.extension,
    Icons.palette,
    Icons.brush,
    Icons.auto_stories,
    Icons.psychology,
    Icons.volunteer_activism,
    Icons.savings,
    Icons.payments,
    Icons.attach_money,
    Icons.currency_rupee,
    Icons.currency_exchange,
    Icons.trending_up,
    Icons.trending_down,
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.local_gas_station,
    Icons.flight,
    Icons.movie,
    Icons.health_and_safety,
    Icons.school,
    Icons.home,
    Icons.directions_car,
    Icons.work,
    Icons.card_giftcard,
    Icons.fastfood,
    Icons.receipt,
    Icons.category,
    Icons.star,
    Icons.favorite,
    Icons.bolt,
    Icons.water_drop,
    Icons.emoji_objects,
    Icons.wallet_giftcard,
    Icons.monetization_on,
    Icons.store,
    Icons.train,
    Icons.pedal_bike,
    Icons.medical_services,
    Icons.child_care,
    Icons.pets,
    Icons.fitness_center,
    Icons.sports_esports,
    Icons.local_cafe,
    Icons.local_dining,
    Icons.local_grocery_store,
    Icons.local_mall,
    Icons.local_hospital,
    Icons.directions_transit,
    Icons.directions_bus,
    Icons.account_tree,
    Icons.pie_chart,
    Icons.bar_chart,
    Icons.show_chart,
    Icons.stacked_line_chart,
    Icons.price_change,
    Icons.request_quote,
  ];

  final List<String> _emojis = [
    '💵',
    '💶',
    '💷',
    '🏦',
    '💳',
    '💰',
    '💸',
    '🪙',
    '🚗',
    '🚕',
    '✈️',
    '🍔',
    '🍕',
    '☕',
    '🛒',
    '🛍️',
    '🎁',
    '🎉',
    '💊',
    '🏥',
    '⚕️',
    '🏠',
    '🏢',
    '🎓',
    '💼',
    '📈',
    '📉',
    '📱',
    '💻',
    '💡',
    '💧',
    '⚡',
    '💹',
    '🧾',
    '🏧',
    '🏛️',
    '🛡️',
    '📊',
    '🚀',
    '☂️',
    '🤝',
    '💼',
    '📦',
    '📱',
    '📲',
    '🤑',
    '🐶',
    '🐱',
    '🎮',
    '⚽',
    '🏀',
    '🎬',
    '🎧',
    '🎸',
    '🏖️',
    '🏝️',
    '🚂',
    '🚲',
    '⛽',
    '🍼',
  ];

  final List<String> _assets = [
    'assets/banks/SBI.png',
    'assets/banks/HDFC.png',
    'assets/banks/BOB.png',
    'assets/banks/EPFO.png',
    'assets/banks/KITE.png',
    'assets/banks/ANGELONE.png',
    'assets/banks/PHONEPE.png',
    'assets/banks/GPAY.png',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customEmojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const Gap(16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(16),
          Text(
            'Select Icon',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(16),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Symbols'),
              Tab(text: 'Emoji'),
              Tab(text: 'Custom'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Symbols Tab
                GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _symbols.length,
                  itemBuilder: (context, index) {
                    final sym = _symbols[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        widget.onIconSelected('material:${sym.codePoint}');
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          sym,
                          size: 28,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
                // Emoji Tab
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _customEmojiController,
                        decoration: InputDecoration(
                          hintText: 'Enter custom emoji (e.g. 🐶)',
                          prefixIcon: const Icon(Icons.emoji_emotions),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () {
                               final val = _customEmojiController.text.trim();
                               if (val.isNotEmpty) {
                                  widget.onIconSelected('emoji:$val');
                                  Navigator.pop(context);
                               }
                            }
                          )
                        ),
                        maxLength: 1,
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                             widget.onIconSelected('emoji:${val.trim()}');
                             Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _emojis.length,
                        itemBuilder: (context, index) {
                          final emj = _emojis[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              widget.onIconSelected('emoji:$emj');
                              Navigator.pop(context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(emj, style: const TextStyle(fontSize: 28)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                // Assets Tab
                GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    final asset = _assets[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        widget.onIconSelected('asset:$asset');
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(asset, fit: BoxFit.contain),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
