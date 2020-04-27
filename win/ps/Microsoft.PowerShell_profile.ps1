# enable vim command
function vim ($File){
    bash -c "vim $File"
}

# behaviour of Tab key autocomplete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# get-command is PS-equivalent to Unix which
New-Alias which get-command

# ipython shortcut
New-Alias py ipython

# git diff output uses less; it will be buggy without utf8
$env:LESSCHARSET='UTF-8'

# console output, e.g, when writing git diff output to file using pipe: | Out-File
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Import-Module posh-git
Import-Module oh-my-posh
Set-Theme Agnoster

# For Agnoster theme, "user@host" will be hidden if user==DefaultUser
$DefaultUser = "alex"

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
