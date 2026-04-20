# Replace lightbox CSS in product HTML files
$correctLightboxCSS = @"
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

Get-ChildItem "product-*.html" | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content $file -Raw

    # Replace the lightbox CSS block
    $replacement = $correctLightboxCSS + "`n        footer"
    $content = $content -replace '(?s)/\* LIGHTBOX \*\/.*?(?=\s*footer)', $replacement

    # Write back
    Set-Content $file $content -Encoding UTF8
}