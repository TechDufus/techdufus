function Get-PSGalleryDownloads() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.String[]] $PackageName
    )
    begin {

    }
    Process {
        try {
            $TotalDownloads = 0
            $ReturnObject = @{
                Total = $TotalDownloads
            }
            $PackageName | ForEach-Object {
                $PackageDownloads = $null
                Write-Verbose "PackageName: $_"
                $URL = "https://img.shields.io/powershellgallery/dt/$_.json"
                Write-Verbose $URL
                $PackageDownloads = (((Invoke-WebRequest $Url) | ConvertFrom-JSON).Value)
                Write-Verbose "$_ downloads: $PackageDownloads"
                switch($PackageDownloads) {
                    { $_ -match 'k' } {
                        $PackageDownloadsInt = [math]::Round([float]$PackageDownloads.Split('k')[0] * 1000)
                        $TotalDownloads = $TotalDownloads + $PackageDownloadsInt
                    } { $_ -match 'm' } {
                        $PackageDownloadsInt = [math]::Round([float]$PackageDownloads.Split('k')[0] * 1000000)
                        $TotalDownloads = $TotalDownloads + $PackageDownloadsInt
                    } DEFAULT {
                        $TotalDownloads = $TotalDownloads + $PackageDownloads
                    }
                }

                Write-Verbose "CurrentTotal: $TotalDownloads"
                $ReturnObject["$_"] = $PackageDownloads
            }
            $ReturnObject['Total'] = $TotalDownloads
            $ReturnObject
        }
        catch {
        }
    }
    end {}
}

function Get-CurrentProfileDownloadsValue() {
    (((Invoke-WebRequest "https://raw.githubusercontent.com/matthewjdegarmo/matthewjdegarmo/master/README.md").Content | Select-String -pattern "-~(\d+|\d{1,3}(,\d{3})*)(\.\d+)?-").matches.value -replace '-') -replace '~'
}

$PSGalleryDownloads = (Get-PSGalleryDownloads -PackageName 'HelpDesk', 'AdminToolkit', 'PSChipotle', 'PSChickfilA','PSIISHelper').Total
$ProfileDownloads = Get-CurrentProfileDownloadsValue
Write-Output "Current PSGallery Downloads : $PSGalleryDownloads"
Write-Output "Current Profile Downloads   : $ProfileDownloads"


if ($PSGalleryDownloads -gt $ProfileDownloads) {
    ## NEED TO UPDATE LINK IN README
    Write-Output "Updating Git Profile README.ME badge."
    $FormatedDownloadsNum = [String]::Format('{0:N0}', $PSGalleryDownloads)
    $Readme_path = [System.IO.Path]::Combine($GITHUB_WORKSPACE, 'Readme.md')
    $OriginalREADME_CONTENT = Get-Content $Readme_path
    $NewREADME_CONTENT = $OriginalREADME_CONTENT -replace '-~(\d+|\d{1,3}(,\d{3})*)(\.\d+)?-', "-~$FormatedDownloadsNum`-"
    Set-Content -Path $Readme_path -Value $NewREADME_CONTENT
    git config --local user.name 'Matthew J. DeGarmo'
    git config --local user.email 'matthewjdegarmo@gmail.com'
    git commit -m "🎉 Updating PSGallery Downloads badge from $ProfileDownloads to $FormatedDownloadsNum" -a
    try {
        git push --quiet
    }
    catch {}
}
