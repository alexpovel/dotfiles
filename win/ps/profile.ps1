# To keep syncing easy, set up a link to this file.
# In PowerShell, while in the directory that contains your profile, e.g.
# C:\Users\alex\Documents\WindowsPowershell, run:

# New-Item -ItemType HardLink -Name "Microsoft.Powershell_profile.ps1" -Value "C:\Users\alex\Documents\dev\repos\other\dotfiles\win\ps\Microsoft.Powershell_profile.ps1"

Import-Module posh-git
Import-Module oh-my-posh
Set-PoshPrompt -Theme agnoster

##
# Functions
##

# enable vim command
function vim ($File){
    bash -c "vim $File"
}

##
# PSReadLine, see https://github.com/PowerShell/PSReadLine
##

## behaviour of Tab key autocomplete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
## From docs:
## With these bindings, up arrow/down arrow will work like PowerShell/cmd if the
## current command line is blank. If you've entered some text though, it will
## search the history for commands that start with the currently entered text.
##
## Like zsh completion.
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

##
# Aliases
##

# get-command is PS-equivalent to Unix which
New-Alias which get-command
# ipython shortcut
New-Alias pi ipython
#
New-Alias g git

##
# Other
##

# git diff output uses less; it will be buggy without utf8
$env:LESSCHARSET='UTF-8'

# console output, e.g, when writing git diff output to file using pipe: | Out-File
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# https://stackoverflow.com/a/50758683/11477374
function Update-Path {
  $env:Path = (
    [System.Environment]::GetEnvironmentVariable("Path","Machine"),
    [System.Environment]::GetEnvironmentVariable("Path","User")
  ) -join ";"
  "Path is now:"
  $env:Path
}
