# Script to update logo size and border-radius for all product pages

$files = Get-ChildItem -Path "product-*.html"

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8

    # Update logo style
    $content = $content -replace 'style="height: 60px; width: auto;"', 'style="height: 80px; width: auto; border-radius: 8px;"'

    Set-Content -Path $file.FullName -Value $content -Encoding UTF8
}

Write-Host "Updated logo size and border-radius for all product pages."