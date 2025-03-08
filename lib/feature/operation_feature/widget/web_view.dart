import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/material.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/button/base_button.dart';
import 'package:fun_edu/utils/common_app.dart';
import 'package:fun_edu/widget/circular_indicator.dart';

class AppWebView extends StatefulWidget {
  final String linkWebView;
  const AppWebView({
    super.key,
    required this.linkWebView,
  });

  @override
  State<AppWebView> createState() => _AppWebViewState();
}

class _AppWebViewState extends State<AppWebView> {
  late InAppWebViewController? webViewController;
  bool isLoading = true;
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: InAppWebView(
                  onWebViewCreated: (controller) =>
                      webViewController = controller,
                  initialUrlRequest:
                      URLRequest(url: Uri.parse(widget.linkWebView)),
                  onLoadStart: (controller, url) {},
                  onProgressChanged: (controller, progress) {
                    if (progress == 100) {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  },
                ),
              ),
              Container(
                height: 96,
                //color: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16 + (Platform.isIOS ? 12 : 0),
                ),
                child: BaseRoundedButton.all(
                  //margin: EdgeInsets.symmetric(vertical: 8),
                  radius: 20,
                  onTap: () {
                    Navigator.pop(context);
                  },
                  backgroundColor: const Color(0xFF007AFF),
                  child: Center(
                    child: Text(
                      "Trở về",
                      style: textTheme.t16R.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 32,
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.white,
              child: const CircularIndicator(),
            ),
        ],
      ),
    );
  }
}
