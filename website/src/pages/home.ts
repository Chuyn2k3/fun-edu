import '../styles/tokens.css';
import '../styles/base.css';
import '../styles/trace.css';
import '../styles/home.css';
import { SITE } from '../config';
import { img } from '../lib/chrome';
import { askAdult } from '../lib/adult-gate';

const TEST = import.meta.env.MODE === 'test';
const app = document.getElementById('app')!;

// Test builds can switch on a fake store link to exercise the adult gate.
const links = { ...SITE.storeLinks };
if (TEST && new URLSearchParams(location.search).has('test-store')) {
  links.googlePlay = '/test-store-target';
}

const store = (label: string, href: string | null) =>
  href
    ? `<a class="btn primary" data-kid data-store href="${href}" rel="noopener">${label}</a>`
    : `<button class="btn" data-kid disabled>${label} · Sắp có</button>`;

app.innerHTML = `
  <section class="hero">
    <img class="chip" src="${img('chip-main')}" alt="Chim sẻ Chíp Chíp" width="180" height="180">
    <h1>Bé tập viết, học chữ cùng Chíp Chíp</h1>
    <p class="muted">Chơi thử ngay, không cần tải app.</p>
    <div class="play">
      <a class="btn primary" href="/to-chu.html" data-kid><span>✏️</span>Tô chữ</a>
      <a class="btn" href="/do-vui.html" data-kid><span>🎈</span>Đố vui</a>
    </div>
  </section>

  <section class="parents" aria-labelledby="ba-me">
    <h2 id="ba-me">Dành cho ba mẹ</h2>
    <ul class="points">
      <li><b>✏️ Chấm từng nét như cô giáo</b>Bé tô trên ô li, ChipChip kiểm tra đúng thứ tự, đúng chiều, không lệch đường mẫu.</li>
      <li><b>📚 Học theo trình độ</b>Bài thử ngắn xếp bé vào đúng mức; làm tốt thì lên bài khó hơn.</li>
      <li><b>🧩 Bốn môn</b>Tập viết, Tiếng Việt, Toán, Tiếng Anh — mỗi ngày một bài 10 phút.</li>
      <li><b>🔒 An toàn cho bé</b>Không quảng cáo, không thu thập thông tin cá nhân của bé. Góc ba mẹ có khóa.</li>
    </ul>
    <div class="shots" aria-label="Ảnh màn hình ứng dụng">
      <img src="/screens/trang-chu.webp" alt="Trang chủ ChipChip" loading="lazy" width="180">
      <img src="/screens/goc-choi.webp" alt="Góc Chơi: đua tên lửa" loading="lazy" width="180">
    </div>
    <h2 id="tai-app">Tải ChipChip</h2>
    <div class="stores">
      ${store('App Store', links.appStore)}
      ${store('Google Play', links.googlePlay)}
    </div>
  </section>

  <footer class="muted">
    <a href="/quyen-rieng-tu.html">Quyền riêng tư</a> · Liên hệ: <a href="mailto:${SITE.contactEmail}">${SITE.contactEmail}</a>
  </footer>`;

// Store links leave the site: an adult answers first.
for (const a of app.querySelectorAll<HTMLAnchorElement>('a[data-store]')) {
  a.addEventListener('click', async (e) => {
    e.preventDefault();
    if (await askAdult()) location.href = a.href;
  });
}
