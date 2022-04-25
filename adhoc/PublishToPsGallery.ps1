$folder = "X:\!WORK\GitHub\SQLPlayer\azure.datafactory.tools\"
$fileName = Join-Path -Path $folder -ChildPath "azure.datafactory.tools.psd1"
$fileName = Join-Path -Path Get-Location -ChildPath "azure.datafactory.tools.psd1"

$Parms = @{
    Path = "$fileName"
    Prerelease = 'preview'
  }
  
Update-ModuleManifest  @Parms 
Get-Content -Path $fileName | Out-Host
