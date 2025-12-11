import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/create_stream_provider.dart';

class MonetizationPage extends ConsumerWidget {
  final PageController pageController;
  
  const MonetizationPage({
    super.key,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createStreamProvider);
    final notifier = ref.read(createStreamProvider.notifier);
    
    final giftOptions = [1, 2, 4, 6, 8, 10];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monetization',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          CheckboxListTile(
            value: state.giftRequirement > 0,
            onChanged: (value) {
              notifier.updateGiftRequirement(value == true ? 1 : 0);
            },
            title: const Text('Require minimum gifts for entry'),
            activeColor: const Color(0xFFFF4D00),
          ),
          
          if (state.giftRequirement > 0) ...[
            const SizedBox(height: 16),
            const Text('Select minimum gifts required:'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: giftOptions.map((amount) {
                final isSelected = state.giftRequirement == amount;
                return ChoiceChip(
                  label: Text('$amount ${amount == 1 ? 'gift' : 'gifts'}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      notifier.updateGiftRequirement(amount);
                    }
                  },
                  selectedColor: const Color(0xFFFF4D00),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}