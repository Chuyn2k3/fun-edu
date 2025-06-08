import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fun_edu/feature/manager_user/cubit/get_user_all_cubit.dart';
import 'package:fun_edu/widget/circular_indicator.dart';
import 'package:fun_edu/widget/menu/portal_master_layout.dart';

class ManagerUserScreen extends StatefulWidget {
  const ManagerUserScreen({super.key});

  @override
  State<ManagerUserScreen> createState() => _ManagerUserScreenState();
}

class _ManagerUserScreenState extends State<ManagerUserScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GetAllUserCubit>().getGetAllUser(); // Gọi dữ liệu khi khởi tạo
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return PortalMasterLayout(
      body: Scaffold(
        appBar: AppBar(
          title: const Text('Danh Sách Người Dùng'),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<GetAllUserCubit, GetAllUserState>(
      builder: (context, state) {
        if (state is GetAllUserLoadingState) {
          return const Center(child: CircularIndicator());
        }
        if (state is GetAllUserLoadedState) {
          final users = state.getAllUser;
          if (users.isEmpty) {
            return const Center(child: Text("Không có người dùng nào."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      user.userName != null && user.userName!.isNotEmpty
                          ? user.userName![0].toUpperCase()
                          : "?",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  title: Text(
                    user.userName ?? "Không rõ tên",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tuổi: ${user.age ?? "-"}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on,
                                size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${user.coin} coins',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Đã chọn ${user.userName ?? "Người dùng"}'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              );
            },
          );
        }
        return const Center(child: Text("Đã xảy ra lỗi hoặc chưa có dữ liệu."));
      },
    );
  }
}
