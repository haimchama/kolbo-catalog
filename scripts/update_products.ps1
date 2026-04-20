# Script to add logo and update colors for all product pages

$files = Get-ChildItem -Path "product-*.html"

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8

    # Update body background
    $content = $content -replace 'background: #f5f5f5;', 'background: #f8f9fa;'

    # Update header background
    $content = $content -replace 'background: linear-gradient\(135deg, #667eea 0%, #764ba2 100%\);', 'background: #343a40;'

    # Add logo before h1 in header
    $content = $content -replace '<header>\s*<a href="index\.html" class="back-button">[^<]*</a>\s*<h1>', @'
<header>
        <div style="text-align: center; margin-bottom: 15px;">
            <img src="logokolbo.jpeg" alt="Kolbo Logo" style="height: 60px; width: auto;">
        </div>
        <a href="index.html" class="back-button">← חזרה לקטלוג</a>
        <h1>
'@

    Set-Content -Path $file.FullName -Value $content -Encoding UTF8
}

Write-Host "Updated all product pages with logo and professional colors."