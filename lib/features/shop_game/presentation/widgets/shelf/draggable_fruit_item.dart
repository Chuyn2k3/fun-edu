import 'package:flutter/material.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

class DraggableFruitItem extends StatelessWidget {
  final ItemEntity item;
  final bool isDraggable;

  const DraggableFruitItem({
    super.key,
    required this.item,
    this.isDraggable = true,
  });

  Widget _buildItemCard({bool isGhost = false, bool isDragging = false}) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: isGhost
            ? Colors.white.withOpacity(0.2)
            : (isDragging ? Colors.amber.shade100 : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGhost
              ? Colors.white.withOpacity(0.4)
              : (isDragging ? Colors.amber : const Color(0xFFE2D4C3)),
          width: isDragging ? 3 : 2,
        ),
        boxShadow: isGhost
            ? null
            : [
                BoxShadow(
                  color: isDragging ? Colors.amber.withOpacity(0.5) : Colors.black12,
                  offset: const Offset(0, 4),
                  blurRadius: isDragging ? 12 : 6,
                ),
              ],
      ),
      child: Center(
        child: Opacity(
          opacity: isGhost ? 0.3 : 1.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.type.emoji,
                style: const TextStyle(fontSize: 34),
              ),
              const SizedBox(height: 2),
              Text(
                item.nameVi,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isDraggable) {
      return _buildItemCard();
    }

    return Draggable<ItemEntity>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.15,
          child: _buildItemCard(isDragging: true),
        ),
      ),
      childWhenDragging: _buildItemCard(isGhost: true),
      child: _buildItemCard(),
    );
  }
}
