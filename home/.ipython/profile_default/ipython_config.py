# https://ipython.readthedocs.io/en/stable/config/intro.html#ipythondir
# https://ipython.readthedocs.io/en/stable/config/intro.html#example-configuration-file
# `c` is magically defined.

c.TerminalIPythonApp.display_banner = False
c.InteractiveShellApp.exec_files = [
    "init.py",
]
