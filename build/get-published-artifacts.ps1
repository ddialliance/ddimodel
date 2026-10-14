[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('\A[a-z][a-z0-9_]*\z', Options = 'None')]
    [string]$Slug
)

# Shared inventory for the downloadable package and S3 publication.
$artifacts = @(
    @{ Directory = 'xsd'; Suffix = '.xsd'; ContentType = 'application/xml' }
    @{ Directory = 'xsd'; FileName = 'xml.xsd'; ContentType = 'application/xml' }
    @{ Directory = 'json'; Suffix = '.schema.json'; ContentType = 'application/json' }
    @{ Directory = 'json'; Suffix = '.meta-schema.json'; ContentType = 'application/json' }
    @{ Directory = 'rdf'; Suffix = '.ttl'; ContentType = 'text/turtle' }
    @{ Directory = 'rdf'; Suffix = '.ontology.jsonld'; ContentType = 'application/ld+json' }
    @{ Directory = 'rdf'; Suffix = '.context.jsonld'; ContentType = 'application/ld+json' }
    @{ Directory = 'rdf'; Suffix = '.shacl.ttl'; ContentType = 'text/turtle' }
    @{ Directory = 'rdf'; Suffix = '.shacl12.ttl'; ContentType = 'text/turtle' }
    @{ Directory = 'uml'; Suffix = '.xmi'; ContentType = 'application/xml' }
    @{ Directory = 'dctap'; Suffix = '.dctap.csv'; ContentType = 'text/csv' }
)
foreach ($artifact in $artifacts) {
    [pscustomobject]@{
        Directory = $artifact.Directory
        FileName = if ($artifact.ContainsKey('FileName')) {
            $artifact.FileName
        } else {
            $Slug + $artifact.Suffix
        }
        ContentType = $artifact.ContentType
    }
}
