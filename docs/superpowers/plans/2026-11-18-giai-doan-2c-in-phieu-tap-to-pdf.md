# Giai đoạn 2C — In phiếu tập tô PDF Implementation Plan

> **For agentic workers:** Execute task-by-task with TDD, clean commits, zero regressions, and visual verification.

**Goal:** Build offline A4 Vietnamese ô li writing worksheet PDF generation, live preview, printing, and sharing inside the Parent Corner (`ProgressTab` → `WorksheetScreen`).

**Architecture:**
- `lib/worksheet/worksheet_model.dart`: pure Dart domain model (`WorksheetConfig`, `WorksheetStyle`, `WorksheetSelectionMode`, `weakGlyphIds`, `paginateGlyphs`, `worksheetFileName`).
- `lib/worksheet/worksheet_pdf.dart`: pure Dart PDF generator (`buildWorksheetPdf`) using `pdf` + bundled `Nunito` TTF fonts + `RuledPaper` ô li line math + `Glyph.inWindow()` vector strokes & faint context letters.
- `lib/worksheet/worksheet_printer.dart`: Riverpod-injectable `WorksheetPrinter` wrapping `printing` (`layoutPdf` / `sharePdf`).
- `lib/worksheet/worksheet_preview.dart`: instant Flutter `CustomPainter` A4 preview mirroring the PDF layout.
- `lib/parent/screens/worksheet_screen.dart` & `lib/parent/screens/progress_tab.dart`: responsive phone/tablet Parent Corner UI wired to `ProgressTab`.

**Tech Stack:** Flutter 3.24.5, Dart 3.5, Riverpod, `pdf`, `printing`, bundled `Nunito` fonts, `assets/glyphs/*.json`.

---

### Task 1: Add `pdf` & `printing` dependencies (Flutter 3.24.5 compatible)

**Files:**
- Modify: `pubspec.yaml`

- [ ] Add `pdf: ^3.11.1` and `printing: ^5.13.4` to `pubspec.yaml` without upgrading any existing pinned package (`drift_flutter: 0.2.4` stays intact).
- [ ] Run `flutter pub get` and `flutter analyze` to confirm clean resolution on Flutter 3.24.5 / Dart 3.5.
- [ ] Commit dependency addition.

---

### Task 2: Worksheet Domain Model & Weak-Glyph Selection (TDD)

**Files:**
- Create: `lib/worksheet/worksheet_model.dart`
- Create: `test/worksheet/worksheet_model_test.dart`

- [ ] Write failing unit tests for `weakGlyphIds`, `paginateGlyphs`, `cellKindsFor`, `worksheetFileName`, and `WorksheetConfig`.
- [ ] Implement `lib/worksheet/worksheet_model.dart`.
- [ ] Run `flutter test test/worksheet/worksheet_model_test.dart`.
- [ ] Commit Task 2.

---

### Task 3: Offline A4 Ô Li PDF Builder & Printer Abstraction (TDD)

**Files:**
- Create: `lib/worksheet/worksheet_pdf.dart`
- Create: `lib/worksheet/worksheet_printer.dart`
- Create: `test/worksheet/worksheet_pdf_test.dart`

- [ ] Write unit tests verifying valid PDF output (`%PDF-1.`), Vietnamese Unicode header/labels, multi-page pagination (>6 glyphs), all 4 glyph sections (basic strokes, digits, ruled letters, context tone marks), and all 3 `WorksheetStyle` modes.
- [ ] Implement `lib/worksheet/worksheet_pdf.dart` reusing `RuledPaper.horizontalLines`, `RuledPaper.verticalLines`, `RuledPaper.heavyLines`, vector stroke paths, stroke number badges + direction arrows, dashed trace strokes, faint context letter for tone marks, and 3 reward stars in footer.
- [ ] Implement `lib/worksheet/worksheet_printer.dart` (`WorksheetPrinter`, `PrintingWorksheetPrinter`, `worksheetPrinterProvider`).
- [ ] Run `flutter test test/worksheet/`.
- [ ] Commit Task 3.

---

### Task 4: Instant A4 Live Preview & Parent Corner Worksheet Screen (Phone + iPad)

**Files:**
- Create: `lib/worksheet/worksheet_preview.dart`
- Create: `lib/parent/screens/worksheet_screen.dart`
- Modify: `lib/parent/screens/progress_tab.dart`
- Modify: `lib/ui/theme/tokens.dart` (if any worksheet color tokens are needed)
- Create: `test/parent/worksheet_screen_test.dart`

- [ ] Implement `WorksheetPreview` matching the PDF A4 layout (header, 6 ô li rows, strokes/arrows/dashed/blank cells, faint context letter, footer stars).
- [ ] Implement `WorksheetScreen` with 3 selection modes (Bé đang yếu / Theo nhóm / Tự chọn), 3 style presets, page switcher, live preview, Print & Share buttons (≥ 48pt, contrast ≥ 4.5:1), responsive phone & iPad 2-column layouts.
- [ ] Add "In phiếu tập tô (PDF)" button to `_WritingCard` in `lib/parent/screens/progress_tab.dart` passing kid profile & progress stats.
- [ ] Write widget tests in `test/parent/worksheet_screen_test.dart` covering entry from `ProgressTab`, mode switching, custom toggling, pagination, mock printing/sharing, and zero overflow on phone (320×568, 390×844) & tablet (1024×768, 768×1024).
- [ ] Run `flutter test test/parent/worksheet_screen_test.dart test/parent/parent_tabs_test.dart`.
- [ ] Commit Task 4.

---

### Task 5: End-to-End Verification, Visual Check & Docs

- [ ] Generate a sample PDF & render/inspect a screenshot of `WorksheetScreen` (phone + tablet) to verify visual polish and ô li accuracy.
- [ ] Run `flutter analyze` and full `flutter test`.
- [ ] Update `docs/PROJECT_STATE.md` sections 6–8, commit, and push to `origin chipchip`.
