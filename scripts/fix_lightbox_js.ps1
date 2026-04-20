# Replace lightbox JS in product HTML files
$correctLightboxJS = @"
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

    # Replace the JS after LB_IMGS
    $replacement = "var LB_IMGS=$lbImgs;" + $correctLightboxJS
    $content = $content -replace '(?s)var LB_IMGS=\[.*?\];.*?(?=</script>)', $replacement

    # Write back
    Set-Content $file $content -Encoding UTF8
}