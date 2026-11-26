# Website dùng thử ChipChip

Trang web tĩnh (Vite + TypeScript, không framework) để bé chơi thử ngay trên trình duyệt: **Tô chữ** (chấm nét giống hệt app) và **Đố vui**; kèm trang giới thiệu cho ba mẹ và chính sách quyền riêng tư. Thiết kế: `docs/superpowers/specs/2026-11-26-website-dung-thu-design.md`.

## Chạy

```
cd website
npm ci
pip install fonttools brotli pillow   # cắt font, đổi ảnh sang WebP
npm run dev        # http://localhost:5173
npm test           # Vitest (gồm kiểm chấm nét khớp app)
npm run build      # ra dist/, có kiểm kích thước (JS ≤ 60 KB gzip, trang đầu ≤ 400 KB)
npm run e2e        # Playwright: điện thoại, tablet, máy tính; không request ra ngoài
```

## Dữ liệu dùng chung với app (không sửa tay)

- Nét mẫu, ảnh Chíp, font: chép/đổi từ `assets/` khi build (`scripts/copy-assets.mjs`, `scripts/prepare-assets.py`) vào `public/generated/` (không commit).
- `test/fixtures/grading.json`: app chấm các nét thử thế nào — sinh bằng `UPDATE_FIXTURES=1 flutter test test/website/grading_fixtures_test.dart`. Đổi luật chấm trong `lib/stroke/` thì sinh lại và sửa `src/stroke/` cho tới khi `npm test` đạt.
- `src/content/privacy-app.json`: chính sách quyền riêng tư của app — sinh bằng `UPDATE_FIXTURES=1 flutter test test/website/privacy_export_test.dart` sau khi sửa `lib/parent/screens/privacy_screen.dart`.

## Cấu hình

`src/config.ts`: email liên hệ, link App Store / Google Play (null = "Sắp có"), 8 mục tô.

## Deploy

Chưa làm (chủ dự án: dev trước, deploy sau). Kế hoạch: Caddy trên máy Oracle phục vụ `dist/` cho `WEB_DOMAIN` (spec §5.6).
