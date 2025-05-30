import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class EnterNameWidget extends StatefulWidget {
  const EnterNameWidget({super.key});

  @override
  State<EnterNameWidget> createState() => _EnterNameWidgetState();
}

class _EnterNameWidgetState extends State<EnterNameWidget> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveNameAndNavigate() async {
    final name = _textController.text.trim();
    if (name.isEmpty) return;

    await GetIt.I<SharedPreferencesManager>().putString("user_name", name);
    if (!mounted) return;
    context.pushNamed(GoRouterName.ageScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: ColorBase.primaryBackground,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/start.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.08),
                    _buildPippoIntro(),
                    _buildTextField(),
                    _buildStartButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPippoIntro() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Container(
              width: 224,
              height: 102,
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Rectangle_2982.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Text(
                'Xin chào! Mình là Pippo\nTên bạn là gì?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'LilitaOne',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 150, right: 10),
            child: Image.asset(
              'assets/images/image_9081.png',
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 30),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: 'Nhập tên của bạn',
          filled: true,
          fillColor: ColorBase.primaryBackground,
          border: _outlineBorder(ColorBase.primaryText),
          focusedBorder: _outlineBorder(ColorBase.primary),
        ),
        style: const TextStyle(
          fontFamily: 'LilitaOne',
          fontSize: 16,
          color: Colors.black,
        ),
        cursorColor: ColorBase.primary,
      ),
    );
  }

  OutlineInputBorder _outlineBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color),
      );

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: InkWell(
        splashColor: Colors.transparent,
        onTap: _saveNameAndNavigate,
        child: Container(
          width: double.infinity,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.purple.shade300,
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                color: Colors.black38,
                offset: Offset(3, 3),
              )
            ],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.brown.shade800,
              width: 2,
            ),
          ),
          child: const Center(
            child: Text(
              'Bắt đầu',
              style: TextStyle(
                fontFamily: 'LilitaOne',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
