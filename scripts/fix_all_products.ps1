# Fix product HTML files with correct lightbox
$lightboxCSS = @"
        /* LIGHTBOX */
        .lightbox { display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(0,0,0,0.92); align-items: center; justify-content: center; touch-action: pan-y; }
        .lightbox.active { display: flex; }
        .lightbox-content { position: relative; max-width: 92vw; max-height: 90vh; display: flex; align-items: center; justify-content: center; }
        .lightbox img { max-width: 88vw; max-height: 82vh; border-radius: 8px; object-fit: contain; user-select: none; -webkit-user-drag: none; transition: opacity 0.18s; }
        .lightbox-close { position: fixed; top: 16px; right: 16px; color: white; font-size: 38px; cursor: pointer; z-index: 1002; background: rgba(0,0,0,0.4); border-radius: 50%; width: 48px; height: 48px; display: flex; align-items: center; justify-content: center; line-height: 1; }
        .lb-arrow { position: fixed; top: 50%; transform: translateY(-50%); color: white; font-size: 30px; cursor: pointer; z-index: 1002; background: rgba(0,0,0,0.35); border-radius: 50%; width: 48px; height: 48px; display: flex; align-items: center; justify-content: center; transition: background 0.2s; user-select: none; }
        .lb-arrow:hover { background: rgba(102,126,234,0.6); }
        .lb-prev { right: 10px; }
        .lb-next { left: 10px; }
        .lb-counter { position: fixed; bottom: 18px; left: 50%; transform: translateX(-50%); color: rgba(255,255,255,0.75); font-size: .85em; background: rgba(0,0,0,0.4); padding: 4px 14px; border-radius: 20px; }
"@

$lightboxHTML = @"
    <div id="lightbox" class="lightbox">
        <span class="lightbox-close" onclick="closeLightbox()">&times;</span>
        <div class="lightbox-content">
            <img id="lightbox-img" src="" alt="">
        </div>
        <span class="lb-arrow lb-prev" onclick="lbNav(-1)">&#8250;</span>
        <span class="lb-arrow lb-next" onclick="lbNav(1)">&#8249;</span>
        <span class="lb-counter" id="lb-counter"></span>
    </div>
"@

$lightboxJS = @"
        var lbIdx=0;
        function openLightbox(idx){
            lbIdx=idx;lbShow();
            document.getElementById('lightbox').classList.add('active');
            document.body.style.overflow='hidden';
        }
        function lbShow(){
            var img=document.getElementById('lightbox-img');
            img.style.opacity='0';
            img.src=LB_IMGS[lbIdx]||'';
            img.onload=function(){img.style.opacity='1'};
            document.getElementById('lb-counter').textContent=(lbIdx+1)+' / '+LB_IMGS.length;
        }
        function lbNav(d){lbIdx=(lbIdx+d+LB_IMGS.length)%LB_IMGS.length;lbShow();}
        function closeLightbox(){document.getElementById('lightbox').classList.remove('active');document.body.style.overflow='auto';}
        document.addEventListener('keydown',function(e){
            if(!document.getElementById('lightbox').classList.contains('active'))return;
            if(e.key==='Escape')closeLightbox();
            if(e.key==='ArrowRight'||e.key==='ArrowUp')lbNav(-1);
            if(e.key==='ArrowLeft'||e.key==='ArrowDown')lbNav(1);
        });
        document.getElementById('lightbox').addEventListener('click',function(e){if(e.target.id==='lightbox')closeLightbox()});
        /* SWIPE */
        var ts=0,tx=0;
        document.getElementById('lightbox').addEventListener('touchstart',function(e){ts=e.touches[0].clientX;tx=0},{ passive:true });
        document.getElementById('lightbox').addEventListener('touchmove',function(e){tx=e.touches[0].clientX-ts},{ passive:true });
        document.getElementById('lightbox').addEventListener('touchend',function(){
            if(Math.abs(tx)>45){lbNav(tx>0?-1:1);}
        });
        document.querySelectorAll('.gallery-item img').forEach(function(img){
            img.addEventListener('error',function(){this.src='data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22200%22 height=%22200%22%3E%3Crect fill=%22%23f0f0f0%22 width=%22200%22 height=%22200%22/%3E%3Ctext x=%2250%25%22 y=%2250%25%22 text-anchor=%22middle%22 dy=%22.3em%22 fill=%22%23999%22%3EImage Not Found%3C/text%3E%3C/svg%3E'});
        });
"@

Get-ChildItem "product-*.html" | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content $file -Raw

    # Extract LB_IMGS
    if ($content -match 'var LB_IMGS=(\[.*?\]);') {
        $lbImgs = $matches[1]
    } else {
        continue
    }

    # Remove conflict markers
    $content = $content -replace '(?s)<<<<<<< HEAD.*?(?=>>>>>>> [a-f0-9]+).*?(>>>>>>> [a-f0-9]+)', ''

    # Replace lightbox CSS
    $content = $content -replace '(?s)/\* LIGHTBOX \*\/.*?(?=footer)', $lightboxCSS + "`n        footer"

    # Replace lightbox HTML
    $content = $content -replace '(?s)<div id="lightbox".*?</div>', $lightboxHTML

    # Replace JS
    $content = $content -replace '(?s)var LB_IMGS=.*?;', "var LB_IMGS=$lbImgs;"
    $content = $content -replace '(?s)var lbIdx=0;.*?(?=</script>)', "var lbIdx=0;" + $lightboxJS

    # Write back
    Set-Content $file $content -Encoding UTF8
}