import 'package:flutter/material.dart';
import 'package:fun_edu/features/town/presentation/widgets/town_building_card.dart';
import 'package:fun_edu/features/town/presentation/widgets/pippo_guide_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';

class TownScreen extends StatelessWidget {
  const TownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Làng Cổ Tích FunEdu',
                    style: TextStyle(
                      fontFamily: 'LilitaOne',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.shade700, width: 2),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.monetization_on, color: Colors.orange, size: 20),
                        SizedBox(width: 4),
                        Text('150', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const PippoGuideWidget(),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    TownBuildingCard(
                      title: 'Siêu Thị Pippo',
                      subtitle: 'Mua hoa quả & tính tiền',
                      icon: Icons.shopping_cart,
                      color: Colors.orange,
                      onTap: () {
                        context.pushNamed(GoRouterName.shopGameLevelSelect.routeName);
                      },
                    ),
                    TownBuildingCard(
                      title: 'Cây Tri Thức',
                      subtitle: 'Tưới nước mỗi ngày',
                      icon: Icons.park,
                      color: Colors.green,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bé đã tưới nước cho Cây Tri Thức!')),
                        );
                      },
                    ),
                    TownBuildingCard(
                      title: 'Nhà Toán Học',
                      subtitle: 'Tô số & phép tính vui',
                      icon: Icons.calculate,
                      color: Colors.purple,
                      onTap: () {
                        context.pushNamed(GoRouterName.numberStudy.routeName);
                      },
                    ),
                    TownBuildingCard(
                      title: 'Trại Ấp Thú',
                      subtitle: '50+ thú cưng kỳ diệu',
                      icon: Icons.pets,
                      color: Colors.pinkAccent,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Quả trứng đang nứt ra kìa!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
