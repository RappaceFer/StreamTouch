$ErrorActionPreference = 'Stop'
$project = $PSScriptRoot
$sdk = $env:ANDROID_HOME
if (-not $sdk) { $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
if (-not (Test-Path $sdk)) { throw 'SDK Android introuvable' }
$env:ANDROID_HOME = $sdk
Set-Content (Join-Path $project 'local.properties') '# SDK selected through ANDROID_HOME' -Encoding ascii
if (Test-Path 'C:\Program Files\Android\Android Studio\jbr') { $env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr' }
Push-Location $project
try { & .\gradlew.bat assembleNonRootDebug lintNonRootDebug --no-daemon --console=plain; exit $LASTEXITCODE } finally { Pop-Location }
