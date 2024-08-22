@echo off
:: remove certs without prompt https://superuser.com/questions/191038/installing-deleting-root-certificate-without-certmgr-certutil-asking-the-end-u

:: self-signing (following line) should be unnecessary? "-ExecutionPolicy Bypass" seems to work
:: Powershell "$user = 'Jason Loucks'; Get-ChildItem Cert:\CurrentUser\ -Recurse | Where-Object {$_.Subject -match $user} | Remove-Item; $authenticode = New-SelfSignedCertificate -Subject 'Jason Loucks' -CertStoreLocation Cert:\CurrentUser\My -Type CodeSigningCert; $rootStore = [System.Security.Cryptography.X509Certificates.X509Store]::new('Root','CurrentUser'); $rootStore.Open('ReadWrite'); $rootStore.Add($authenticode); $rootStore.Close(); $publisherStore = [System.Security.Cryptography.X509Certificates.X509Store]::new('TrustedPublisher','CurrentUser'); $publisherStore.Open('ReadWrite'); $publisherStore.Add($authenticode); $publisherStore.Close(); Get-ChildItem Cert:\CurrentUser\My | Where-Object {$_.Subject -eq 'CN=$user'}; Get-ChildItem Cert:\CurrentUser\Root | Where-Object {$_.Subject -eq 'CN=$user'}; Get-ChildItem Cert:\CurrentUser\TrustedPublisher | Where-Object {$_.Subject -eq 'CN=$user'}; $codeCertificate = Get-ChildItem Cert:\CurrentUser\My | Where-Object {$_.Subject -eq 'CN=Jason Loucks'}; Set-AuthenticodeSignature -FilePath Documents\Scripting\ChangeSchoolComputerSettings.ps1 -Certificate $codeCertificate -TimeStampServer http://timestamp.digicert.com"

set CSCS_ps1=..\powershell\test.ps1

set SUFTA=

Powershell %CSCS_ps1%
PortableApps\SetUserFTA\SetUserFTA PortableApps\SetUserFTA\config.txt
Start.exe