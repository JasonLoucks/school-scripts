$user = "Jason Loucks"
Get-ChildItem Cert:\CurrentUser\My               | Where-Object {$_.Subject -match $user} | Remove-Item
Get-ChildItem Cert:\CurrentUser\Root             | Where-Object {$_.Subject -match $user} | Remove-Item
Get-ChildItem Cert:\CurrentUser\TrustedPublisher | Where-Object {$_.Subject -match $user} | Remove-Item

# Generate a self-signed Authenticode certificate in the local computer's personal certificate store.
$authenticode = New-SelfSignedCertificate -Subject "Jason Loucks" -CertStoreLocation Cert:\CurrentUser\My -Type CodeSigningCert

# Add the self-signed Authenticode certificate to the computer's root certificate store.
## Create an object to represent the CurrentUser\Root certificate store.
$rootStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("Root","CurrentUser")
## Open the root certificate store for reading and writing.
$rootStore.Open("ReadWrite")
## Add the certificate stored in the $authenticode variable.
$rootStore.Add($authenticode)
## Close the root certificate store.
$rootStore.Close()
 
# Add the self-signed Authenticode certificate to the computer's trusted publishers certificate store.
## Create an object to represent the CurrentUser\TrustedPublisher certificate store.
$publisherStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("TrustedPublisher","CurrentUser")
## Open the TrustedPublisher certificate store for reading and writing.
$publisherStore.Open("ReadWrite")
## Add the certificate stored in the $authenticode variable.
$publisherStore.Add($authenticode)
## Close the TrustedPublisher certificate store.
$publisherStore.Close()

# Confirm if the self-signed Authenticode certificate exists in the computer's Personal certificate store
Get-ChildItem Cert:\CurrentUser\My | Where-Object {$_.Subject -eq "CN=$user"}
# Confirm if the self-signed Authenticode certificate exists in the computer's Root certificate store
Get-ChildItem Cert:\CurrentUser\Root | Where-Object {$_.Subject -eq "CN=$user"}
# Confirm if the self-signed Authenticode certificate exists in the computer's Trusted Publishers certificate store
Get-ChildItem Cert:\CurrentUser\TrustedPublisher | Where-Object {$_.Subject -eq "CN=$user"}

# Get the code-signing certificate from the local computer's certificate store with the name $user and store it to the $codeCertificate variable.
$codeCertificate = Get-ChildItem Cert:\CurrentUser\My | Where-Object {$_.Subject -eq "CN=$user"}

# Sign the PowerShell script
# PARAMETERS:
# - FilePath - Specifies the file path of the PowerShell script to sign, eg. C:\ATA\myscript.ps1.
# - Certificate - Specifies the certificate to use when signing the script.
# - TimeStampServer - Specifies the trusted timestamp server that adds a timestamp to your script's digital signature. Adding a timestamp ensures that your code will not expire when the signing certificate expires.
Set-AuthenticodeSignature -FilePath E:\Win11.ps1 -Certificate $codeCertificate -TimeStampServer http://timestamp.digicert.com
