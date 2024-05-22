#!/bin/bash -l

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title srgn
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Developer Utils

# Documentation:
# @raycast.author Alex Povel
# @raycast.authorURL https://github.com/alexpovel/srgn?tab=readme-ov-file#german

# Login shell (`bash -l`) and `bash.enable` in nix-darwin config allow Nix binaries to
# be found here.

# Ensure the directory this ends up in is registered in raycast: https://github.com/raycast/script-commands/blob/88fe21feb9f697a2d4cc76e48796af06c283e532/README.md#install-script-commands-from-this-repository
RES=$(pbpaste | srgn --german)
pbcopy <<< "$RES"
echo "$RES"
