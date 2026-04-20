# Fix product HTML files with correct lightbox
Get-ChildItem "product-*.html" | ForEach-Object {
    $file = $_.FullName
    $lines = Get-Content $file

    # Remove lines with conflict markers
    $lines = $lines | Where-Object { $_ -notmatch '^.*<<<<<<< HEAD.*$' -and $_ -notmatch '^.*=======.*$' -and $_ -notmatch '^.*>>>>>>> [a-f0-9]+.*$' }

    # Write back
    Set-Content $file $lines -Encoding UTF8
}