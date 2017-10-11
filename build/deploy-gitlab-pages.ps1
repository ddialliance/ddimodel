# Copy the artifact zip to the sphinx _static directory
copy ddi.zip ddi\sphinx\build\dirhtml\_static\

# Push the dirhtml subdirectory to Gitlab Pages
PUSHD ddi\sphinx\build

git config --global credential.helper store
Add-Content "$env:USERPROFILE\.git-credentials" "https://$($env:access_token):x-oauth-basic@github.com`n"
git config --global user.name "ddibot"
git config --global user.email "ddibot@ddialliance.org"

git clone https://github.com/ddialliance/ddimodel-web.git
PUSHD ddimodel-web
Copy-Item ..\dirhtml\* $env:APPVEYOR_REPO_COMMIT -Force -Recurse


if (!(Test-Path 'builds.json')) 
{
    Add-Content "builds.json" "{builds : []}`n"
}

$buildsjson = Get-Content 'builds.json' -raw | ConvertFrom-Json

$newBuild =@"
    {
    "APPVEYOR_BUILD_ID":"$env:APPVEYOR_BUILD_ID",
    "APPVEYOR_REPO_BRANCH":"$env:APPVEYOR_REPO_BRANCH",
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
    "APPVEYOR_PULL_REQUEST_HEAD_COMMIT":"$env:APPVEYOR_PULL_REQUEST_HEAD_COMMIT"
    }
"@

$buildsjson.builds += (ConvertFrom-Json -InputObject $newBuild)

$buildsjson | ConvertTo-Json  | set-content 'builds.json'


git add master
git commit -m 'docs'
git push -u origin master

POPD
POPD

