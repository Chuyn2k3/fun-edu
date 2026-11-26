# Website dùng thử ChipChip — kế hoạch làm (chưa deploy)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Làm trang web tĩnh `website/` (Vite + TypeScript, không framework). Trang có trang chính cho ba mẹ, trò Tô chữ chấm nét giống hệt app, trò Đố vui, và trang quyền riêng tư đầy đủ. **Chưa deploy**: chủ dự án muốn dev trước, phần Caddy/Oracle làm ở đợt sau.

**Architecture:**
- Ứng dụng nhiều trang (multi-page) của Vite: `index.html`, `to-chu.html`, `do-vui.html`, `quyen-rieng-tu.html`.
- Trang `to-chu` dùng canvas + Pointer Events. Phần chấm nét là bản TypeScript của `lib/stroke/`, kiểm bằng bộ ví dụ do Dart sinh ra.
- Chữ chính sách quyền riêng tư của app được Dart xuất ra JSON để web dùng, nên hai nơi luôn cùng nội dung.
- Script build chép nét mẫu, ảnh và font từ `assets/`.

**Tech Stack:** Node 22, Vite, TypeScript, Vitest, Playwright (đã có sẵn trên máy dev), Python + fonttools/brotli để cắt font.

**Spec:** `docs/superpowers/specs/2026-11-26-website-dung-thu-design.md`. Chủ dự án duyệt 2026-11-26; email liên hệ `phamdoan060801@gmail.com` (đã có trong chính sách của app).

## Global Constraints

- Không gửi request nào ra ngoài tên miền của trang: không CDN, không Google Fonts, không phân tích, không cookie.
- Màu lấy từ tokens của app:
  - primary `#C8460F`, accent `#E8590C`;
  - background `#FBF5EC`, dot `#EADFCF`;
  - text `#22284A`, textMuted `#5B6385`;
  - card `#FFFFFF`;
  - correct `#2E9E5B`; dùng `GameColors.correctRing` nếu khác.
- Font Nunito (ExtraBold, Bold) tự phục vụ, cắt còn Latin + tiếng Việt, định dạng WOFF2.
- Nút cho bé ≥ 64 px; chữ đạt tương phản ≥ 4.5:1; chuỗi tiếng Việt.
- 8 mục tô: `so-1`, `so-2`, `so-3`, `chu-a`, `chu-o`, `chu-b`, `chu-c`, `chu-e`. Nét mẫu chép nguyên từ `assets/glyphs/`.
- Chấm nét theo đúng luật Dart:
  - `inWindow()`, `GradeConfig.forGlyph`;
  - nhìn trước để phát hiện sai thứ tự (`GlyphSession.submit`);
  - chặn NaN;
  - kẹp điểm về [0,1].
- Giọng: Web Speech API, chỉ dùng giọng `vi-VN`; không có thì im và ẩn nút loa.
- `localStorage` chỉ để bật/tắt tiếng, bọc try/catch.
- Kích thước: JS sau nén ≤ 60 KB; trang đầu (không tính ảnh màn hình) ≤ 400 KB.
- Nút tải app nằm sau cổng người lớn (câu phép nhân viết bằng chữ). Link kho chưa có thì hiện "Sắp có".
- Trước khi commit:
  - `cd website && npm test && npm run build`;
  - nếu đụng code Dart thì thêm `flutter analyze` và `flutter test`.

## Review Focus

1. **Bé vẽ trên điện thoại.** Ngón tay chạm vùng tô không được cuộn hay phóng to trang. Nét vẽ đến từ nhiều pointer cùng lúc thì bỏ, chỉ giữ một. Test ở Task 3.
2. **Trình duyệt không có giọng `vi-VN`.** Không đọc bằng giọng khác; đố vui không có câu nghe chữ. Test ở Task 3 và Task 4.
3. **Request ra ngoài.** Không có request nào tới tên miền khác. Test ở Task 6.
4. **`localStorage` bị chặn** (Safari ẩn danh). Trang vẫn chạy. Test ở Task 1.
5. **Xoay máy hoặc đổi cỡ cửa sổ giữa lúc tô.** Canvas vẽ lại đúng, nét đã đạt vẫn giữ. Test ở Task 3.

---

### Task 1: Khung website, chép tài nguyên, token, font

