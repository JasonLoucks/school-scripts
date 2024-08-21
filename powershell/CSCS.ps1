# Change School Computer Settings - modified 20240821
#
# Currently:
# - taskbar
#   - hides search, task view, widgets, and chat
#   - aligns taskbar left
# - explorer
#   - shows file extensions and hidden files
#   - restarts explorer to save changes
# - mouse
#   - sets sensitivity to 8/20
#   - disables mouse acceleration
# - volume
#   - mutes volume
# - adds apps to registry
#   - so SetUserFTA in the .bat can make them default
# - opens folder to flash drive
# - adds firefox to registry so SetUserFTA can set as default pdf reader
# - turns on numlock
# - is signed
#   - now automatically signs in the .bat using signer.ps1 with comments removed and semicolons as newlines
#   - should be good, but just in case, https://adamtheautomator.com/how-to-sign-powershell-script/
#
# To do:
# - set firefox portable as default browser
# - add stuff to context menus (open with etc.)
# - add stuff to taskbar: firefox, n++, texstudio

# 29-35: taskbar stuff - hide search, task view, widgets, and chat; align taskbar left
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Search            -Name SearchBoxTaskbarMode -Value 0 -Type DWord -Force # hide search
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowTaskViewButton   -Value 0 -Type DWord -Force # hide task view
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarDa            -Value 0 -Type DWord -Force # hide widgets
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarMn            -Value 0 -Type DWord -Force # hide chat
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarAl            -Value 0 -Type DWord -Force # align taskbar left
# end taskbar stuff

# 37-40: explorer stuff - show file ext and hidden files
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0 -Type DWord -Force # show file extensions
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name Hidden      -Value 1 -Type DWord -Force # show hidden files
# end explorer stuff

# 42-86: mouse stuff - lower sens, turn off accel
# first, update registry w/ mouse settings
Set-ItemProperty -Path 'HKCU:\Control Panel\Mouse' -Name MouseSensitivity -Value $sens    -Type String -Force
Set-ItemProperty -Path 'HKCU:\Control Panel\Mouse' -Name MouseSpeed       -Value $speed   -Type String -Force
Set-ItemProperty -Path 'HKCU:\Control Panel\Mouse' -Name MouseThreshold1  -Value $thresh1 -Type String -Force
Set-ItemProperty -Path 'HKCU:\Control Panel\Mouse' -Name MouseThreshold2  -Value $thresh2 -Type String -Force

# now tell the system to enact the settings
# code stolen/modified from:
# - https://www.reddit.com/r/gaming/comments/qs0387/i_created_a_powershell_script_to_enabledisable/
# - https://renenyffenegger.ch/notes/Windows/PowerShell/examples/WinAPI/modify-mouse-speed

# mouse variables - ref: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfoa
$setSens  = 0x0071         # uiAction for sens
$setAccel = 0x0004         # uiAction for accel

$sens     = 6              # sensitivity value 0-20

$speed    = 0              #
$thresh1  = 0              # speed, thresh1, thresh2 = 0 to turn accel off
$thresh2  = 0              #
$accel    = @( $speed,
               $thresh1,
               $thresh2  ) # array for accel

Add-Type -name user32 -namespace tq84 -passThru -memberDefinition '
    [DllImport("user32.dll")]
    public static extern bool SystemParametersInfo( uint uiAction,
                                                    uint uiParam ,
                                                    uint pvParam ,
                                                    uint fWinIni   );
'

