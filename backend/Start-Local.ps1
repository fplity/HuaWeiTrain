param([switch]$PrepareOnly)

$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$local = Join-Path $PSScriptRoot '.local'
$cert = Join-Path $local 'echo-dev-ca.pem'
$store = Join-Path $local 'echo-local.p12'
$keytool = Get-Command keytool -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $keytool -and $env:JAVA_HOME) {
    $keytool = Join-Path $env:JAVA_HOME 'bin/keytool.exe'
}
if (-not $keytool -or -not (Test-Path -LiteralPath $keytool)) {
    throw 'Install a JDK and set JAVA_HOME or add its bin directory to PATH.'
}

$null = New-Item -ItemType Directory -Force -Path $local
$savedPassword = Join-Path $local 'keystore-pass.dpapi'
if (-not $env:ECHO_KEYSTORE_PASSWORD) {
    if (Test-Path -LiteralPath $savedPassword) {
        $secret = Get-Content -LiteralPath $savedPassword | ConvertTo-SecureString
    } elseif (Test-Path -LiteralPath $store) {
        $secret = Read-Host 'Existing local TLS keystore password' -AsSecureString
    } else {
        $random = [Security.Cryptography.RandomNumberGenerator]::Create()
        try {
            $bytes = New-Object byte[] 24
            $random.GetBytes($bytes)
            $secret = ConvertTo-SecureString ([Convert]::ToBase64String($bytes)) -AsPlainText -Force
        } finally {
            $random.Dispose()
        }
        $secret | ConvertFrom-SecureString | Set-Content -LiteralPath $savedPassword
    }
    $env:ECHO_KEYSTORE_PASSWORD = [Net.NetworkCredential]::new('', $secret).Password
}
if (-not (Test-Path -LiteralPath $store)) {
    & $keytool -genkeypair -alias echo-local -keyalg RSA -keysize 2048 -validity 365 -storetype PKCS12 `
        -dname 'CN=Echo Local Development' -ext 'BC=ca:true' -ext 'KU=digitalSignature,keyEncipherment,keyCertSign' `
        -ext 'EKU=serverAuth' -ext 'SAN=ip:127.0.0.1,dns:localhost' -keystore $store -storepass:env ECHO_KEYSTORE_PASSWORD
    if ($LASTEXITCODE) { throw 'Could not generate the local TLS certificate.' }
}
& $keytool -exportcert -rfc -alias echo-local -keystore $store -storepass:env ECHO_KEYSTORE_PASSWORD -file $cert
if ($LASTEXITCODE) { throw 'Could not export the public local TLS certificate.' }
foreach ($product in 'phone','tablet') {
    $rawfile = Join-Path $project "products/$product/src/main/resources/rawfile"
    $null = New-Item -ItemType Directory -Force -Path $rawfile
    Copy-Item -LiteralPath $cert -Destination (Join-Path $rawfile 'echo-dev-ca.pem') -Force
}
if ($PrepareOnly) { return }

if (-not $env:ECHO_LISTENER_PASSWORD) {
    $secret = Read-Host 'Listener account password' -AsSecureString
    $env:ECHO_LISTENER_PASSWORD = [Net.NetworkCredential]::new('', $secret).Password
}
if (-not $env:ECHO_OPERATOR_PASSWORD) {
    $secret = Read-Host 'Operator account password' -AsSecureString
    $env:ECHO_OPERATOR_PASSWORD = [Net.NetworkCredential]::new('', $secret).Password
}
Push-Location -LiteralPath $PSScriptRoot
try {
    $jar = Join-Path $PSScriptRoot 'target/echo-backend-1.0.0.jar'
    if (-not (Test-Path -LiteralPath $jar)) {
        & mvn -B -ntp package
        if ($LASTEXITCODE) { throw 'Could not build the Java service.' }
    }
    & java -jar $jar
    if ($LASTEXITCODE) { throw 'The Java service stopped with an error.' }
} finally {
    Pop-Location
}