mkdir ddi-lifecycle-all-outputs

echo Validate
cogs validate .
if %errorlevel% neq 0 exit /b %errorlevel%

echo JSON
cogs publish-json . ddi-lifecycle-all-outputs\json --overwrite

echo GraphQL
cogs publish-graphql . ddi-lifecycle-all-outputs\graphql --overwrite

echo XSD
cogs publish-xsd . ddi-lifecycle-all-outputs\xsd --overwrite --namespace "http://www.ddialliance.org/ddi" --namespacePrefix ddi

echo UML
cogs publish-uml . ddi-lifecycle-all-outputs\uml --location graphviz\release\bin\dot.exe --overwrite

echo OWL
cogs publish-owl . ddi-lifecycle-all-outputs\owl --overwrite

REM cogs publish-dot . --location ddi-lifecycle-all-outputs\dot graphviz\release\bin\dot.exe --overwrite --single
REM cogs publish-dot . --location ddi-lifecycle-all-outputs\dot graphviz\release\bin\dot.exe --overwrite --all --inheritance

echo Sphinx
cogs publish-sphinx . ddi-lifecycle-all-outputs\sphinx --location graphviz\release\bin\dot.exe --overwrite

echo C#
cogs publish-cs . ddi-lifecycle-all-outputs\csharp --overwrite

echo Build Sphinx
REM Generate documentation with Sphinx.
PUSHD ddi-lifecycle-all-outputs\sphinx
CALL make dirhtml
POPD

echo Copy outputs
mkdir ddi-lifecycle
xcopy ddi-lifecycle-all-outputs\xsd ddi-lifecycle\xsd /E /I
xcopy ddi-lifecycle-all-outputs\json ddi-lifecycle\json /E /I
xcopy ddi-lifecycle-all-outputs\owl ddi-lifecycle\owl /E /I

echo Making file suffix. If this commit it tagged, use the tag name. If not, use the date.
$suffix = if ($env:GITHUB_REF -match 'refs/tags/(.+)') { $Matches[1] } else { (Get-Date -Format "yyyyMMdd") }

echo Zip the artifact directories

7z a -tzip "ddi-lifecycle-all-outputs.zip" "ddi-lifecycle-all-outputs\*"
7z a -tzip "ddi-lifecycle.zip" "ddi-lifecycle\*"