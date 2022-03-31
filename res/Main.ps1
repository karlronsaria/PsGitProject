$scripts = dir "$PsScriptRoot\script\*.ps1"

foreach ($script in $scripts) {
    . $script
}
