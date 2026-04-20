# Fix duplicate CSS in product files

$files = Get-ChildItem -Path "product-*.html" | Where-Object { $_.Name -ne "product-1.html" }

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw

    # Remove duplicate arrow CSS
    $duplicatePattern = '\.lightbox-prev, \.lightbox-next \{ position: absolute; top: 50%; transform: translateY\(-50%\); color: white; font-size: 40px; cursor: pointer; z-index: 1001; background: rgba\(0,0,0,0\.5\); padding: 10px; border-radius: 50%; \}\s*\.lightbox-prev \{ left: -60px; \}\s*\.lightbox-next \{ right: -60px; \}\s*\.lightbox-prev:hover, \.lightbox-next:hover \{ background: rgba\(102,126,234,0\.7\); \}'

    $content = $content -replace $duplicatePattern, ''

    Set-Content $file.FullName $content
    Write-Host "Fixed $($file.Name)"
}