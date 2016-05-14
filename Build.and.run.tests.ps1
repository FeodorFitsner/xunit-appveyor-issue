Param(
    [string]$vs = '14'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-ColorOutput($message, [System.ConsoleColor]$ForegroundColor)
{
    if ($ForegroundColor) {
        # save the current color
        $fc = $host.UI.RawUI.ForegroundColor

        # set the new color
        $host.UI.RawUI.ForegroundColor = $ForegroundColor
    }

    # output
    if ($message) {
        Write-Output $message
    }
    else {
        $input | Write-Output
    }

    if ($ForegroundColor) {
        # restore the original color
        $host.UI.RawUI.ForegroundColor = $fc
    }
}

function Run-Command([scriptblock]$Command) {
    & $Command

    if ($LASTEXITCODE -ne 0) {
        Get-PSCallStack | Write-ColorOutput -ForegroundColor Red
        throw "An error occured..."
    }
}

function Restore-Packages($root, $slnPath) {
    $NugetSource = "https://nuget.org/nuget.exe"
    $nugetExe = Join-Path $root ".nuget/nuget.exe"

    If (-Not (Test-Path $nugetExe))
    {
        Write-ColorOutput -ForegroundColor "Green" "Downloading `"$NugetSource`"..."

	    $proxy = [System.Net.WebRequest]::GetSystemWebProxy()
	    $proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials

	    $webClient = New-Object System.Net.WebClient
	    $webClient.UseDefaultCredentials = $true ## Proxy credentials only
	    $webClient.Proxy.Credentials = $webClient.Credentials
	    $webClient.DownloadFile($NugetSource, $nugetExe)

        Write-ColorOutput "Done."
    }

    Write-ColorOutput -ForegroundColor "Green" "Restoring packages of `"$slnPath`"..."

    Run-Command { & "$nugetExe" restore $slnPath }
}

# From http://www.dougfinke.com/blog/index.php/2010/12/01/note-to-self-how-to-programmatically-get-the-msbuild-path-in-powershell/

Function Get-MSBuild {
    return "C:\Program Files (x86)\MSBuild\14.0\Bin\msbuild.exe"
}

function Build-Solution($slnPath) {

    Write-ColorOutput -ForegroundColor "Green" "Building solution..."

    Run-Command { & (Get-MSBuild) "$slnPath" /maxcpucount:3 /p:Configuration=Release /p:VisualStudioVersion=$vs.0 }
}

function Run-Tests($root, $binReleaseFolder) {
    $xUnitVersion = "2.1.0"

    Write-ColorOutput -ForegroundColor "Green" "Running tests..."

    $xUnitRunner = Join-Path $root "packages\xunit.runner.console.$xUnitVersion\tools\xunit.console.exe"
    $testAssemblyLocation = Join-Path $binReleaseFolder "Tests.dll"
    Run-Command { & "$xUnitRunner" "$testAssemblyLocation" -parallel all -diagnostics }
}

function Clean-OutputFolder($binReleaseFolder) {

    If (Test-Path $binReleaseFolder) {
        Write-ColorOutput -ForegroundColor "Green" "Removing `"$binReleaseFolder`" folder..."

        Remove-Item -Recurse -Force "$binReleaseFolder"

        Write-ColorOutput "Done."
    }
}

######################

$root = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

Clean-OutputFolder (Join-Path $root "Tests\bin")
Clean-OutputFolder (Join-Path $root "Tests\obj")

$slnPath = Join-Path $root "Tests.sln"

Restore-Packages $root $slnPath
Build-Solution $slnPath

Run-Tests $root (Join-Path $root "Tests\bin\Release")