**Files:**
- Create: `website/package.json`, `website/tsconfig.json`, `website/vite.config.ts`, `website/vitest.config.ts`
- Create: `website/scripts/copy-assets.mjs`, `website/scripts/subset-fonts.py`, `website/scripts/check-size.mjs`
- Create: `website/src/styles/tokens.css`, `website/src/styles/base.css`
- Create: `website/src/lib/prefs.ts`, `website/src/config.ts`
- Create: `website/.gitignore` (bỏ qua `dist/`, `public/generated/`, `node_modules/`)
- Test: `website/test/prefs.test.ts`

**Interfaces:**
- Produces:
  - `npm run assets`: chạy `copy-assets.mjs` rồi `subset-fonts.py`, kết quả vào `website/public/generated/`.
  - `npm run build`: `assets` → `vite build` → `check-size`.
  - `npm test`: `vitest run`.
  - `getSoundOn(): boolean`, `setSoundOn(v: boolean): void` trong `prefs.ts` (mặc định `true`; không ném lỗi khi storage hỏng).
  - `SITE.storeLinks: {appStore: string | null, googlePlay: string | null}`, `SITE.contactEmail: 'phamdoan060801@gmail.com'` trong `config.ts`.

- [ ] **Step 1: Viết test lỗi.** `prefs.test.ts`:
  - `localStorage` thường: `setSoundOn(false)` rồi `getSoundOn() === false`;
  - `localStorage` ném lỗi ở `getItem`/`setItem`: `getSoundOn() === true`, `setSoundOn(false)` không ném.
- [ ] **Step 2: Chạy để thấy lỗi.**
  - Chạy: `cd website && npm install -D vite typescript vitest jsdom && npx vitest run`.
  - Mong đợi: FAIL (thiếu `prefs.ts`).
- [ ] **Step 3: Viết code.**
  - `copy-assets.mjs` chép vào `public/generated/`:
    - 8 file nét mẫu (`glyphs/`);
    - `chip-main.png`, `chip-joy.png`, `chip-encourage.png`, `chip-thumb.png`, `ic-star.png` (bản `2.0x`);
    - `logo.png`.
  - `subset-fonts.py`: `pyftsubset` Nunito-ExtraBold/Bold với unicodes `U+0000-00FF,U+0102-0103,U+0110-0111,U+0128-0129,U+0168-0169,U+01A0-01B0,U+1EA0-1EF9,U+20AB`, ra `--flavor=woff2`. Cần `pip install fonttools brotli`.
  - `check-size.mjs`: tổng gzip các file `.js` ≤ 60 KB; trang đầu (`index.html` + CSS + JS + font + ảnh Chíp) ≤ 400 KB. Vượt thì thoát với mã lỗi.
- [ ] **Step 4: Chạy lại test và build.** Chạy: `cd website && npm test && npm run build`. Mong đợi: PASS; `dist/` có đủ font WOFF2 và nét mẫu.
- [ ] **Step 5: Commit** (kèm `package-lock.json`). `git commit -m "feat(website): scaffold, assets copy, fonts, prefs"`

### Task 2: Chấm nét bằng TypeScript, khớp với Dart

**Files:**
- Create: `website/src/stroke/geometry.ts`, `website/src/stroke/glyph.ts`, `website/src/stroke/grader.ts`, `website/src/stroke/session.ts`
- Create: `test/website/grading_fixtures_test.dart`. Test này sinh `website/test/fixtures/grading.json`, và báo lỗi nếu file đã commit khác với file vừa sinh (cho phép ghi lại khi chạy với biến môi trường `UPDATE_FIXTURES=1`).
- Test: `website/test/grading.test.ts`

**Interfaces:**
- Produces:
  ```ts
  type Point = {x: number; y: number}; type Stroke = Point[];
  interface Glyph { id: string; label: string; speech?: string; strokes: Stroke[]; ruling?: {cell:number; baseline:number; window:[number,number,number]} }
  function inWindow(g: Glyph): Glyph;
  function gradeConfigFor(g: Glyph): GradeConfig; // forGlyph
  function gradeStroke(drawn: Stroke, ref: Stroke, cfg?: GradeConfig): {ok: boolean; error?: 'tooShort'|'wrongDirection'|'offPath'|'wrongOrder'; deviation: number};
  class GlyphSession { constructor(g: Glyph); currentIndex: number; isComplete: boolean; submit(drawn: Stroke): StrokeResult; reset(): void; }
  function clampPoint(p: Point): Point;
  ```
