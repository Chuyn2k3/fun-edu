import 'dart:developer';

import 'package:easy_audience_network/easy_audience_network.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'my_dialog.dart';

class AdHelper {
  static void init() {
    EasyAudienceNetwork.init(
      testMode:
          true, // for testing purpose but comment it before making the app live
    );
  }

  static void showInterstitialAd(VoidCallback onComplete) {
  // Tạm thời bỏ quảng cáo, chỉ hiển thị loading khi gọi onComplete
  MyDialog.showLoadingDialog();
  Future.delayed(Duration(seconds: 1), () { // Giả lập loading 1s
    Get.back(); // Đóng loading
    onComplete(); // Gọi callback
  });

  // final interstitialAd = InterstitialAd(InterstitialAd.testPlacementId);

  // interstitialAd.listener = InterstitialAdListener(
  //   onLoaded: () {
  //     interstitialAd.show();
  //   },
  //   onDismissed: () {
  //     interstitialAd.destroy();
  //     MyDialog.showLoadingDialog();
  //     Future.delayed(Duration(seconds: 1), () {
  //       Get.back();
  //       onComplete();
  //     });
  //   },
  //   onError: (i, e) {
  //     log('interstitial error: $e');
  //     MyDialog.showLoadingDialog();
  //     Future.delayed(Duration(seconds: 1), () {
  //       Get.back();
  //       onComplete();
  //     });
  //   },
  // );

  // interstitialAd.load(); // Bắt đầu tải quảng cáo
}


  static Widget nativeAd() {
    return SafeArea(
      child: NativeAd(
        placementId: NativeAd.testPlacementId,
        adType: NativeAdType.NATIVE_AD,
        keepExpandedWhileLoading: false,
        expandAnimationDuraion: 1000,
        listener: NativeAdListener(
          onError: (code, message) => log('error'),
          onLoaded: () => log('loaded'),
          onClicked: () => log('clicked'),
          onLoggingImpression: () => log('logging impression'),
          onMediaDownloaded: () => log('media downloaded'),
        ),
      ),
    );
  }

  static Widget nativeBannerAd() {
    return SafeArea(
      child: NativeAd(
        placementId: NativeAd.testPlacementId,
        adType: NativeAdType.NATIVE_BANNER_AD,
        bannerAdSize: NativeBannerAdSize.HEIGHT_100,
        keepExpandedWhileLoading: false,
        height: 100,
        expandAnimationDuraion: 1000,
        listener: NativeAdListener(
          onError: (code, message) => log('error'),
          onLoaded: () => log('loaded'),
          onClicked: () => log('clicked'),
          onLoggingImpression: () => log('logging impression'),
          onMediaDownloaded: () => log('media downloaded'),
        ),
      ),
    );
  }
}
