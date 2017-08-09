[CmdletBinding()]

###################################################################################################

#
# PowerShell configurations
#

# NOTE: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.
#       This is necessary to ensure we capture errors inside the try-catch-finally block.
$ErrorActionPreference = "Stop"

# Ensure we set the working directory to that of the script.
pushd $PSScriptRoot

# Configure strict debugging.
Set-PSDebug -Strict

###################################################################################################

#
# Functions used in this script.
#

function Handle-LastError
{
    [CmdletBinding()]
    param(
    )

    $message = $error[0].Exception.Message
    if ($message)
    {
        Write-Host -Object "ERROR: $message" -ForegroundColor Red
    }
    
    # IMPORTANT NOTE: Throwing a terminating error (using $ErrorActionPreference = "Stop") still
    # returns exit code zero from the PowerShell script when using -File. The workaround is to
    # NOT use -File when calling this script and leverage the try-catch-finally block and return
    # a non-zero exit code from the catch block.
    exit -1
}

###################################################################################################

#
# Handle all errors in this script.
#

trap
{
    # NOTE: This trap will handle all errors. There should be no need to use a catch below in this
    #       script, unless you want to ignore a specific error.
    Handle-LastError
}

###################################################################################################

#
# Main execution block.
#

try
{
    $downloadUrl="http://ReplaceWithSQLServerDownloadPath"
    (Get-Date).DateTime
    $url = "$($downloadUrl)/SQLServer2016-x64-ENU.exe"
    $urlBox = "$($downloadUrl)/SQLServer2016-x64-ENU.box"
    $silentArgs = "/IACCEPTSQLSERVERLICENSETERMS /Q /ACTION=install /INSTANCENAME=MSSQLSERVER /UPDATEENABLED=FALSE /FEATURES=SQLEngine /SQLSYSADMINACCOUNTS=`"BUILTIN\Administrators`""
    $tempDir = Join-Path (Get-Item $env:TEMP).FullName "sql2016Installer"
    if ((Test-Path $tempDir) -eq $false) { New-Item -ItemType Directory -Path $tempDir}
    $fileFullPath = "$tempDir\SQLServer.exe"
    $fileFullPathBox = "$tempDir\SQLServer.box"
    (new-object net.webclient).DownloadFile($url , $fileFullPath)
    (new-object net.webclient).DownloadFile($urlBox , $fileFullPathBox)
    (Get-Date).DateTime
    $extractPath = "$env:SystemDrive\SQLInstaller"
    Write-Host "Extracting from $fileFullPath to $extractPath  ..."
    Start-Process  "$fileFullPath" "/Q /x:`"$extractPath`"" -Wait -Verb runAs
    (Get-Date).DateTime
    Write-Host "Installing SQL Server..."
    $setupPath = "$extractPath\setup.exe"
    Start-Process $setupPath "$silentArgs" -Wait -Verb runAs
    (Get-Date).DateTime
    Write-Host "Installation completed"
}
finally
{
    popd
}