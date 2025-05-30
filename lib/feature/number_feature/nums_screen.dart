import 'package:flutter/material.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NumsScreen extends StatelessWidget {
  const NumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureItem(
        title: "Âm Thanh & Hình Ảnh 🔊",
        description:
            "Nghe và xem hình ảnh số từ 0 đến 9 (Vui nhộn & dễ nhớ! 🦕)",
        color: Colors.orange,
        icon: FontAwesomeIcons.volumeHigh,
        routeName: GoRouterName.numberByAudio.routeName,
      ),
      _FeatureItem(
        title: "Trò Chơi Ghép Số & Ảnh 🧩",
        description: "Tìm và ghép số với hình đúng (Thử thách vui nhộn! 🎲)",
        color: Colors.green,
        icon: FontAwesomeIcons.puzzlePiece,
        routeName: GoRouterName.numberByMatchImage.routeName,
      ),
      _FeatureItem(
        title: "Sắp Xếp Các Số 🔢",
        description:
            "Sắp xếp số theo thứ tự chính xác (Cùng đặt số về đúng chỗ! 🚀)",
        color: Colors.lightBlue,
        icon: FontAwesomeIcons.arrowDown19,
        routeName: GoRouterName.numberBySort.routeName,
      ),
    ];

    return BaseScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CustomHeader(onBack: () {
            context.pop(context);
          }),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.builder(
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final item = features[index];
                  return _FeatureCard(
                    title: item.title,
                    description: item.description,
                    icon: item.icon,
                    color: item.color,
                    onTap: () => context.pushNamed(item.routeName),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _CustomHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            bottom: 16,
            left: 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4FC3F7), Color(0xFF81D4FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Học Chữ Số 🎈",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Bé muốn học theo cách nào nhỉ?\n🤩",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: -20,
          child:
              Icon(Icons.cloud, size: 50, color: Colors.white.withOpacity(0.6)),
        ),
        Positioned(
          left: 10,
          top: -10,
          child:
              Icon(Icons.cloud, size: 40, color: Colors.white.withOpacity(0.4)),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2);
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: FaIcon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String routeName;

  _FeatureItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.routeName,
  });
}
