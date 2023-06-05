# dotfiles

Pragmatic little scripts without much beauty to them.
They're not tested thoroughly and will fall on their face in most edge cases.
At worst, at least they're written documentation of what to install and/or do when first setting up a new machine.

They're supposed to be idempotent: when changing a setting, just run them again to apply.
Downside is speed, upside is safety and simplicity.

## Usage

Execute the script whose name corresponds to your distribution.

## Context

I used to have these in Ansible, but the overhead and YAML hell of that got too much, in the context of what it is (single-host, rarely-run configuration management).
Keeping it simple (and ugly...) now.
