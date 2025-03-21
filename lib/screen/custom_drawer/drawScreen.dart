import 'package:flutter/material.dart';
import 'package:fun_edu/utils/base_scaffold.dart';

class DrawerScreen extends StatefulWidget {
  const DrawerScreen({super.key});

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // background: _buildBackground(),
      body: Stack(
        children: [
          _buildBackground(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/images/avatar.png'),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Miroslava Savi',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Active Status',
                          style: TextStyle(
                            color:
                                Color(0xFFB3E5FC), // Màu xanh nhạt dễ nhìn hơn
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    const Icon(
                      Icons.settings,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: Color(0xFFB3E5FC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 2,
                      height: 20,
                      color: const Color(0xFFB3E5FC),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Log out',
                      style: TextStyle(
                        color: Color(0xFFB3E5FC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Nền Gradient đẹp hơn, không quá tím
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0F7FA), Color(0xFFB3E5FC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