- Bộ ví dụ: với mỗi mục trong 8 mục, Dart sinh các nét thử từ nét mẫu đã `inWindow()`:
  - đúng y nét mẫu;
  - nét mẫu bị đảo chiều;
  - nét mẫu dịch đi 0,05, 0,15 và 0,3;
  - nét mẫu bị cắt còn 40%;
  - nét có điểm NaN (ghi bằng chuỗi `"NaN"`);
  - nét 2 vẽ trước nét 1 (cho các mục có ≥ 2 nét).
  
  Kết quả chạy session ghi lại dạng `{glyph, inputs: [[x,y]...][], results: [{ok, error, deviation}]}`.

- [ ] **Step 1: Viết test Dart và sinh bộ ví dụ.** Chạy: `UPDATE_FIXTURES=1 flutter test test/website/grading_fixtures_test.dart`. Mong đợi: tạo ra `website/test/fixtures/grading.json` có 8 mục.
- [ ] **Step 2: Viết test TS.** `grading.test.ts`:
  - với mỗi ví dụ: dựng `GlyphSession(inWindow(glyph))`, nộp lần lượt các nét, so `ok`/`error` và `deviation` (`toBeCloseTo`, 9 chữ số);
  - `gradeConfigFor(chu-b đã inWindow).tolerance` bằng giá trị Dart ghi trong bộ ví dụ.
- [ ] **Step 3: Chạy để thấy lỗi.** Chạy: `cd website && npx vitest run test/grading.test.ts`. Mong đợi: FAIL (chưa có thư viện).
- [ ] **Step 4: Viết code.** Dịch từng hàm Dart sang TS theo đúng thứ tự phép tính, để kết quả số thực khớp.
- [ ] **Step 5: Chạy lại test.**
  - Chạy: `cd website && npm test`. Mong đợi: PASS.
  - Chạy: `flutter test test/website/`. Mong đợi: PASS (bộ ví dụ khớp với file đã commit).
- [ ] **Step 6: Commit.** `git commit -m "feat(website): stroke grading port with Dart-generated fixtures"`

### Task 3: Trang Tô chữ

**Files:**
- Create: `website/to-chu.html`, `website/src/pages/trace.ts`, `website/src/trace/pad.ts` (canvas + pointer), `website/src/lib/speech.ts`, `website/src/trace/messages.ts`
- Test: `website/test/speech.test.ts`, `website/test/pad.test.ts` (jsdom)

**Interfaces:**
- Produces:
  ```ts
  // speech.ts
  function pickVietnameseVoice(voices: SpeechSynthesisVoice[]): SpeechSynthesisVoice | null; // lang startsWith 'vi'
  function speak(text: string): Promise<void>; // resolves on end/error; no-op without a vi voice or sound off
  function hasVietnameseVoice(): boolean;
  // pad.ts
  class TracePad { constructor(canvas: HTMLCanvasElement, onStroke: (s: Stroke) => void); setGlyph(g: Glyph, done: number): void; flashHint(): void; destroy(): void; }
  ```

Hành vi:
- Thanh chọn 8 mục.
- Vùng tô vuông. Với chữ cái, vẽ các dòng ô li theo `ruling` đã `inWindow()`.
- Nét đã đạt tô màu đậm; nét đang cần tô hiện mờ, có chấm bắt đầu.
- Chỉ nhận pointer chính đầu tiên. `touch-action: none`.
- Điểm vẽ được kẹp về [0,1], rồi nộp vào session.
- Lời nhắn (theo app):
  - đúng: `'Giỏi quá! Giờ tô nét N nhé.'`;
  - xong: `'Bé viết ${speech ?? label} đẹp lắm!'`;
  - sai theo từng lỗi:
    - `tooShort`: `'Tô dài thêm chút nữa nhé!'`;
    - `wrongDirection`: `'Bắt đầu từ chấm tròn nhé!'`;
    - `offPath`: `'Tô theo đường mẫu nhé!'`;
    - `wrongOrder`: `'Tô nét này trước nhé!'`.
- Nút "Nghe" (ẩn khi không có giọng), "Xem mẫu", "Tô lại", đều ≥ 64 px.
- Xong thì hiện thẻ khen, nút "Chữ tiếp theo", và thẻ "Muốn học tiếp? Tải ChipChip" dẫn về `/#tai-app`.
- Đổi cỡ cửa sổ thì vẽ lại, giữ tiến độ.

