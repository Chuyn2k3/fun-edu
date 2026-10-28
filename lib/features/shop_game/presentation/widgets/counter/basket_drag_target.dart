import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

class BasketDragTarget extends StatefulWidget {
  final List<ItemEntity> items;
  final ValueChanged<ItemEntity> onItemDropped;

  const BasketDragTarget({
    super.key,
    required this.items,
    required this.onItemDropped,
  });

  @override
  State<BasketDragTarget> createState() => _BasketDragTargetState();
}

class _BasketDragTargetState extends State<BasketDragTarget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ItemEntity>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isHovering = true);
        return true;
      },
      onLeave: (data) {
        setState(() => _isHovering = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        widget.onItemDropped(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedScale(
          scale: _isHovering ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 240,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFC48E56), // Wicker basket color
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(50)),
              border: Border.all(
                color: _isHovering ? Colors.amberAccent : const Color(0xFF8B5A2B),
                width: _isHovering ? 5 : 3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 8),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Basket rim handle
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA06A3B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // Collected items inside basket
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: widget.items.map((it) {
                    return Text(
                      it.type.emoji,
                      style: const TextStyle(fontSize: 28),
                    )
                        .animate()
                        .scale(duration: 200.ms, curve: Curves.easeOutBack);
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
