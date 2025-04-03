import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/screen/choose_age.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:get_it/get_it.dart';

class EnterNameWidget extends StatefulWidget {
  const EnterNameWidget({super.key});

  static String routeName = 'EnterName';
  static String routePath = '/EnterName';

  @override
  State<EnterNameWidget> createState() => _EnterNameWidgetState();
}

class _EnterNameWidgetState extends State<EnterNameWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/start.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.sizeOf(context).height * 0.08),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Hộp thoại Pippo
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 25),
                            child: Container(
                              width: 224,
                              height: 102,
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                      'assets/images/Rectangle_2982.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Text(
                                'Xin chào! Mình là Pippo\nTên bạn là gì?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Sukhumvit Set',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Ảnh Pippo
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: EdgeInsets.only(top: 150, right: 10),
                            child: Image.asset(
                              'assets/images/image_9081.png',
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Ô nhập tên
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 35, vertical: 30),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Nhập tên của bạn',
                          filled: true,
                          fillColor: ColorBase.primaryBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: ColorBase.primaryText),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: ColorBase.primary),
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Sukhumvit Set',
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        cursorColor: ColorBase.primary,
                      ),
                    ),

                    // Nút "Bắt đầu"
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        onTap: () async {
                          await GetIt.instance
                              .get<SharedPreferencesManager>()
                              .putString("user_name", _textController.text);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChooseAgeWidget(),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.purple.shade300, // Đổi thành màu nâu
                            boxShadow: [
                              const BoxShadow(
                                blurRadius: 8,
                                color: Colors.black38,
                                offset: Offset(3, 3),
                              )
                            ],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.brown.shade800, // Viền màu nâu đậm
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Bắt đầu',
                              style: TextStyle(
                                fontFamily: 'Sukhumvit Set',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors
                                    .white, // Chữ màu trắng để nổi bật trên nền nâu
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
