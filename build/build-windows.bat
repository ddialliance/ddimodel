mkdir ddi-lifecycle-all-outputs

echo Validate
cogs validate .
if %errorlevel% neq 0 exit /b %errorlevel%

echo JSON
cogs publish-json . ddi-lifecycle-all-outputs\json --overwrite

echo GraphQL
cogs publish-graphql . ddi-lifecycle-all-outputs\graphql --overwrite

echo XSD
cogs publish-xsd . ddi-lifecycle-all-outputs\xsd --overwrite --namespace "ddi:instance:4_0" --namespacePrefix ddi

echo DCTAP
cogs publish-dctap . ddi-lifecycle-all-outputs\dctap --overwrite

echo UML
cogs publish-uml . ddi-lifecycle-all-outputs\uml --location graphviz\release\bin\dot.exe --overwrite

echo OWL
cogs publish-owl . ddi-lifecycle-all-outputs\owl --namespace "http://rdf-vocabulary.ddialliance.org/lifecycle#" --namespacePrefix "ddi" --overwrite

echo LinkML
cogs publish-linkml . ddi-lifecycle-all-outputs\linkml --namespace "http://rdf-vocabulary.ddialliance.org/lifecycle#" --namespacePrefix "ddi" --overwrite

echo Build LinkML
PUSHD ddi-lifecycle-all-outputs\linkml
CALL gen-owl --metadata-profile rdfs -f ttl linkml.yml > ..\owl\ddi4.owl.ttl
CALL gen-shacl linkml.yml > ..\owl\ddi4.shacl
CALL gen-shex linkml.yml > ..\owl\ddi4.shex
POPD

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