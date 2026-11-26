// Chíp's lines on the tracing page (same words as the app).
import type { StrokeError } from '../stroke/grader';

export const tracePrompt = (strokeNo: number, total: number) =>
  total === 1 ? 'Tô theo nét mẫu nhé!' : `Tô nét ${strokeNo} nhé!`;

export const nextStroke = (strokeNo: number) => `Giỏi quá! Giờ tô nét ${strokeNo} nhé.`;

export const praise = (name: string) => `Bé viết ${name} đẹp lắm!`;

export const errorLine: Record<StrokeError, string> = {
  tooShort: 'Tô dài thêm chút nữa nhé!',
  wrongDirection: 'Bắt đầu từ chấm tròn xanh nhé!',
  offPath: 'Tô theo đường mẫu nhé!',
  wrongOrder: 'Tô nét này trước nhé!',
};