- [ ] **Step 1: Viết test lỗi.**
  - `speech.test.ts`:
    - `pickVietnameseVoice` chọn giọng `vi-VN`, trả null khi chỉ có `en-US`;
    - `speak` không gọi `speechSynthesis.speak` khi không có giọng tiếng Việt.
  - `pad.test.ts`:
    - pointerdown → move → up gửi đúng một nét, điểm đã chia cho cạnh và kẹp về [0,1];
    - pointer thứ hai trong lúc đang vẽ bị bỏ qua;
    - đổi kích thước canvas giữa chừng không làm mất các nét đã đạt.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `cd website && npm test`. Mong đợi: FAIL.
- [ ] **Step 3: Viết code.**
- [ ] **Step 4: Chạy lại test.** Chạy: `cd website && npm test && npm run build`. Mong đợi: PASS.
- [ ] **Step 5: Commit.** `git commit -m "feat(website): tracing page"`

### Task 4: Trang Đố vui

**Files:**
- Create: `website/do-vui.html`, `website/src/pages/quiz.ts`, `website/src/quiz/generate.ts`
- Test: `website/test/quiz.test.ts`

**Interfaces:**
- Produces:
  ```ts
  type Q = {kind:'count'|'add'|'letter'; prompt:string; speech:string; choices:string[]; correct:number; stars?:number; letterIds?:string[]};
  function makeRound(rng: () => number, opts: {voice: boolean}): Q[]; // 5 questions
  ```
- **Đếm sao:** 1–5 sao, lựa chọn là số.
- **Cộng:** `a + b` với tổng ≤ 5, lựa chọn là số.
- **Nghe chữ:**
  - chỉ có khi `voice` bật;
  - dùng các chữ trong 8 mục và nhóm dễ nhầm `['b','d','h']`, `['o','a','e']`, `['c','e','o']`;
  - lựa chọn là chữ, đọc bằng `speech` của nét mẫu ("chữ bờ").
- Mỗi lượt trộn cả 3 loại khi có giọng; không có giọng thì chỉ có đếm và cộng.
- Chọn sai: phím rung nhẹ, chọn lại. Chọn đúng: phím xanh, chờ đọc xong (hoặc tối thiểu 900 ms), rồi sang câu kế.
- Hết 5 câu: thẻ khen và thẻ tải app.

- [ ] **Step 1: Viết test lỗi.**
  - 5 câu; mỗi câu có 3 lựa chọn khác nhau; `correct` nằm trong 0..2;
  - `count`: số sao trong 1..5;
  - `add`: tổng ≤ 5, đáp án đúng bằng tổng;
  - `voice: false` thì không có câu `letter`;
  - `voice: true` thì có ít nhất một câu `letter` trong 20 seed.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `cd website && npx vitest run test/quiz.test.ts`. Mong đợi: FAIL.
- [ ] **Step 3: Viết code.**
- [ ] **Step 4: Chạy lại test.** Chạy: `cd website && npm test && npm run build`. Mong đợi: PASS.
- [ ] **Step 5: Commit.** `git commit -m "feat(website): quiz page"`

### Task 5: Trang chính, quyền riêng tư, cổng người lớn

**Files:**
- Create: `website/index.html`, `website/src/pages/home.ts`, `website/quyen-rieng-tu.html`, `website/src/pages/privacy.ts`, `website/src/lib/adult-gate.ts`
- Modify: `lib/parent/screens/privacy_screen.dart`: đổi `_sections` thành `privacySections` (công khai), không đổi nội dung.
- Create: `test/website/privacy_export_test.dart`: sinh `website/src/content/privacy-app.json`, báo lỗi nếu khác bản đã commit (`UPDATE_FIXTURES=1` để ghi lại).
- Test: `website/test/gate.test.ts`

**Interfaces:**
- Produces:
  - `askAdult(): Promise<boolean>`: hộp thoại hỏi một phép nhân viết bằng chữ ("Bảy nhân sáu bằng mấy?"), bàn phím số, đúng thì trả `true`.
  - Trang chính có `id="tai-app"`: nút App Store / Google Play lấy từ `SITE.storeLinks`; link `null` thì hiện "Sắp có" và không bấm được. Bấm nút có link thì gọi `askAdult()` trước.

