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
    return BaseScaffold(
      body: Column(
        //mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              SizedBox(width: 8),
              SizedBox(
                width: 10,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Miroslava Saviskaya',
                    style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text('Active Status',
                      style: TextStyle(
                          color: Colors.white60, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 8),
              const Icon(
                Icons.settings,
                color: Colors.white60,
              ),
              const SizedBox(
                width: 10,
              ),
              const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white60,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Container(
                width: 2,
                height: 20,
                color: Colors.white60,
              ),
              const SizedBox(
                width: 10,
              ),
              const Text(
                'Log out',
                style: TextStyle(
                  color: Colors.white60,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
