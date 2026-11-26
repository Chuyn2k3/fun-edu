import '../styles/tokens.css';
import '../styles/base.css';
import { SITE } from '../config';
import appPolicy from '../content/privacy-app.json';

const esc = (s: string) =>
  s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]!);
const linkEmail = (s: string) =>
  esc(s).replace(SITE.contactEmail, `<a href="mailto:${SITE.contactEmail}">${SITE.contactEmail}</a>`);

const app = document.getElementById('app')!;
app.innerHTML = `
  <header class="top"><a class="btn" href="/" aria-label="Về trang chính">‹</a><h1>Quyền riêng tư</h1></header>
  <section class="card" id="web">
    <h2>Trang web ChipChip</h2>
    <p>Trang web này không thu thập bất kỳ thông tin nào của bé hay ba mẹ:</p>
    <p>• Không có tài khoản, không đăng nhập.<br>
       • Không dùng cookie, không công cụ phân tích hay quảng cáo, không tải tài nguyên từ trang khác.<br>
       • Nét bé tô và câu trả lời chỉ xử lý ngay trên trình duyệt, không gửi đi đâu.<br>
       • Trình duyệt chỉ nhớ lựa chọn bật/tắt tiếng trên chính máy đó.</p>
  </section>
  <section class="card" id="app-policy" style="margin-top:16px">
    <h2>Ứng dụng ChipChip</h2>
    ${(appPolicy as { title: string; lines: string[] }[])
      .map((s) => `<h3>${esc(s.title)}</h3>${s.lines.map((l) => `<p>${linkEmail(l)}</p>`).join('')}`)
      .join('')}
  </section>
  <p class="muted" style="text-align:center;margin:20px 0">Liên hệ: <a href="mailto:${SITE.contactEmail}">${SITE.contactEmail}</a></p>`;
