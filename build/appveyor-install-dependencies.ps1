pwd

# Download Graphviz
Start-FileDownload 'https://graphviz.gitlab.io/_pages/Download/windows/graphviz-2.38.zip'

7z x graphviz-2.38.zip -y -o"graphviz"

ls cogs
ls graphviz

# Download Sphinx
pip install sphinx
pip install sphinx_rtd_theme
pip install Pygments
