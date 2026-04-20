# Fix merge conflicts in product HTML files
Get-ChildItem "product-*.html" | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content $file -Raw

    # Remove entire conflict blocks
    $content = $content -replace '(?s)<<<<<<< HEAD.*?(?=>>>>>>> [a-f0-9]+).*?(>>>>>>> [a-f0-9]+)', ''

    # Write back
    Set-Content $file $content -Encoding UTF8
}