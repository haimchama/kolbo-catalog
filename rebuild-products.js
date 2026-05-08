const fs = require('fs');
const path = require('path');

const DIR = path.resolve(__dirname);
const WA = '972502123209';

function xe(s) {
  return String(s || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function stripTags(html) {
  return html
    .replace(/<[^>]+>/g, ' ')
    .replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"').replace(/&#(\d+);/g, (_, n) => String.fromCharCode(+n))
    .replace(/\s+/g, ' ').trim();
}

function parseProduct(html, filename) {
  // --- NAME ---
  const titleM = html.match(/<title>([\s\S]*?)(?:\s*[—\-]\s*Kolbo Online)?<\/title>/i);
  const name = titleM ? stripTags(titleM[1]) : path.basename(filename, '.html');

  // --- IMAGES ---
  const images = [];
  const seen = new Set();

  // gallery-item img (old design)
  const galSection = html.match(/class="image-gallery"[\s\S]*?(?=<div id="lightbox"|<footer|<\/body)/i)?.[0] || '';
  if (galSection) {
    for (const m of galSection.matchAll(/<img[^>]+src="([^"]+)"/gi)) {
      if (!seen.has(m[1])) { seen.add(m[1]); images.push(m[1]); }
    }
  }

  // pg-img-box (new minimalist design)
  if (!images.length) {
    for (const m of html.matchAll(/class="pg-img-box[^"]*"[^>]*>[\s\S]*?<img[^>]+src="([^"]+)"/gi)) {
      if (!seen.has(m[1])) { seen.add(m[1]); images.push(m[1]); }
    }
  }

  // thumb-item (previous redesign)
  if (!images.length) {
    for (const m of html.matchAll(/class="thumb-item[^"]*"[^>]*>[\s\S]*?<img[^>]+src="([^"]+)"/gi)) {
      if (!seen.has(m[1])) { seen.add(m[1]); images.push(m[1]); }
    }
  }

  // gallery-main main-img fallback
  if (!images.length) {
    const mainM = html.match(/id="main-img"[^>]*src="([^"]+)"/);
    if (mainM) { images.push(mainM[1]); seen.add(mainM[1]); }
  }

  // --- PRICE ---
  let price = 'מחיר על בקשה';
  const priceM = html.match(/class="(?:product-price|pg-price)"[^>]*>([\s\S]*?)<\/(?:p|div)>/i);
  if (priceM) {
    let raw = stripTags(priceM[1]).replace(/💰/g, '').replace(/₪/g, '').replace(/\s+/g, ' ').trim();
    if (raw) price = raw;
  }

  // --- DESCRIPTION & FEATURES ---
  let descFull = '';
  const features = [];

  // Old design: multiple .product-description paragraphs
  const oldDescs = [...html.matchAll(/class="product-description"[^>]*>([\s\S]*?)<\/p>/gi)];
  for (const m of oldDescs) {
    const inner = m[1];
    if (inner.includes('✓') || (inner.includes('<strong>') && inner.includes('<br'))) {
      // features block
      for (const line of inner.split(/<br\s*\/?>/i)) {
        const t = stripTags(line).replace(/✓/g, '').replace(/תכונות\s*:?/g, '').trim();
        if (t.length > 1) features.push(t);
      }
    } else {
      const t = stripTags(inner);
      if (t) descFull = t;
    }
  }

  // New minimalist .pg-desc
  if (!descFull) {
    const pgD = html.match(/class="pg-desc"[^>]*>([\s\S]*?)<\/p>/i);
    if (pgD) descFull = stripTags(pgD[1]);
  }

  // New minimalist .pg-feat-list
  if (!features.length) {
    const featSec = html.match(/class="pg-feat-list"[^>]*>([\s\S]*?)<\/ul>/i);
    if (featSec) {
      for (const m of featSec[1].matchAll(/<li[^>]*>([\s\S]*?)<\/li>/gi)) {
        const t = stripTags(m[1]).trim();
        if (t) features.push(t);
      }
    }
  }

  // --- TEXT BLOCKS ---
  const textBlocks = [];
  for (const m of html.matchAll(/class="(?:txt-block-free|pg-txt-block)"[^>]*>([\s\S]*?)<\/div>/gi)) {
    const t = m[1].replace(/<br\s*\/?>/gi, '\n').replace(/<[^>]+>/g, '').trim();
    if (t) textBlocks.push(t);
  }

  // --- FOLDER ---
  let folder = '';
  if (images.length && images[0].includes('/')) {
    folder = images[0].split('/').slice(0, -1).join('/');
  }

  return { name, images, price, descFull, features, textBlocks, folder, file: filename };
}

function buildPage(p) {
  const imgs = p.images || [];
  const gridItems = imgs.map((src, idx) =>
    `\n                <div class="pg-img-box" onclick="openLightbox(${idx})"${idx > 3 ? ' style="display:none"' : ''}>\n                    <img src="${xe(src)}" alt="" loading="${idx === 0 ? 'eager' : 'lazy'}">\n                </div>`
  ).join('');
  const hasMore = imgs.length > 4;
  const txtHtml = p.textBlocks.map(t =>
    `\n    <div class="pg-txt-block">${xe(t).replace(/\n/g, '<br>')}</div>`
  ).join('');
  const imgJson = JSON.stringify(imgs);
  const waText = encodeURIComponent('שלום, הגעתי דרך האתר, בקשר ל: ' + p.name);

  return `<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${xe(p.name)} — Kolbo Online</title>
    <script>if(localStorage.getItem('kolbo_dark')==='1')document.documentElement.classList.add('dark');<\/script>
    <style>
        *,*::before,*::after{margin:0;padding:0;box-sizing:border-box}
        body{font-family:'Segoe UI',Arial,sans-serif;background:#fff;color:#222;min-height:100vh;display:flex;flex-direction:column}
        .pg-header{padding:32px 72px 24px;border-bottom:1px solid #e8e8e8;display:flex;align-items:center;justify-content:space-between}
        .pg-logo{display:flex;align-items:center;gap:14px}
        .pg-logo img{height:44px}
        .pg-logo-text{font-size:15px;letter-spacing:5px;color:#bbb;font-weight:300;text-transform:uppercase}
        .pg-back{text-decoration:none;color:#aaa;font-size:13px;font-weight:300;letter-spacing:.5px;transition:color .15s}
        .pg-back:hover{color:#333}
        .pg-breadcrumb{padding:16px 72px;font-size:11px;color:#bbb;letter-spacing:1px}
        .pg-breadcrumb a{color:#bbb;text-decoration:none}
        .pg-breadcrumb a:hover{color:#555}
        .pg-main{max-width:1160px;margin:40px auto 80px;padding:0 72px;display:grid;grid-template-columns:1fr 1fr;gap:80px;flex:1}
        .pg-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px}
        .pg-img-box{background:#f5f5f5;aspect-ratio:1;overflow:hidden;cursor:zoom-in}
        .pg-img-box img{width:100%;height:100%;object-fit:cover;display:block;transition:transform .4s}
        .pg-img-box:hover img{transform:scale(1.04)}
        .pg-more-btn{grid-column:1/-1;border:1px solid #e0e0e0;background:#fff;padding:12px;font-size:12px;color:#aaa;letter-spacing:2px;cursor:pointer;font-family:inherit;transition:all .15s}
        .pg-more-btn:hover{background:#f9f9f9;color:#666}
        .pg-info{padding-top:8px;display:flex;flex-direction:column}
        .pg-tag{font-size:11px;letter-spacing:3px;color:#bbb;text-transform:uppercase;margin-bottom:18px}
        .pg-name{font-size:38px;font-weight:200;color:#111;line-height:1.2;margin-bottom:20px}
        .pg-price-wrap{margin-bottom:36px}
        .pg-price-label{font-size:11px;letter-spacing:2px;color:#bbb;margin-bottom:4px}
        .pg-price{font-size:20px;color:#444;font-weight:300}
        .pg-price strong{font-size:26px;color:#222;font-weight:400}
        .pg-divider{height:1px;background:#f0f0f0;margin:0 0 32px}
        .pg-desc{font-size:15px;color:#777;line-height:1.9;font-weight:300;margin-bottom:36px}
        .pg-feat-title{font-size:11px;letter-spacing:3px;color:#bbb;text-transform:uppercase;margin-bottom:16px}
        .pg-feat-list{list-style:none;margin-bottom:44px}
        .pg-feat-list li{display:flex;align-items:center;gap:10px;padding:10px 0;border-bottom:1px solid #f5f5f5;font-size:14px;color:#666;font-weight:300}
        .pg-feat-list li::before{content:"·";font-size:22px;color:#ccc;line-height:0;padding-top:3px}
        .pg-cta{display:inline-flex;align-items:center;justify-content:center;gap:10px;border:1px solid #333;padding:15px 40px;font-size:13px;color:#333;cursor:pointer;background:transparent;letter-spacing:1.5px;font-weight:400;font-family:inherit;text-decoration:none;transition:background .2s,color .2s;width:100%;margin-top:auto}
        .pg-cta:hover{background:#333;color:#fff}
        .pg-blocks{max-width:1160px;margin:0 auto 80px;padding:0 72px;display:flex;flex-direction:column;gap:1px}
        .pg-txt-block{padding:28px 0;border-top:1px solid #f0f0f0;font-size:14px;color:#777;line-height:1.9;font-weight:300}
        footer{border-top:1px solid #e8e8e8;padding:28px 72px;display:flex;justify-content:center;margin-top:auto}
        footer p{font-size:11px;color:#ccc;letter-spacing:2px;font-weight:300}
        .lb{display:none;position:fixed;inset:0;background:rgba(0,0,0,.92);z-index:1000;align-items:center;justify-content:center}
        .lb.on{display:flex}
        .lb img{max-width:88vw;max-height:86vh;object-fit:contain;transition:opacity .15s}
        .lb-x{position:fixed;top:20px;right:20px;color:#fff;font-size:28px;cursor:pointer;opacity:.6;transition:opacity .15s;background:none;border:none;font-family:inherit}
        .lb-x:hover{opacity:1}
        .lb-arr{position:fixed;top:50%;transform:translateY(-50%);color:#fff;font-size:24px;cursor:pointer;user-select:none;opacity:.5;transition:opacity .15s;background:none;border:none;font-family:inherit;padding:16px}
        .lb-arr:hover{opacity:1}
        .lb-prev{right:20px}.lb-next{left:20px}
        .lb-n{position:fixed;bottom:20px;left:50%;transform:translateX(-50%);color:rgba(255,255,255,.4);font-size:11px;letter-spacing:2px}
        #dark-toggle{position:fixed;bottom:24px;left:24px;width:40px;height:40px;border:1px solid #e0e0e0;background:#fff;font-size:17px;cursor:pointer;z-index:999;transition:all .2s;display:flex;align-items:center;justify-content:center;line-height:1}
        #dark-toggle:hover{border-color:#aaa}
        html.dark body{background:#111;color:#ddd}
        html.dark .pg-header{border-color:#222}
        html.dark .pg-logo-text{color:#444}
        html.dark .pg-back{color:#555}
        html.dark .pg-back:hover{color:#bbb}
        html.dark .pg-breadcrumb{color:#444}
        html.dark .pg-breadcrumb a{color:#444}
        html.dark .pg-img-box{background:#1a1a1a}
        html.dark .pg-tag{color:#444}
        html.dark .pg-name{color:#eee}
        html.dark .pg-price-label{color:#444}
        html.dark .pg-price{color:#888}
        html.dark .pg-price strong{color:#ccc}
        html.dark .pg-divider{background:#222}
        html.dark .pg-desc{color:#555}
        html.dark .pg-feat-title{color:#444}
        html.dark .pg-feat-list li{color:#666;border-color:#1e1e1e}
        html.dark .pg-feat-list li::before{color:#333}
        html.dark .pg-cta{border-color:#444;color:#aaa}
        html.dark .pg-cta:hover{background:#ddd;color:#111}
        html.dark .pg-more-btn{border-color:#222;background:#111;color:#444}
        html.dark .pg-more-btn:hover{background:#1a1a1a;color:#888}
        html.dark .pg-txt-block{border-color:#1e1e1e;color:#555}
        html.dark footer{border-color:#222}
        html.dark footer p{color:#333}
        html.dark #dark-toggle{background:#111;border-color:#333;color:#aaa}
        html.dark #dark-toggle:hover{border-color:#666}
        html.dark .lb{background:rgba(0,0,0,.97)}
        @media(max-width:860px){
            .pg-header,.pg-breadcrumb,.pg-main,.pg-blocks,footer{padding-right:24px;padding-left:24px}
            .pg-main{grid-template-columns:1fr;gap:40px;margin-top:24px}
            .pg-name{font-size:28px}
        }
    </style>
</head>
<body>
    <header class="pg-header">
        <a href="index.html" class="pg-back">← חזרה לקטלוג</a>
        <div class="pg-logo">
            <img src="logokolbo.jpeg" alt="Kolbo">
            <span class="pg-logo-text">Kolbo Online</span>
        </div>
        <div style="width:100px"></div>
    </header>
    <div class="pg-breadcrumb"><a href="index.html">קטלוג</a> &nbsp;/&nbsp; ${xe(p.name)}</div>

    <main class="pg-main">
        <div>
            <div class="pg-grid">${gridItems}
            </div>${hasMore ? `\n            <button class="pg-more-btn" onclick="openLightbox(4)">+ ${imgs.length - 4} תמונות נוספות</button>` : ''}
        </div>
        <div class="pg-info">
            <div class="pg-tag">מוצר</div>
            <h1 class="pg-name">${xe(p.name)}</h1>
            <div class="pg-price-wrap">
                <div class="pg-price-label">מחיר</div>
                <div class="pg-price">${p.price && p.price !== 'מחיר על בקשה'
                  ? `<strong>₪ ${xe(p.price)}</strong>`
                  : '<span style="color:#bbb;font-size:15px">מחיר על בקשה</span>'}</div>
            </div>
            <div class="pg-divider"></div>
            ${p.descFull ? `<p class="pg-desc">${xe(p.descFull)}</p>` : ''}
            ${p.features.length ? `<div class="pg-feat-title">פרטים</div>\n            <ul class="pg-feat-list">${p.features.map(f => `\n                <li>${xe(f)}</li>`).join('')}\n            </ul>` : ''}
            <a href="https://wa.me/${WA}?text=${waText}" class="pg-cta">💬 &nbsp; צור קשר</a>
        </div>
    </main>
${txtHtml ? `\n    <div class="pg-blocks">${txtHtml}\n    </div>` : ''}
    <footer><p>© 2026 KOLBO ONLINE</p></footer>

    <button id="dark-toggle" onclick="toggleDark()" title="מצב חושך / בהיר"></button>

    <div id="lb" class="lb">
        <button class="lb-x" onclick="lbClose()">×</button>
        <img id="lb-img" src="" alt="">
        <button class="lb-arr lb-prev" onclick="lbNav(-1)">›</button>
        <button class="lb-arr lb-next" onclick="lbNav(1)">‹</button>
        <div class="lb-n" id="lb-n"></div>
    </div>
    <script>
        function toggleDark(){var on=document.documentElement.classList.toggle('dark');localStorage.setItem('kolbo_dark',on?'1':'0');document.getElementById('dark-toggle').textContent=on?'☀':'☾';}
        document.getElementById('dark-toggle').textContent=document.documentElement.classList.contains('dark')?'☀':'☾';
        var S=${imgJson},i=0;
        function openLightbox(idx){i=idx;lbShow();document.getElementById('lb').classList.add('on');document.body.style.overflow='hidden';}
        function lbShow(){var el=document.getElementById('lb-img');el.style.opacity='0';el.src=S[i]||'';el.onload=function(){el.style.opacity='1'};document.getElementById('lb-n').textContent=(i+1)+' / '+S.length;}
        function lbNav(d){i=(i+d+S.length)%S.length;lbShow();}
        function lbClose(){document.getElementById('lb').classList.remove('on');document.body.style.overflow='';}
        document.getElementById('lb').addEventListener('click',function(e){if(e.target===this)lbClose();});
        document.addEventListener('keydown',function(e){if(!document.getElementById('lb').classList.contains('on'))return;if(e.key==='Escape')lbClose();if(e.key==='ArrowRight')lbNav(-1);if(e.key==='ArrowLeft')lbNav(1);});
        var ts=0;
        document.getElementById('lb').addEventListener('touchstart',function(e){ts=e.touches[0].clientX;},{passive:true});
        document.getElementById('lb').addEventListener('touchend',function(e){var tx=e.changedTouches[0].clientX-ts;if(Math.abs(tx)>45)lbNav(tx>0?-1:1);});
    </script>
</body>
</html>`;
}

const files = fs.readdirSync(DIR).filter(f => /^product-\d+\.html$/.test(f)).sort();
let done = 0;

for (const file of files) {
  const filePath = path.join(DIR, file);
  const html = fs.readFileSync(filePath, 'utf8');
  const product = parseProduct(html, file);

  if (!product.name) {
    console.log(`  SKIP  ${file} — no name`);
    continue;
  }

  fs.writeFileSync(filePath, buildPage(product), 'utf8');
  console.log(`  ✓  ${file.padEnd(18)} "${product.name}"  (${product.images.length} imgs, ${product.features.length} feats)`);
  done++;
}

console.log(`\n✅ Done: ${done}/${files.length} files rebuilt.`);