Nội dung:
- **Trang chính:** đúng phác thảo trong spec §5.1. Chữ giới thiệu lấy từ `docs/store-listing.md`, gồm 3–4 điểm nổi bật. Ảnh màn hình chụp bằng `tools/shot` (trang chủ điện thoại, màn tô chữ), xuất WebP vào `website/public/screens/` và commit.
- **Trang quyền riêng tư:**
  - phần **Trang web**: không thu thập gì, không cookie, không theo dõi, nét vẽ không rời máy;
  - phần **Ứng dụng ChipChip**: hiện từ `privacy-app.json`;
  - email liên hệ.
- Meta Open Graph tiếng Việt, ảnh chia sẻ là logo + Chíp.

- [ ] **Step 1: Viết test lỗi.**
  - `gate.test.ts`: trả lời đúng thì `true`; sai hoặc hủy thì `false`; câu hỏi viết bằng chữ, không có chữ số.
  - Test Dart xuất JSON chạy được, và nội dung có email liên hệ.
- [ ] **Step 2: Chạy để thấy lỗi.**
  - Chạy: `cd website && npx vitest run test/gate.test.ts`. Mong đợi: FAIL.
  - Chạy: `flutter test test/website/`. Mong đợi: FAIL (chưa có `privacySections`).
- [ ] **Step 3: Viết code**, rồi chạy `UPDATE_FIXTURES=1 flutter test test/website/privacy_export_test.dart` để tạo JSON.
- [ ] **Step 4: Chạy lại test.**
  - Chạy: `cd website && npm test && npm run build`. Mong đợi: PASS.
  - Chạy: `flutter analyze && flutter test`. Mong đợi: sạch, đạt hết.
- [ ] **Step 5: Commit.** `git commit -m "feat(website): home, privacy, adult gate"`

### Task 6: Kiểm thử trình duyệt (Playwright)

**Files:**
- Create: `website/e2e/site.spec.ts`, `website/playwright.config.ts` (chạy `vite preview` trên bản build; dự án điện thoại 375×667, tablet 820×1180, máy tính 1280×800)
- Modify: `website/package.json` thêm script `e2e`

- [ ] **Step 1: Viết test.**
  - Cả 4 trang, cả 3 cỡ màn hình:
    - không cuộn ngang (`scrollWidth <= clientWidth`);
    - mọi nút có `data-kid` cao ≥ 64;
    - không có lỗi console.
  - **Không request ra ngoài:** ghi lại mọi request khi mở và chơi; mọi URL phải cùng origin.
  - **Tô `so-1`:** lấy nét mẫu từ `/generated/glyphs/so-1.json`, chuyển sang tọa độ canvas, kéo chuột theo nét; thấy thẻ khen.
  - **Đố vui:** đọc đáp án đúng qua `data-correct` trên nút (chỉ có khi build ở chế độ test, `import.meta.env.MODE === 'test'`), trả lời 5 câu, thấy thẻ khen.
  - **Cổng người lớn:** đặt link Google Play thử qua `?test-store=1` (chỉ ở chế độ test), bấm nút thì thấy hộp hỏi; trả lời sai thì không mở link.
- [ ] **Step 2: Chạy.** Chạy: `cd website && npm run build -- --mode test && npx playwright test --trace off`. Mong đợi: PASS.
- [ ] **Step 3: Chụp màn hình và xem** trang chính, tô chữ, đố vui trên điện thoại và máy tính.
- [ ] **Step 4: Commit.** `git commit -m "test(website): browser checks"`

### Task 7: Tài liệu

- [ ] **Step 1: Viết `website/README.md`:** cách chạy (`npm ci`, `npm run dev`, `npm test`, `npm run e2e`), cách build, yêu cầu Python fonttools, ghi chú "deploy: đợt sau".
- [ ] **Step 2: Cập nhật `docs/PROJECT_STATE.md`.**
  - Mục 6: thêm dòng Website dùng thử.
  - Mục 7: còn deploy Caddy/Oracle, link App Store/Google Play.
  - Mục 3: thêm lệnh kiểm tra website.
  - `AGENTS.md`: thêm một dòng về `website/`.
- [ ] **Step 3: Kiểm tra và commit.** Chạy `cd website && npm test && npm run build`, rồi `flutter analyze && flutter test`. Mong đợi: tất cả đạt. Commit: `git commit -m "docs: website state"`
