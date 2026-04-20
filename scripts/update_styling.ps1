# Change gallery item border to black in all product files

$files = Get-ChildItem -Path "product-*.html" | Where-Object { $_.Name -ne "product-1.html" }

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw

    # Change border to black
    $content = $content -replace 'border: 3px solid transparent; background: linear-gradient\(white, white\) padding-box, linear-gradient\(to right, #C15317, #C99B26, #005B6F\) border-box;', 'border: 3px solid black;'

    # Update price text to contact link - find lines with 💰 and replace them
    $content = $content -replace '            <p class="product-price">💰.*?</p>', '            <p class="product-price"><a href="https://wa.me/972502123209" style="color: #667eea; text-decoration: none;">צור קשר עם הספק</a></p>'

    Set-Content $file.FullName $content
    Write-Host "Updated $($file.Name)"
}