# why does this one have EntryPoint?
Add-Type -name Win32 -NameSpace System '
    [DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
    public static extern bool SystemParametersInfo( uint  uiAction,
                                                    uint  uiParam ,
                                                    int[] pvParam ,
                                                    uint  fWinIni   );
'

[tq84.user32]::SystemParametersInfo( $setSens, 0, $sens, 0 )    # why doesn't [System.Win32] work here?
[System.Win32]::SystemParametersInfo( $setAccel, 0, $accel, 2 ) # what do [System.Win32] and [tq84.user32] even mean?
# end mouse stuff

# 88-160: volume stuff - mute volume
# C# code stolen/modified from:
# - https://stackoverflow.com/questions/21355891/change-audio-level-from-powershell
# - https://stackoverflow.com/questions/255419/how-can-i-mute-unmute-my-sound-from-powershell
Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
[ Guid( "5CDF2C82-841E-4546-9722-0CF74078229A" ), InterfaceType( ComInterfaceType.InterfaceIsIUnknown ) ]
interface IAudioEndpointVolume
{
    // f(), g(), ... are unused COM method slots. Define these if you care
    int f(); int g(); int h(); int i();
    int SetMasterVolumeLevelScalar( float fLevel, System.Guid pguidEventContext );
    int j();
    int GetMasterVolumeLevelScalar( out float pfLevel );
    int k(); int l(); int m(); int n();
    int SetMute( [ MarshalAs( UnmanagedType.Bool ) ] bool bMute, System.Guid pguidEventContext );
    int GetMute( out bool pbMute );
}
[ Guid( "D666063F-1587-4E43-81F1-B948E807363F" ), InterfaceType( ComInterfaceType.InterfaceIsIUnknown ) ]
interface IMMDevice
{
    int Activate( ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev );
}
[ Guid( "A95664D2-9614-4F35-A746-DE8DB63617E6" ), InterfaceType( ComInterfaceType.InterfaceIsIUnknown ) ]
interface IMMDeviceEnumerator
{
    int f(); // Unused
    int GetDefaultAudioEndpoint( int dataFlow, int role, out IMMDevice endpoint );
}
[ ComImport, Guid( "BCDE0395-E52F-467C-8E3D-C4579291692E" ) ] class MMDeviceEnumeratorComObject { }
public class Audio
{
    static IAudioEndpointVolume Vol()
    {
        var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
        IMMDevice dev = null;
        Marshal.ThrowExceptionForHR( enumerator.GetDefaultAudioEndpoint( /*eRender*/ 0, /*eMultimedia*/ 1, out dev ) );
        IAudioEndpointVolume epv = null;
        var epvid = typeof( IAudioEndpointVolume ).GUID;
        Marshal.ThrowExceptionForHR( dev.Activate( ref epvid, /*CLSCTX_ALL*/ 23, 0, out epv ) );
        return epv;
    }
    public static float Volume
    {
        get
        {
            float v = -1;
            Marshal.ThrowExceptionForHR( Vol().GetMasterVolumeLevelScalar( out v ) );
            return v;
        }
        set
        {
            Marshal.ThrowExceptionForHR( Vol().SetMasterVolumeLevelScalar( value, System.Guid.Empty ) );
        }
    }
    public static bool Mute
    {
        get 
        {
            bool mute;
            Marshal.ThrowExceptionForHR( Vol().GetMute( out mute ) );
            return mute;
        }
        set
        {
            Marshal.ThrowExceptionForHR( Vol().SetMute( value, System.Guid.Empty ) );
        }
    }
}
'@

[ audio ]::Mute = $true
# end volume stuff

# 162-196: add apps to registry for use with SetUserFTA
# - currently only firefox portable
# - TODO: add n++ and powershell to registry

#$programs = "powershell_ise.exe",
#            "FirefoxPortable",
#            "Notepad++Portable"
#$keyPath = ,"HKCU:\Software\Classes\Applications\powershell_ise.exe\shell\open\command" # blank array
#$keyName = "(Default")
#$keyValue = ,"`"C:\Windows\System32\WindowsPowerShell\v1.0\powershell_ise.exe`" `"%1`""
#            
#foreach ( $program in $programs )
#{
#    $keyPath += "HKCU:\Software\Classes\Applications\$program.exe\shell\open\command"
#    $keyValue = "`"$PSScriptRoot\PortableApps\$program\$program.exe`" `"%1`"".replace('\\','\')
#}
#
#$keyValue = "`"$PSScriptRoot\PortableApps\FirefoxPortable\FirefoxPortable.exe`" `"%1`"".replace('\\','\')
#
#If ( !( Test-Path -path $keyPath ) )
#{
#    New-Item -Path $keyPath -Force | Out-Null
#}

$keyPath = "HKCU:\Software\Classes\Applications\FirefoxPortable.exe\shell\open\command"
$keyName = "(Default)"
$keyValue = "`"$PSScriptRoot\..\..\PortableApps\FirefoxPortable\FirefoxPortable.exe`" `"%1`"".replace('\\','\')

If ( !( Test-Path -path $keyPath ) )
{
    New-Item -Path $keyPath -Force | Out-Null
}

Set-ItemProperty -Path HKCU:\Software\Classes\Applications\FirefoxPortable.exe\shell\open\command -name $keyName -Value $keyValue -Force
# end registry stuff

# 198-202: numlock stuff
# just clicks numlock to turn it on
$wsh = New-Object -ComObject WScript.Shell
$wsh.SendKeys('{NUMLOCK}')
# end numlock stuff

# 204-207: misc stuff
Stop-Process -name explorer –force # need to restart explorer for explorer settings to take effect. everything else seems to work
Invoke-Item $PSScriptRoot\..\.. # open flash drive folder
# end misc stuff

# SIG # Begin signature block
# MIIbkQYJKoZIhvcNAQcCoIIbgjCCG34CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUpRJNJc+MSf0EFOV6jqdBTkvb
# cwOgghYLMIIC/jCCAeagAwIBAgIQG8y5OuckdbdA0KUQXWWvKzANBgkqhkiG9w0B
# AQsFADAXMRUwEwYDVQQDDAxKYXNvbiBMb3Vja3MwHhcNMjQwMzI2MjIwMzE4WhcN
# MjUwMzI2MjIyMzE4WjAXMRUwEwYDVQQDDAxKYXNvbiBMb3Vja3MwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQCmDKMmS/EO5h8VfACS8D9/tGCDLvTvRGJk
# AhTkyIrgICIB0+6LUvEwjj0Empa2zgN4eBJOR29CLdo1t7SrCkAOhfIftpLOs4vP
# 0EgL9aZ/MIHiO3vCKVjrRPUIKGrZ9a7ZGVtSwopuwdww21g6PDsixs+uLxifMQCh
# AiNbfhva6t1Y5fx8+qoYp9cixFM7Jy46J3hj48U2GkTMQVO2020Wk7cVzcLYIwOY
# 3fYZ6YAJq2T80r3+oq3+JT2/8RWCTtJSZjfylktphtkY1yZi3B7fkxTFd05JeqZN
# eZVIMgz0zd4RvriyKrNiVS4YJeoMQ+WGF/RgiyxxzIyRJd0AEvhxAgMBAAGjRjBE
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU
# LOWnz2ANMQo0Z8AcYbYNrKHJiGQwDQYJKoZIhvcNAQELBQADggEBABYx5v10TQ2f
# aSOjmyPG9isgpUenhmk/DCQruSA8WZnbdTN1SwMCTfYV9zBWdG/o2QZzPGFnt5MS
# +y/8JrmIxRrEZk0wSwIbDpBqfSSQUoKqETMT/s+TzbB7RKdMMzmUDY56ZQyX8Ijm
# bNheXf8Qg1+lMFTljMuPjyBmjTXSc0UkQr4HVl8gBITdmv9PWUzNmJ8zHoBcQCu3
# i/WTa8BQEUJ9cPfBMagjLOv6A4zZNB0O1xQVNtG0xiQlFQO5afaKaFnYZXKFPFZc
# D2o403IpjYmIops9YHpYb86cTHAvkB6VBvcThOGckTr+o47yYIH+YX1nUqpFlj8Z
# Kgwt/KNxcMYwggWNMIIEdaADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3
# DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAX
# BgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3Vy
# ZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBH
# NDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIw
# aTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLK
# EdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4Tm
# dDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembu
# d8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnD
# eMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1
# XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVld
# QnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTS
# YW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSm
# M9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzT
# QRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6Kx
# fgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/
# MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv
# 9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBr
# MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUH
# MAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYG
# BFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72a
# rKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFID
# yE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/o
# Wajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv
# 76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30
# fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQwggauMIIE
# lqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNV
# BAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdp
# Y2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0y
# MjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcwFQYD
# VQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBH
# NCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXHJQPE8pE3qZdRodbSg9GeTKJt
# oLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMfUBMLJnOWbfhXqAJ9/UO0hNoR
# 8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w1lbU5ygt69OxtXXnHwZljZQp
# 09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRktFLydkf3YYMZ3V+0VAshaG43
# IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYbqMFkdECnwHLFuk4fsbVYTXn+
# 149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUmcJgmf6AaRyBD40NjgHt1bicl
# kJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP65x9abJTyUpURK1h0QCirc0PO
# 30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzKQtwYSH8UNM/STKvvmz3+Drhk
# Kvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo80VgvCONWPfcYd6T/jnA+bIw
# pUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjBJgj5FBASA31fI7tk42PgpuE+
# 9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXcheMBK9Rp6103a50g5rmQzSM7TN
# sQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUuhbZ
# bU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4c
# D08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcGCCsGAQUF
# BwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEG
# CCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNVHSAEGTAX
# MAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBAH1ZjsCT
# tm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd4ksp+3CKDaopafxpwc8dB+k+
# YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiCqBa9qVbPFXONASIlzpVpP0d3
# +3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl/Yy8ZCaHbJK9nXzQcAp876i8
# dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeCRK6ZJxurJB4mwbfeKuv2nrF5
# mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYTgAnEtp/Nh4cku0+jSbl3ZpHx
# cpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/a6fxZsNBzU+2QJshIUDQtxMk
# zdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37xJV77QpfMzmHQXh6OOmc4d0j
# /R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmLNriT1ObyF5lZynDwN7+YAN8g
# Fk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0YgkPCr2B2RP+v6TR81fZvAT6
# gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJRyvmfxqkhQ/8mJb2VVQrH4D6
# wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIGwjCCBKqgAwIBAgIQBUSv85Sd
# CDmmv9s/X+VhFjANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJVUzEXMBUGA1UE
# ChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQg
# UlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMB4XDTIzMDcxNDAwMDAwMFoX
# DTM0MTAxMzIzNTk1OVowSDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0
# LCBJbmMuMSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMzCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBAKNTRYcdg45brD5UsyPgz5/X5dLnXaEO
# CdwvSKOXejsqnGfcYhVYwamTEafNqrJq3RApih5iY2nTWJw1cb86l+uUUI8cIOrH
# mjsvlmbjaedp/lvD1isgHMGXlLSlUIHyz8sHpjBoyoNC2vx/CSSUpIIa2mq62DvK
# Xd4ZGIX7ReoNYWyd/nFexAaaPPDFLnkPG2ZS48jWPl/aQ9OE9dDH9kgtXkV1lnX+
# 3RChG4PBuOZSlbVH13gpOWvgeFmX40QrStWVzu8IF+qCZE3/I+PKhu60pCFkcOvV
# 5aDaY7Mu6QXuqvYk9R28mxyyt1/f8O52fTGZZUdVnUokL6wrl76f5P17cz4y7lI0
# +9S769SgLDSb495uZBkHNwGRDxy1Uc2qTGaDiGhiu7xBG3gZbeTZD+BYQfvYsSzh
# Ua+0rRUGFOpiCBPTaR58ZE2dD9/O0V6MqqtQFcmzyrzXxDtoRKOlO0L9c33u3Qr/
# eTQQfqZcClhMAD6FaXXHg2TWdc2PEnZWpST618RrIbroHzSYLzrqawGw9/sqhux7
# UjipmAmhcbJsca8+uG+W1eEQE/5hRwqM/vC2x9XH3mwk8L9CgsqgcT2ckpMEtGlw
# Jw1Pt7U20clfCKRwo+wK8REuZODLIivK8SgTIUlRfgZm0zu++uuRONhRB8qUt+JQ
# ofM604qDy0B7AgMBAAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/
# BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAgBgNVHSAEGTAXMAgGBmeBDAEE
# AjALBglghkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZbU2FL3MpdpovdYxqII+eyG8w
# HQYDVR0OBBYEFKW27xPn783QZKHVVqllMaPe1eNJMFoGA1UdHwRTMFEwT6BNoEuG
# SWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQw
# OTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUFBwEBBIGDMIGAMCQG
# CCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wWAYIKwYBBQUHMAKG
# TGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJT
# QTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZIhvcNAQELBQADggIB
# AIEa1t6gqbWYF7xwjU+KPGic2CX/yyzkzepdIpLsjCICqbjPgKjZ5+PF7SaCinEv
# GN1Ott5s1+FgnCvt7T1IjrhrunxdvcJhN2hJd6PrkKoS1yeF844ektrCQDifXcig
# LiV4JZ0qBXqEKZi2V3mP2yZWK7Dzp703DNiYdk9WuVLCtp04qYHnbUFcjGnRuSvE
# xnvPnPp44pMadqJpddNQ5EQSviANnqlE0PjlSXcIWiHFtM+YlRpUurm8wWkZus8W
# 8oM3NG6wQSbd3lqXTzON1I13fXVFoaVYJmoDRd7ZULVQjK9WvUzF4UbFKNOt50MA
# cN7MmJ4ZiQPq1JE3701S88lgIcRWR+3aEUuMMsOI5ljitts++V+wQtaP4xeR0arA
# VeOGv6wnLEHQmjNKqDbUuXKWfpd5OEhfysLcPTLfddY2Z1qJ+Panx+VPNTwAvb6c
# Kmx5AdzaROY63jg7B145WPR8czFVoIARyxQMfq68/qTreWWqaNYiyjvrmoI1VygW
# y2nyMpqy0tg6uLFGhmu6F/3Ed2wVbK6rr3M66ElGt9V/zLY4wNjsHPW2obhDLN9O
# TH0eaHDAdwrUAuBcYLso/zjlUlrWrBciI0707NMX+1Br/wd3H3GXREHJuEbTbDJ8
# WC9nR2XlG3O2mflrLAZG70Ee8PBf4NvZrZCARK+AEEGKMYIE8DCCBOwCAQEwKzAX
# MRUwEwYDVQQDDAxKYXNvbiBMb3Vja3MCEBvMuTrnJHW3QNClEF1lryswCQYFKw4D
# AhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZI
# hvcNAQkEMRYEFC+Kjrbhl06NIb9EIerc1bY7Owe0MA0GCSqGSIb3DQEBAQUABIIB
# ADTNM3sW4WYMjv1h8thG5CIpul97B7Dd/yVsnfuS496GpRN2wiDXGDUuRCfgmAQi
# 5gjZnDxvMWJsdP7KX2ymCJn4oP8yD7gYEgigRpGDWvCQ2YaRnCFimqb4Qaf2enkn
# BEtQMQ/s+UUTuo5WJ6uNiFRbXzejJuyENfy4ZcHy3iP+XMjGCCw8q6DIwY96Yq4P
# +MYDckTfzwJjZwJMHWWXLHSG6eacW4pnTFIh+KrEufQz8SMeN6Ab/GIFW7nADZb3
# 3GEEK0GBgFIqZCcRilPbk4gsso0s3TXQZvIR3YBPbAAEvWQZEgI9JrRm4jNOqOZ/
# bBH45gPEfJyFkAlYle04k/6hggMgMIIDHAYJKoZIhvcNAQkGMYIDDTCCAwkCAQEw
# dzBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNV
# BAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1w
# aW5nIENBAhAFRK/zlJ0IOaa/2z9f5WEWMA0GCWCGSAFlAwQCAQUAoGkwGAYJKoZI
# hvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjQwMzI2MjIxMzIw
# WjAvBgkqhkiG9w0BCQQxIgQgnnmgkVRaPxs787J2n1X6oVnxFlsD5h+q2VGP6zN2
# uTkwDQYJKoZIhvcNAQEBBQAEggIAC9swwV5rWXjJ314Cb19A7S8xF1yFA+euPI8x
# 06cFp7dpeglJdYRYm5LwEbfDu5JkNa0kNaHXNPpuiy+/E54QpU4aXqmLcjB/5cM/
# 8w1zKsvXgXIdY2v85pilD507Lsy1KZAd+QXEiCKcBO+DwP2X/8BRHj20Wx03Fdrr
# DBvkWrZtPQNXg6kahX1nILHokwCMj4nc4O8cO9Hd2XRIZbbwtSgXNl8U19uiIdCc
# ZguTmzHyKzzeG7WkY9cKDBnCFn3GPhO5JYx6Vn7Qu1tZgaEZOyLgNzNiwQGdHrGO
# /oa6+JmtEFpxNlfZJSYEB+03QzngxLYGMZ3Y0lwCeRywR9s7hqxlBKXEtl1M3x24
# Cjl4sw/MlVAMTJrtYKkLuCz4zM9FuNgv3aqRmNNqg7nnvfEIDw2H1jnyPyMB+UrP
# OUxj2DTX8pJ69W0r18SY2SGF4XMRsn8T+k4Yee2o/QPIfMH+QZxlfkQZqowAY4jB
# 5T48+MKA2m83kcd2TqjSzVVWo0pkzpaJ2grf7DYWg7vTxeee9g1GOiWbpjkqaT79
# 0UOzEZKnY1sLC0knRaPE2MAKwNkFA9ftls1xsp74TIrqNu32v/ziq4ZUn/devbn6
# aZbVrmuTLNCJQ8eE7mhAQv3Z3UG2uX/d6ilzVMUUMPHTtLtihYaW9/Jt+kkhg6zO
# Q9zx/yk=
# SIG # End signature block
