pwd

# Download COGS
Start-FileDownload 'http://ci.appveyor.com/api/projects/DanSmith/cogs/artifacts/Cogs.Console/bin/Release/netcoreapp2.0/Windows-CogsRelease.zip'
7z x Windows-CogsRelease.zip -y -o"cogs"

# Download Graphviz
Start-FileDownload 'http://www.graphviz.org/pub/graphviz/stable/windows/graphviz-2.38.zip'
7z x graphviz-2.38.zip -y -o"graphviz"

ls cogs
ls graphviz

# Download Sphinx
pip install sphinx
pip install sphinx_rtd_theme
pip install Pygments
