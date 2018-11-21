dotnet tool install -g cogs

mkdir ddi\

echo Validate
cogs validate .
if %errorlevel% neq 0 exit /b %errorlevel%

echo JSON
cogs publish-json . ddi\json --overwrite

echo GraphQL
cogs publish-graphql . ddi\graphql --overwrite

echo XSD
cogs publish-xsd . ddi\xsd --overwrite --namespace "http://www.ddialliance.org/ddi" --namespacePrefix ddi

echo UML
cogs publish-uml . ddi\uml --location graphviz\release\bin\dot.exe --overwrite

echo OWL
cogs publish-owl . ddi\owl --overwrite

REM cogs publish-dot . --location ddi\dot graphviz\release\bin\dot.exe --overwrite --single
REM cogs publish-dot . --location ddi\dot graphviz\release\bin\dot.exe --overwrite --all --inheritance

echo Sphinx
cogs publish-sphinx . ddi\sphinx --location graphviz\release\bin\dot.exe --overwrite

echo C#
cogs publish-cs . ddi\csharp --overwrite

echo Build Sphinx
REM Generate documentation with Sphinx.
cd ddi\sphinx
CALL make dirhtml
cd \projects\ddimodel

echo Zipping artifacts
7z a -tzip ddi.zip ddi\*

