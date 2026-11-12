# Chíp Chíp (funedu)

Ứng dụng học viết cho trẻ em, linh vật Chíp Chíp.

- Package id: `com.ibme.funedu` (Android applicationId / iOS bundle id), Dart package `funedu`
- Flutter 3.50.0 (stable), Dart 3.14.0
- Stack: flutter_riverpod, go_router, drift (+ drift_flutter, path_provider)

## Chạy

```
flutter pub get
flutter test
flutter analyze
```

## Font

Nunito (SIL OFL, see `assets/fonts/OFL.txt`) is bundled as static instances; the variable font is not committed. To regenerate:

```
curl -L -o Nunito-VF.ttf 'https://raw.githubusercontent.com/google/fonts/main/ofl/nunito/Nunito%5Bwght%5D.ttf'
curl -L -o assets/fonts/OFL.txt https://raw.githubusercontent.com/google/fonts/main/ofl/nunito/OFL.txt
pip install fonttools
# wght 400/600/700/800/900 -> Regular/SemiBold/Bold/ExtraBold/Black
fonttools varLib.instancer Nunito-VF.ttf wght=400 -o assets/fonts/Nunito-Regular.ttf
```
