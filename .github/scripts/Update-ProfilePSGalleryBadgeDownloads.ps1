function Get-PSGalleryDownloads() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [System.String[]] $PackageName
    )
    begin {
        $TotalDownloads = 0
        $ReturnObject = @{}
    }
    Process {
        try {
            $PackageName | ForEach-Object {
                Write-Verbose "PackageName: $_"
                $URL = "https://img.shields.io/powershellgallery/dt/$_.json"
                $PackageDownloads = ((Invoke-WebRequest $Url) | ConvertFrom-JSON).Value
                Write-Verbose "$_ downloads: $PackageDownloads"
                $TotalDownloads = $TotalDownloads + $PackageDownloads
                Write-Verbose "CurrentTotal: $TotalDownloads"
                $ReturnObject += @{$_ = $PackageDownloads}
            }
        } catch {
        }
    }
    end {
        $ReturnObject += @{Total = $TotalDownloads}
        [pscustomobject]$ReturnObject
    }
}

function Get-CurrentProfileDownloadsValue() {
    ((Invoke-WebRequest "https://raw.githubusercontent.com/matthewjdegarmo/matthewjdegarmo/master/README.md").Content | Select-String -pattern "-\d+-").matches.value -replace '-'
}

$PSGalleryDownloads = (Get-PSGalleryDownloads -PackageName 'HelpDesk','AdminToolkit').Total
$ProfileDownloads = Get-CurrentPRofileDownloadsValue
Write-Output "Current PSGallery Downloads : $PSGalleryDownloads"
Write-Output "Current Profile Downloads   : $ProfileDownloads"


if ($PSGalleryDownloads -gt $ProfileDownloads) {
  ## NEED TO UPDATE LINK IN README
  Write-Output "Updating Git Profile README.ME badge."
  $Readme_path = [System.IO.Path]::Combine($GITHUB_WORKSPACE,'Readme.md')
  $OriginalREADME_CONTENT = Get-Content $Readme_path
  $NewREADME_CONTENT = $OriginalREADME_CONTENT -replace '-\d+-',"-$PSGalleryDownloads`-"
  Set-Content -Path $Readme_path -Value $NewREADME_CONTENT
  git config --local user.email ${{ secrets.GH_EMAIL }}
  git config --local user.name $(( secrets.GH_USER }}
  git commit -m "Updating PSGallery Downloads badge from $ProfileDownloads to $PSGalleryDownloads" -a
  git push
  exit 0
}
