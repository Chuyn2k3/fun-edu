import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fun_edu/feature/game_feature/game/multi_player_quiz/offline_multiplayer_screen.dart';
import 'package:fun_edu/helper/pref.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/colorConst.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';

class SoloPage extends StatefulWidget {
  /// {@macro page}
  const SoloPage({
    super.key, // ignore: unused_element
  });

  @override
  State<SoloPage> createState() => _SoloPageState();
}

/// State for widget SoloPage.
class _SoloPageState extends State<SoloPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _user1 = TextEditingController();

  final TextEditingController _user2 = TextEditingController();
  /* #region Lifecycle */
  @override
  void initState() {
    super.initState();
    // Initial state initialization
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: CustomAppbar.basic(
        onTap: () => Navigator.pop(context),
        title: "Nhập tên người chơi",
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextForm(_user1, "Nhập tên người chơi thứ nhất"),
                _buildTextForm(_user2, "Nhập tên người chơi thứ hai"),
              ],
            ),
          ),
          MaterialButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          OfflineMultiplayerScreen(_user1.text, _user2.text)),
                );
              }
            },
            elevation: 20,
            color: baseColor,
            child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Bắt đầu',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w600))),
          ),
        ]),
      ),
    );
  }

  Widget _buildTextForm(
    TextEditingController userName,
    String labelName,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: MediaQuery.of(context).size.width > 700 ? 500 : double.infinity,
      child: TextFormField(
        controller: userName,
        style: const TextStyle(color: Colors.black, fontSize: 20),
        decoration: InputDecoration(
          errorStyle: const TextStyle(color: redColorLight),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: redColorLight),
            borderRadius: BorderRadius.circular(16),
          ),
          labelText: labelName,
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: baseColorLight, width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
          focusColor: baseColorLight,
          hintStyle: const TextStyle(color: Colors.grey),
          hintText: "Nhập tên người chơi",
          contentPadding: const EdgeInsets.all(15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
