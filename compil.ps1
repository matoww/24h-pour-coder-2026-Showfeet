.\fennel --require-as-include --compile src/main.fnl  > bundle.lua
# Chemin du fichier source UTF-16
$source = "bundle.lua"

# Chemin du fichier de sortie UTF-8
$destination = "bundle_utf8.lua"

# Lire en UTF-16 (Unicode en PowerShell)
$content = Get-Content $source -Encoding Unicode -Raw

[System.IO.File]::WriteAllText($destination, $content, (New-Object System.Text.UTF8Encoding($false)))

.\tic80 --skip --fs . --cmd="load assets/game.tic & import code bundle_utf8.lua & run"