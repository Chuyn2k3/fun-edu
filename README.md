# Chíp Chíp (funedu)

Ứng dụng học viết cho trẻ em, linh vật Chíp Chíp. Dự án Flutter nằm ngay ở thư mục gốc (thay cho app cũ; mã cũ tra trong lịch sử git, nhánh `new-web`, `develop`).

- `lib/`, `test/`, `assets/`, `android/`, `ios/` — app Flutter, mã gói `com.ibme.funedu`.
- `tools/` — công cụ hỗ trợ (cắt và tách nền ảnh).
- `docs/superpowers/specs/` — spec thiết kế; `docs/superpowers/plans/` — kế hoạch triển khai; `docs/phase0/` — tài liệu giai đoạn 0.

- Package id: `com.ibme.funedu` (Android applicationId / iOS bundle id), Dart package `funedu`
- Flutter 3.24.5 (stable), Dart 3.5.4 — chạy được với Flutter ≥ 3.24
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

## Mã gói

Đã kiểm tra bằng `git grep`: không còn mã gói mẫu hay mã gói cũ trong dự án; applicationId (Android) và bundle id (iOS) đều là `com.ibme.funedu`.

## Việc của chủ dự án

- Thu hồi khóa OpenAI cũ: CHƯA XÁC NHẬN. Khóa nằm trong các file cũ `lib/feature/game_feature/game/sweep/game/data/envied/env.g.dart` và `lib/helper/global.dart`, vẫn còn trong lịch sử git.
