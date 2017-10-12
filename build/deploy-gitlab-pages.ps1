# Copy the artifact zip to the sphinx _static directory
copy ddi.zip ddi\sphinx\build\dirhtml\_static\


# For now, we will publish this on github pages.
# We should move to a regular http host, as the content of checkin-add-commit will get very large
#   We will simply scp the new directory and the updated builds.json


# Push the dirhtml subdirectory to Gitlab Pages
PUSHD ddi\sphinx\build

Write-Output "Cloning the DDI docs"

git config --global credential.helper store
Add-Content "$env:USERPROFILE\.git-credentials" "https://$($env:access_token):x-oauth-basic@github.com`n"
git config --global user.name "ddibot"
git config --global user.email "ddibot@colectica.com"

git clone https://github.com/ddialliance/ddimodel-web.git

Write-Output "Copying new html docs"

PUSHD ddimodel-web
Copy-Item ..\dirhtml\ $env:APPVEYOR_REPO_COMMIT -Force -Recurse


$web_client = new-object system.net.webclient
$commit_info = Invoke-RestMethod -Uri "https://api.github.com/repos/$env:APPVEYOR_REPO_NAME/commits/$env:APPVEYOR_REPO_COMMIT"

$committer =  $commit_info.committer | ConvertTo-Json -Depth 10

$newBuild =@"
    {
    "APPVEYOR_BUILD_ID":"$env:APPVEYOR_BUILD_ID",
    "APPVEYOR_REPO_BRANCH":"$env:APPVEYOR_REPO_BRANCH",
    "APPVEYOR_REPO_NAME":"$env:APPVEYOR_REPO_NAME",
    "APPVEYOR_REPO_TAG_NAME":"$env:APPVEYOR_REPO_TAG_NAME",
    "APPVEYOR_REPO_COMMIT":"$env:APPVEYOR_REPO_COMMIT",
    "APPVEYOR_REPO_COMMIT_AUTHOR":"$env:APPVEYOR_REPO_COMMIT_AUTHOR",
    "APPVEYOR_REPO_COMMIT_TIMESTAMP":"$env:APPVEYOR_REPO_COMMIT_TIMESTAMP",
    "APPVEYOR_REPO_COMMIT_MESSAGE":"$env:APPVEYOR_REPO_COMMIT_MESSAGE",
    "APPVEYOR_REPO_COMMIT_MESSAGE_EXTENDED":"$env:APPVEYOR_REPO_COMMIT_MESSAGE_EXTENDED",
    "APPVEYOR_REPO_TAG":"$env:APPVEYOR_REPO_TAG",
    "APPVEYOR_PULL_REQUEST_NUMBER":"$env:APPVEYOR_PULL_REQUEST_NUMBER",
    "APPVEYOR_PULL_REQUEST_TITLE":"$env:APPVEYOR_PULL_REQUEST_TITLE",
    "APPVEYOR_PULL_REQUEST_HEAD_REPO_NAME":"$env:APPVEYOR_PULL_REQUEST_HEAD_REPO_NAME",
    "APPVEYOR_PULL_REQUEST_HEAD_REPO_BRANCH":"$env:APPVEYOR_PULL_REQUEST_HEAD_REPO_BRANCH",
    "APPVEYOR_PULL_REQUEST_HEAD_COMMIT":"$env:APPVEYOR_PULL_REQUEST_HEAD_COMMIT",
    "github_commit_info" : $committer
    }
"@

Write-Output $newBuild

if (!(Test-Path 'builds.json')) 
{
    $buildsjson = @{ builds = @($newBuild | ConvertFrom-Json)}
} 
else 
{ 
    $buildsjson = Get-Content 'builds.json' -raw | ConvertFrom-Json

    $buildsjson.builds += (ConvertFrom-Json -InputObject $newBuild)
    $builds = $buildsjson.builds
    $buildsjson.builds = $builds | Sort-Object APPVEYOR_BUILD_ID -Descending
}

$buildsjson | ConvertTo-Json -Depth 10 | set-content 'builds.json'

git add .
git commit -m 'docs'
git push -u origin master

POPD
POPD

