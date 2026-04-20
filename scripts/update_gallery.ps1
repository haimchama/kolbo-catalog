# Update all product HTML files with new gallery navigation

$files = Get-ChildItem -Path "product-*.html" | Where-Object { $_.Name -ne "product-1.html" }

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw

    # Update CSS
    $oldCss = '.lightbox-content { position: relative; max-width: 90%; max-height: 90%; }'
    $newCss = '.lightbox-content { position: relative; max-width: 90%; max-height: 90%; display: flex; align-items: center; }'
    $content = $content -replace [regex]::Escape($oldCss), $newCss

    $closeHover = '.lightbox-close:hover { color: #667eea; }'
    $newCloseHover = '.lightbox-close:hover { color: #667eea; }
        .lightbox-prev, .lightbox-next { position: absolute; top: 50%; transform: translateY(-50%); color: white; font-size: 40px; cursor: pointer; z-index: 1001; background: rgba(0,0,0,0.5); padding: 10px; border-radius: 50%; }
        .lightbox-prev { right: -60px; }
        .lightbox-next { left: -60px; }
        .lightbox-prev:hover, .lightbox-next:hover { background: rgba(102,126,234,0.7); }'
    $content = $content -replace [regex]::Escape($closeHover), $newCloseHover

    # Update HTML
    $oldHtml = '    <div id="lightbox" class="lightbox">
        <div class="lightbox-content">
            <span class="lightbox-close" onclick="closeLightbox()">&times;</span>
            <img id="lightbox-img" src="" alt="">
        </div>
    </div>'
    $newHtml = '    <div id="lightbox" class="lightbox">
        <div class="lightbox-content">
            <span class="lightbox-prev" onclick="changeImage(-1)">&#10094;</span>
            <img id="lightbox-img" src="" alt="">
            <span class="lightbox-next" onclick="changeImage(1)">&#10095;</span>
            <span class="lightbox-close" onclick="closeLightbox()">&times;</span>
        </div>
    </div>'
    $content = $content -replace [regex]::Escape($oldHtml), $newHtml

    # Update JS
    $oldJs = '    <script>
        function openLightbox(el){document.getElementById(''lightbox-img'').src=el.querySelector(''img'').src;document.getElementById(''lightbox'').classList.add(''active'');document.body.style.overflow=''hidden''}
        function closeLightbox(){document.getElementById(''lightbox'').classList.remove(''active'');document.body.style.overflow=''auto''}
        document.addEventListener(''keydown'',e=>e.key===''Escape''&&closeLightbox());
        document.getElementById(''lightbox'').addEventListener(''click'',e=>e.target.id===''lightbox''&&closeLightbox());
        document.querySelectorAll(''.gallery-item img'').forEach(img=>img.addEventListener(''error'',function(){this.src=''data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22200%22 height=%22200%22%3E%3Crect fill=%22%23f0f0f0%22 width=%22200%22 height=%22200%22/%3E%3Ctext x=%2250%25%22 y=%2250%25%22 text-anchor=%22middle%22 dy=%22.3em%22 fill=%22%23999%22%3EImage Not Found%3C/text%3E%3C/svg%3E''}));
    </script>'
    $newJs = '    <script>
        let images = [];
        let currentIndex = 0;

        document.addEventListener(''DOMContentLoaded'', function() {
            const galleryItems = document.querySelectorAll(''.gallery-item'');
            galleryItems.forEach((item, index) => {
                const img = item.querySelector(''img'');
                images.push(img.src);
                item.setAttribute(''data-index'', index);
            });
        });

        function openLightbox(el) {
            currentIndex = parseInt(el.getAttribute(''data-index''));
            document.getElementById(''lightbox-img'').src = images[currentIndex];
            document.getElementById(''lightbox'').classList.add(''active'');
            document.body.style.overflow = ''hidden'';
        }

        function closeLightbox() {
            document.getElementById(''lightbox'').classList.remove(''active'');
            document.body.style.overflow = ''auto'';
        }

        function changeImage(direction) {
            currentIndex += direction;
            if (currentIndex < 0) currentIndex = images.length - 1;
            if (currentIndex >= images.length) currentIndex = 0;
            document.getElementById(''lightbox-img'').src = images[currentIndex];
        }

        document.addEventListener(''keydown'', function(e) {
            if (document.getElementById(''lightbox'').classList.contains(''active'')) {
                if (e.key === ''Escape'') closeLightbox();
                else if (e.key === ''ArrowLeft'') changeImage(-1);
                else if (e.key === ''ArrowRight'') changeImage(1);
            }
        });

        document.getElementById(''lightbox'').addEventListener(''click'', function(e) {
            if (e.target.id === ''lightbox'') closeLightbox();
        });

        document.querySelectorAll(''.gallery-item img'').forEach(img => img.addEventListener(''error'', function() {
            this.src = ''data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22200%22 height=%22200%22%3E%3Crect fill=%22%23f0f0f0%22 width=%22200%22 height=%22200%22/%3E%3Ctext x=%2250%25%22 y=%2250%25%22 text-anchor=%22middle%22 dy=%22.3em%22 fill=%22%23999%22%3EImage Not Found%3C/text%3E%3C/svg%3E'';
        }));
    </script>'
    $content = $content -replace [regex]::Escape($oldJs), $newJs

    Set-Content $file.FullName $content
    Write-Host "Updated $($file.Name)"
}