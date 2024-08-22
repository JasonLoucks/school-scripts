$answer = Read-Host "Do you want to run the script? (y/n)"

if ( $answer -eq "y" -or $answer -eq "Y" )
{
    Write-Host "Running script..."
    
    $msg = $args[ 0 ]

    Write-Host $msg

    Write-Host -NoNewLine 'Press any key to continue...';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    $driveLetter = [System.IO.Path]::GetPathRoot( $PSScriptRoot ).TrimEnd('\')
    Write-Host "Drive letter is:"
    Write-Host $driveLetter
    Write-Host "PSScriptRoot is:"
    Write-Host $PSScriptRoot
}
else
{
    Write-Host "Exiting script."
}