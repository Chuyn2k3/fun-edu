import 'package:flutter/material.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/shelf/draggable_fruit_item.dart';

class FruitShelfDraggableLayer extends StatelessWidget {
  final List<ItemEntity> availableItems;
  final bool isEnabled;
  final ValueChanged<ItemEntity>? onItemTapped;

  const FruitShelfDraggableLayer({
    super.key,
    required this.availableItems,
    this.isEnabled = true,
    this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      top: 80,
      bottom: 40,
      width: 170,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF795548).withOpacity(0.92), // Warm mahogany wood shelf
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF5D4037), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              offset: Offset(4, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shelf Title Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD7CCC8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF8D6E63)),
              ),
              child: const Center(
                child: Text(
                  'KỆ TRÁI CÂY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: Color(0xFF4E342E),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Scrollable or wrapping fruit items
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: availableItems.map((item) {
                    return DraggableFruitItem(
                      item: item,
                      isDraggable: isEnabled,
                      onTap: onItemTapped != null ? () => onItemTapped!(item) : null,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
