#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="ddi-lifecycle-all-outputs"
GRAPHVIZ_DOT="${GRAPHVIZ_DOT:-dot}"

mkdir -p "$OUTPUT_DIR"

echo "Validate"
cogs validate .

echo "JSON"
cogs publish-json . "$OUTPUT_DIR/json" --overwrite

echo "GraphQL"
cogs publish-graphql . "$OUTPUT_DIR/graphql" --overwrite

echo "XSD"
cogs publish-xsd . "$OUTPUT_DIR/xsd" --overwrite --namespace "ddi:instance:4_0" --namespacePrefix ddi

echo "DCTAP"
cogs publish-dctap . "$OUTPUT_DIR/dctap" --overwrite

echo "UML"
cogs publish-uml . "$OUTPUT_DIR/uml" --location "$GRAPHVIZ_DOT" --overwrite

echo "OWL"
cogs publish-owl . "$OUTPUT_DIR/owl" --namespace "http://rdf-vocabulary.ddialliance.org/lifecycle#" --namespacePrefix "ddi" --overwrite

echo "LinkML"
cogs publish-linkml . "$OUTPUT_DIR/linkml" --namespace "http://rdf-vocabulary.ddialliance.org/lifecycle#" --namespacePrefix "ddi" --overwrite

echo "Build LinkML"
pushd "$OUTPUT_DIR/linkml" >/dev/null
gen-owl --metadata-profile rdfs -f ttl linkml.yml > "../owl/ddi4.owl.ttl"
gen-shacl linkml.yml > "../owl/ddi4.shacl"
gen-shex linkml.yml > "../owl/ddi4.shex"
popd >/dev/null

# cogs publish-dot . --location "$OUTPUT_DIR/dot" "$GRAPHVIZ_DOT" --overwrite --single
# cogs publish-dot . --location "$OUTPUT_DIR/dot" "$GRAPHVIZ_DOT" --overwrite --all --inheritance

echo "Sphinx"
cogs publish-sphinx . "$OUTPUT_DIR/sphinx" --location "$GRAPHVIZ_DOT" --overwrite

echo "C#"
cogs publish-cs . "$OUTPUT_DIR/csharp" --overwrite

echo "Build Sphinx"
pushd "$OUTPUT_DIR/sphinx" >/dev/null
make dirhtml
popd >/dev/null
