import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:gap/gap.dart';

class IconSelectorModal extends StatefulWidget {
  const IconSelectorModal({super.key, required this.onIconSelected});
  final ValueChanged<String> onIconSelected;

  @override
  State<IconSelectorModal> createState() => _IconSelectorModalState();
}

class _IconSelectorModalState extends State<IconSelectorModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<IconData> _symbols = [
    Symbols.account_balance_wallet,
    Symbols.account_balance,
    Symbols.credit_card,
    Symbols.savings,
    Symbols.payments,
    Symbols.attach_money,
    Symbols.currency_rupee,
    Symbols.currency_exchange,
    Symbols.trending_up,
    Symbols.trending_down,
    Symbols.shopping_cart,
    Symbols.restaurant,
    Symbols.local_gas_station,
    Symbols.flight,
    Symbols.movie,
    Symbols.health_and_safety,
    Symbols.school,
    Symbols.home,
    Symbols.directions_car,
    Symbols.work,
    Symbols.card_giftcard,
    Symbols.fastfood,
    Symbols.receipt,
    Symbols.category,
    Symbols.star,
    Symbols.favorite,
    Symbols.bolt,
    Symbols.water_drop,
    Symbols.emoji_objects,
  ];

  final List<String> _emojis = [
    '💵', '💶', '💷', '🏦', '💳', '💰', '💸', '🪙',
    '🚗', '🚕', '✈️', '🍔', '🍕', '☕', '🛒', '🛍️',
    '🎁', '🎉', '💊', '🏥', '⚕️', '🏠', '🏢', '🎓',
    '💼', '📈', '📉', '📱', '💻', '💡', '💧', '⚡',
  ];

  final List<String> _assets = [
    'assets/banks/SBI.png',
    'assets/banks/HDFC.png',
    'assets/banks/BOB.png',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          const Gap(16),
          Text('Select Icon', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Gap(16),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(sym, size: 28, color: Theme.of(context).colorScheme.primary),
                      ),
                    );
                  },
                ),
                // Emoji Tab
                GridView.builder(
                  padding: const EdgeInsets.all(16),
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
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(emj, style: const TextStyle(fontSize: 28)),
                      ),
                    );
                  },
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
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
          )
        ],
      ),
    );
  }
}
