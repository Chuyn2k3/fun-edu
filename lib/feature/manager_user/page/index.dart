import 'package:flutter/material.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';
import 'package:fun_edu/widget/menu/portal_master_layout.dart';
import 'package:go_router/go_router.dart';

class ManagerUserPage extends StatefulWidget {
  const ManagerUserPage({super.key});

  @override
  State<ManagerUserPage> createState() => _ManagerUserPageState();
}

class _ManagerUserPageState extends State<ManagerUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Simulate network delay
      Future.delayed(const Duration(seconds: 1), () {
        if (_usernameController.text == "admin" &&
            _passwordController.text == "123456") {
          GoRouter.of(context).go(GoRouterName.users.routePath);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Tên đăng nhập hoặc mật khẩu không đúng';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PortalMasterLayout(
      body: Scaffold(
        appBar: AppBar(
          title: const Text('Đăng Nhập'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 100,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên đăng nhập';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'ĐĂNG NHẬP',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // const Text(
                  //   'Đăng nhập với: admin / 123456',
                  //   style: TextStyle(color: Colors.grey),
                  //   textAlign: TextAlign.center,
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
