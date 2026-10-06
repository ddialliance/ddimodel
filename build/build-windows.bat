@echo off
setlocal EnableExtensions DisableDelayedExpansion

REM Resolve the model independently of the caller's working directory.
for %%I in ("%~dp0..") do set "MODEL_ROOT=%%~fI"

REM COGS 2 publication targets must be outside the model source directory.
REM DDI_OUTPUT_ROOT can override the default for local builds.
if not defined DDI_OUTPUT_ROOT if defined RUNNER_TEMP set "DDI_OUTPUT_ROOT=%RUNNER_TEMP%\ddi-lifecycle-all-outputs"
if not defined DDI_OUTPUT_ROOT set "DDI_OUTPUT_ROOT=%TEMP%\ddi-lifecycle-all-outputs"
for %%I in ("%DDI_OUTPUT_ROOT%") do set "DDI_OUTPUT_ROOT=%%~fI"
if not defined COGS_PYTHON set "COGS_PYTHON=python"
if not defined COGS_DOT if exist "%MODEL_ROOT%\graphviz\release\bin\dot.exe" set "COGS_DOT=%MODEL_ROOT%\graphviz\release\bin\dot.exe"
set "DOT_OPTION="
if defined COGS_DOT set DOT_OPTION=--dot "%COGS_DOT%"

pushd "%MODEL_ROOT%" || exit /b 1
echo Build outputs: %DDI_OUTPUT_ROOT%

echo Validate
call :run cogs validate "%MODEL_ROOT%" || goto :fail

echo JSON
call :run cogs publish-json "%MODEL_ROOT%" "%DDI_OUTPUT_ROOT%\json" --overwrite || goto :fail

echo GraphQL
call :run cogs publish-graphql "%MODEL_ROOT%" "%DDI_OUTPUT_ROOT%\graphql" --overwrite || goto :fail

echo XSD
call :run cogs publish-xsd "%MODEL_ROOT%" "%DDI_OUTPUT_ROOT%\xsd" --overwrite --namespace "ddi:instance:4_0" --namespacePrefix ddi || goto :fail

echo DCTAP
call :run cogs publish-dctap "%MODEL_ROOT%" "%DDI_OUTPUT_ROOT%\dctap" --overwrite || goto :fail

echo UML
call :run cogs publish-uml "%MODEL_ROOT%" "%DDI_OUTPUT_ROOT%\uml" --mode ea %DOT_OPTION% --overwrite || goto :fail

echo OWL
call :run cogs publish-owl "%MODEL_ROOT%" "%DDI_OUTPUT_ROOT%\owl" --namespace "http://rdf-vocabulary.ddialliance.org/lifecycle#" --namespacePrefix ddi --overwrite || goto :fail

echo LinkML
call :run cogs publish-linkml "%MODEL_ROOT%" "%DDI_OUTPUT_ROOT%\linkml" --namespace "http://rdf-vocabulary.ddialliance.org/lifecycle#" --namespacePrefix ddi --overwrite || goto :fail

echo Build LinkML
REM Keep the LinkML-derived ontology separate from COGS's authoritative ddi4.ttl.
call :run gen-owl --metadata-profile rdfs -f ttl "%DDI_OUTPUT_ROOT%\linkml\linkml.yml" > "%DDI_OUTPUT_ROOT%\owl\ddi4.owl.ttl" || goto :fail
call :run gen-shacl "%DDI_OUTPUT_ROOT%\linkml\linkml.yml" > "%DDI_OUTPUT_ROOT%\owl\ddi4.shacl" || goto :fail
call :run gen-shex "%DDI_OUTPUT_ROOT%\linkml\linkml.yml" > "%DDI_OUTPUT_ROOT%\owl\ddi4.shex" || goto :fail

echo Sphinx
call :run cogs publish-sphinx "%MODEL_ROOT%" "%DDI_OUTPUT_ROOT%\sphinx" %DOT_OPTION% --overwrite || goto :fail

echo C#
call :run cogs publish-cs "%MODEL_ROOT%" "%DDI_OUTPUT_ROOT%\csharp" --overwrite || goto :fail

echo Build Sphinx
REM Invoke the selected Python directly, without relying on make discovery.
call :run "%COGS_PYTHON%" -m sphinx -M dirhtml "%DDI_OUTPUT_ROOT%\sphinx\source" "%DDI_OUTPUT_ROOT%\sphinx\build" || goto :fail

popd
endlocal & exit /b 0

:run
call %*
exit /b %errorlevel%

:fail
set "BUILD_EXIT=%errorlevel%"
if "%BUILD_EXIT%"=="0" set "BUILD_EXIT=1"
echo Build failed with exit code %BUILD_EXIT%.
popd
endlocal & exit /b %BUILD_EXIT%
