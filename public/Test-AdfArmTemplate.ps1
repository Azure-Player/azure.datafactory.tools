<#
.SYNOPSIS
Runs validation agains Data Factory code in ARMTemplate in terms of best practices from the field.

.DESCRIPTION
Runs validation agains Data Factory code in ARMTemplate in terms of best practices from the field.
Author: Paul Andrew

.PARAMETER ARMTemplateFilePath
Provide the location of your ARM template file

.EXAMPLE
Test-AdfArmTemplate -ARMTemplateFilePath "$File"

#>
function Test-AdfArmTemplate {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] 
        [String] $ARMTemplateFilePath
        ,[bool] $SummaryOutput = $true 
        ,[bool] $VerboseOutput = $false
    )

    Set-StrictMode -Version 1


#############################################################################################
if(-not (Test-Path -Path $ARMTemplateFilePath))
{
    Write-Error "ARM template file not found. Please check the path provided."
    return
}

$Hr = "-------------------------------------------------------------------------------------------------------------------"
Write-Host ""
Write-Host $Hr
Write-Host "Running checks for Data Factory ARM template:"
Write-Host ""
$ARMTemplateFilePath
Write-Host ""

#Parse template into ADF resource parts
$ADF = Get-Content $ARMTemplateFilePath | ConvertFrom-Json
$LinkedServices = $ADF.resources | Where-Object {$_.type -eq "Microsoft.DataFactory/factories/linkedServices"}
$Datasets = $ADF.resources | Where-Object {$_.type -eq "Microsoft.DataFactory/factories/datasets"}
$Pipelines = $ADF.resources | Where-Object {$_.type -eq "Microsoft.DataFactory/factories/pipelines"}
$Activities = $Pipelines.properties.activities #regardless of pipeline
$DataFlows = $ADF.resources | Where-Object {$_.type -eq "Microsoft.DataFactory/factories/dataflows"}
$Triggers = $ADF.resources | Where-Object {$_.type -eq "Microsoft.DataFactory/factories/triggers"}

#Output variables
$CheckNumber = 0
$CheckDetail = ""
$Severity = ""
$CheckCounter = 0
$SummaryTable = @()
$VerboseDetailTable = @()

#String helper functions
function CleanName {
    param (
        [parameter(Mandatory = $true)] [String] $RawValue
    )
    $CleanName = $RawValue.substring($RawValue.IndexOf("/")+1, $RawValue.LastIndexOf("'") - $RawValue.IndexOf("/")-1)
    return $CleanName
}

function CleanType {
    param (
        [parameter(Mandatory = $true)] [String] $RawValue
    )
    $CleanName = $RawValue.substring($RawValue.LastIndexOf("/")+1, $RawValue.Length - $RawValue.LastIndexOf("/")-1)
    return $CleanName
}

#############################################################################################
#Review resource dependants
#############################################################################################
$ResourcesList = New-Object System.Collections.ArrayList($null)
$DependantsList = New-Object System.Collections.ArrayList($null)

#Get resources
ForEach($Resource in $ADF.resources)
{
    $ResourceName = CleanName -RawValue $Resource.name
    $ResourceType = CleanType -RawValue $Resource.type
    $CompleteResource =   $ResourceType + "|" + $ResourceName
    
    if(-not ($ResourcesList -contains $CompleteResource))
    {
        [void]$ResourcesList.Add($CompleteResource)
    }
}

#Get dependants
ForEach($Resource in $ADF.resources)# | Where-Object {$_.type -ne "Microsoft.DataFactory/factories/triggers"})
{
    if($Resource.dependsOn.Count -eq 1)
    {
        $DependantName = CleanName -RawValue $Resource.dependsOn[0].ToString()
        $CompleteDependant = $DependantName.Replace('/','|')

        if(-not ($DependantsList -contains $CompleteDependant))
        {
            [void]$DependantsList.Add($CompleteDependant)
        }
    }
    else
    {
        ForEach($Dependant in $Resource.dependsOn)
        {
            $DependantName = CleanName -RawValue $Dependant
            $CompleteDependant = $DependantName.Replace('/','|')

            if(-not ($DependantsList -contains $CompleteDependant))
            {
                [void]$DependantsList.Add($CompleteDependant)
            }
        }
    }
}

#Get trigger dependants
ForEach($Resource in $Triggers)
{
    
    $ResourceName = CleanName -RawValue $Resource.name
    $ResourceType = CleanType -RawValue $Resource.type
    $CompleteResource =   $ResourceType + "|" + $ResourceName

    if($Resource.dependsOn.count -ge 1)
    {
        if(-not ($DependantsList -contains $CompleteResource))
        {
            [void]$DependantsList.Add($CompleteResource)
        }
    }
}

#Establish simple redundancy to use later
$RedundantResources = $ResourcesList | Where-Object {$DependantsList -notcontains $_}

#############################################################################################
#Check for pipeline without triggers
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Pipeline(s) without any triggers attached. Directly or indirectly."
Write-Host "Running check... " $CheckDetail
$Severity = "Medium"
ForEach($RedundantResource in $RedundantResources | Where-Object {$_ -like "pipelines*"})
{
    $Parts = $RedundantResource.Split('|')

    $CheckCounter += 1
    if($VerboseOutput)
    {  
        $VerboseDetailTable += [PSCustomObject]@{
            Component = "Pipeline";
            Name = $Parts[1];
            CheckDetail = "Does not any triggers attached.";
            Severity = $Severity
        }
    }
}
$SummaryTable += [PSCustomObject]@{
    IssueCount = $CheckCounter; 
    CheckDetail = $CheckDetail;
    Severity = $Severity
}
$CheckCounter = 0

#############################################################################################
#Check pipeline with an impossible execution chain.
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Pipeline(s) with an impossible AND/OR activity execution chain."
Write-Host "Running check... " $CheckDetail
$Severity = "High"
ForEach($Pipeline in $Pipelines)
{
    $PipelineName = (CleanName -RawValue $Pipeline.name.ToString())
    $ActivityFailureDependencies = New-Object System.Collections.ArrayList($null)
    $ActivitySuccessDependencies = New-Object System.Collections.ArrayList($null)

    #get upstream failure dependants
    ForEach($Activity in $Pipeline.properties.activities)
    {
        if($Activity.dependsOn.Count -gt 1)
        {
            ForEach($UpStreamActivity in $Activity.dependsOn)
            {
                if($UpStreamActivity.dependencyConditions.Contains('Failed'))
                {  
                    if(-not ($ActivityFailureDependencies -contains $UpStreamActivity.activity))
                    {
                        [void]$ActivityFailureDependencies.Add($UpStreamActivity.activity)
                    }
                }
            }
        }
    }

    #get downstream success dependants
    ForEach($ActivityDependant in $ActivityFailureDependencies)
    {
        ForEach($Activity in $Pipeline.properties.activities | Where-Object {$_.name -eq $ActivityDependant})
        {
            if($Activity.dependsOn.Count -ge 1)
            {
                ForEach($DownStreamActivity in $Activity.dependsOn)
                {
                    if($DownStreamActivity.dependencyConditions.Contains('Succeeded'))
                    {                  
                        if(-not ($ActivitySuccessDependencies -contains $DownStreamActivity.activity))
                        {
                            [void]$ActivitySuccessDependencies.Add($DownStreamActivity.activity)
                        }
                    }
                }
            }
        }
    }
    
    #compare dependants - do they exist in both lists?
    $Problems = $ActivityFailureDependencies | Where-Object {$ActivitySuccessDependencies -contains $_}
    if($Problems.Count -gt 0)
    {
        $CheckCounter += 1
        if($VerboseOutput)
        {  
            $VerboseDetailTable += [PSCustomObject]@{
                Component = "Pipeline";
                Name = $PipelineName;
                CheckDetail = "Has an impossible AND/OR activity execution chain.";
                Severity = $Severity
            }
        }
    }
}
$SummaryTable += [PSCustomObject]@{
    IssueCount = $CheckCounter; 
    CheckDetail = $CheckDetail;
    Severity = $Severity
}
$CheckCounter = 0

#############################################################################################
#Check for pipeline descriptions
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Pipeline(s) without a description value."
Write-Host "Running check... " $CheckDetail
$Severity = "Low"
ForEach ($Pipeline in $Pipelines)
{
    $PipelineName = (CleanName -RawValue $Pipeline.name.ToString())
    $PipelineDescription = $Pipeline.properties.description

    if(([string]::IsNullOrEmpty($PipelineDescription)))
    {
        $CheckCounter += 1
        if($VerboseOutput)
        {  
            $VerboseDetailTable += [PSCustomObject]@{
                Component = "Pipeline";
                Name = $PipelineName;
                CheckDetail = "Does not have a description.";
                Severity = $Severity
            }
        }
    }
}
$SummaryTable += [PSCustomObject]@{
        IssueCount = $CheckCounter; 
        CheckDetail = $CheckDetail;
        Severity = $Severity
    }
$CheckCounter = 0

#############################################################################################
#Check for pipelines not in folders
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Pipeline(s) not organised into folders."
Write-Host "Running check... " $CheckDetail
$Severity = "Low"
ForEach ($Pipeline in $Pipelines)
{
    $PipelineName = (CleanName -RawValue $Pipeline.name.ToString())
    $PipelineFolder = $Pipeline.properties.folder.name
    if(([string]::IsNullOrEmpty($PipelineFolder)))
    {
        $CheckCounter += 1
        if($VerboseOutput)
        {  
            $VerboseDetailTable += [PSCustomObject]@{
                Component = "Pipeline";
                Name = $PipelineName;
                CheckDetail = "Not organised into a folder.";
                Severity = $Severity
            }
        }
    }
}
$SummaryTable += [PSCustomObject]@{
        IssueCount = $CheckCounter; 
        CheckDetail = $CheckDetail;
        Severity = $Severity
    }
$CheckCounter = 0

#############################################################################################
#Check for pipelines without annotations
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Pipeline(s) without annotations."
Write-Host "Running check... " $CheckDetail
$Severity = "Low"
ForEach ($Pipeline in $Pipelines)
{
    $PipelineName = (CleanName -RawValue $Pipeline.name.ToString())
    $PipelineAnnotations = $Pipeline.properties.annotations.Count
    if($PipelineAnnotations -le 0)
    {
        $CheckCounter += 1
        if($VerboseOutput)
        {  
            $VerboseDetailTable += [PSCustomObject]@{
                Component = "Pipeline";
                Name = $PipelineName;
                CheckDetail = "Does not have any annotations.";
                Severity = $Severity
            }
        }
    }
}
$SummaryTable += [PSCustomObject]@{
        IssueCount = $CheckCounter; 
        CheckDetail = $CheckDetail;
        Severity = $Severity
    }
$CheckCounter = 0

#############################################################################################
#Check for data flow descriptions
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Data Flow(s) without a description value."
Write-Host "Running check... " $CheckDetail
$Severity = "Low"
ForEach ($DataFlow in $DataFlows)
{
    $DataFlowName = (CleanName -RawValue $DataFlow.name.ToString())
    $DataFlowDescription = $DataFlow.properties.description

    if(([string]::IsNullOrEmpty($DataFlowDescription)))
    {
        $CheckCounter += 1
        if($VerboseOutput)
        {  
            $VerboseDetailTable += [PSCustomObject]@{
                Component = "Data Flow";
                Name = $DataFlowName;
                CheckDetail = "Does not have a description.";
                Severity = $Severity
            }
        }
    }
}
$SummaryTable += [PSCustomObject]@{
        IssueCount = $CheckCounter; 
        CheckDetail = $CheckDetail;
        Severity = $Severity
    }
$CheckCounter = 0

#############################################################################################
#Check activity timeout values
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Activitie(s) with timeout values still set to the service default value of 7 days."
Write-Host "Running check... " $CheckDetail
$Severity = "High"
ForEach ($Activity in $Activities)
{
    $timeout = $Activity.policy.timeout
    if(-not ([string]::IsNullOrEmpty($timeout)))
    {        
        if($timeout -eq "7.00:00:00")
        {
            $CheckCounter += 1
            if($VerboseOutput)
            {            
                $VerboseDetailTable += [PSCustomObject]@{
                    Component = "Activity";
                    Name = $Activity.Name;
                    CheckDetail = "Timeout policy still set to the service default value of 7 days.";
                    Severity = $Severity
                }
            }
        }
    }
}
$SummaryTable += [PSCustomObject]@{
        IssueCount = $CheckCounter; 
        CheckDetail = $CheckDetail;
        Severity = $Severity
    }
$CheckCounter = 0

#############################################################################################
#Check activity descriptions
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Activitie(s) without a description value."
Write-Host "Running check... " $CheckDetail
$Severity = "Low"
ForEach ($Activity in $Activities)
{
    $ActivityDescription = $Activity.description
    if(([string]::IsNullOrEmpty($ActivityDescription)))
    {        
        $CheckCounter += 1
        if($VerboseOutput)
        {            
            $VerboseDetailTable += [PSCustomObject]@{
                Component = "Activity";
                Name = $Activity.Name;
                CheckDetail = "Does not have a description.";
                Severity = $Severity
            }
        }
    }
}
$SummaryTable += [PSCustomObject]@{
        IssueCount = $CheckCounter; 
        CheckDetail = $CheckDetail;
        Severity = $Severity
    }
$CheckCounter = 0

#############################################################################################
#Check foreach activity batch size unset
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Activitie(s) ForEach iteration without a batch count value set."
Write-Host "Running check... " $CheckDetail
$Severity = "High"
ForEach ($Activity in $Activities | Where-Object {$_.type -eq "ForEach"})
{    
    [bool]$isSequential = $false #attribute may only exist if changed, assume not present in arm template
    if((-not [string]::IsNullOrEmpty($Activity.typeProperties.isSequential)))
    {
        $isSequential = $Activity.typeProperties.isSequential
    }
    $BatchCount = $Activity.typeProperties.batchCount

    if(!$isSequential)
    {
        if(([string]::IsNullOrEmpty($BatchCount)))
        {        
            $CheckCounter += 1
            if($VerboseOutput)
            {            
                $VerboseDetailTable += [PSCustomObject]@{
                    Component = "Activity";
                    Name = $Activity.Name;
                    CheckDetail = "ForEach does not have a batch count value set.";
                    Severity = $Severity
                }
            }
        }
    }
}
$SummaryTable += [PSCustomObject]@{
        IssueCount = $CheckCounter; 
        CheckDetail = $CheckDetail;
        Severity = $Severity
    }
$CheckCounter = 0


#############################################################################################
#Check foreach activity batch size is less than the service maximum
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Activitie(s) ForEach iteration with a batch count size that is less than the service maximum."
Write-Host "Running check... " $CheckDetail
$Severity = "Medium"
ForEach ($Activity in $Activities | Where-Object {$_.type -eq "ForEach"})
{   
    [bool]$isSequential = $false #attribute may only exist if changed, assume not present in arm template
    if((-not [string]::IsNullOrEmpty($Activity.typeProperties.isSequential)))
    {
        $isSequential = $Activity.typeProperties.isSequential
    }
    $BatchCount = $Activity.typeProperties.batchCount

    if(!$isSequential)
    {
        if($BatchCount -lt 50)
        {        
            $CheckCounter += 1
            if($VerboseOutput)
            {            
                $VerboseDetailTable += [PSCustomObject]@{
                    Component = "Activity";
                    Name = $Activity.Name;
                    CheckDetail = "ForEach has a batch size that is less than the service maximum.";
                    Severity = $Severity
                }
            }
        }
    }
}
$SummaryTable += [PSCustomObject]@{
        IssueCount = $CheckCounter; 
        CheckDetail = $CheckDetail;
        Severity = $Severity
    }
$CheckCounter = 0

#############################################################################################
#Check linked service using key vault
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Linked Service(s) not using Azure Key Vault to store credentials."
Write-Host "Running check... " $CheckDetail
$Severity = "High"

$LinkedServiceList = New-Object System.Collections.ArrayList($null)
ForEach ($LinkedService in $LinkedServices | Where-Object {$_.properties.type -ne "AzureKeyVault"})
{
    $typeProperties = Get-Member -InputObject $LinkedService.properties.typeProperties -MemberType NoteProperty

    ForEach($typeProperty in $typeProperties) 
    {
        $propValue = $LinkedService.properties.typeProperties | Select-Object -ExpandProperty $typeProperty.Name

        #handle linked services with multiple type properties
        if(([string]::IsNullOrEmpty($propValue.secretName))){
            $LinkedServiceName = (CleanName -RawValue $LinkedService.name)
            if(-not ($LinkedServiceList -contains $LinkedServiceName))
            {
                [void]$LinkedServiceList.Add($LinkedServiceName) #add linked service if secretName is missing
            }
        }
        if(-not([string]::IsNullOrEmpty($propValue.secretName))){
            $LinkedServiceName = (CleanName -RawValue $LinkedService.name)
            [void]$LinkedServiceList.Remove($LinkedServiceName) #renove linked service if secretName is then found
        }
    }
}
$CheckCounter = $LinkedServiceList.Count
$SummaryTable += [PSCustomObject]@{
    IssueCount = $CheckCounter; 
    CheckDetail = $CheckDetail;
    Severity = $Severity
}
$CheckCounter = 0

if($VerboseOutput)
{  
    ForEach ($LinkedServiceOutput in $LinkedServiceList)
    {
        $VerboseDetailTable += [PSCustomObject]@{
            Component = "Linked Service";
            Name = $LinkedServiceOutput;
            CheckDetail = "Not using Key Vault to store credentials.";
            Severity = $Severity
        }
    }
}

#############################################################################################
#Check for linked services not in use
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Linked Service(s) not used by any other resource."
Write-Host "Running check... " $CheckDetail
$Severity = "Medium"
ForEach($RedundantResource in $RedundantResources | Where-Object {$_ -like "linkedServices*"})
{
    $Parts = $RedundantResource.Split('|')

    $CheckCounter += 1
    if($VerboseOutput)
    {  
        $VerboseDetailTable += [PSCustomObject]@{
            Component = "Linked Service";
            Name = $Parts[1];
            CheckDetail = "Not used by any other resource.";
            Severity = $Severity
        }
    }
}
$SummaryTable += [PSCustomObject]@{
    IssueCount = $CheckCounter; 
    CheckDetail = $CheckDetail;
    Severity = $Severity
}
$CheckCounter = 0

#############################################################################################
#Check linked service descriptions
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Linked Service(s) without a description value."
Write-Host "Running check... " $CheckDetail
$Severity = "Low"
ForEach ($LinkedService in $LinkedServices)
{
    $LinkedServiceName = (CleanName -RawValue $LinkedService.name.ToString())
    $LinkedServiceDescription = $LinkedService.properties.description
    if(([string]::IsNullOrEmpty($LinkedServiceDescription)))
    {        
        $CheckCounter += 1
        if($VerboseOutput)
        {            
            $VerboseDetailTable += [PSCustomObject]@{
                Component = "Linked Service";
                Name = $LinkedServiceName;
                CheckDetail = "Does not have a description.";
                Severity = $Severity
            }
        }
    }
}
$SummaryTable += [PSCustomObject]@{
        IssueCount = $CheckCounter; 
        CheckDetail = $CheckDetail;
        Severity = $Severity
    }
$CheckCounter = 0

#############################################################################################
#Check for linked service without annotations
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Linked Service(s) without annotations."
Write-Host "Running check... " $CheckDetail
$Severity = "Low"
ForEach ($Pipeline in $Pipelines)
{
    $LinkedServiceName = (CleanName -RawValue $LinkedService.name.ToString())
    $LinkedServiceAnnotations = $Pipeline.properties.annotations.Count
    if($LinkedServiceAnnotations -le 0)
    {
        $CheckCounter += 1
        if($VerboseOutput)
        {  
            $VerboseDetailTable += [PSCustomObject]@{
                Component = "Linked Service";
                Name = $LinkedServiceName;
                CheckDetail = "Does not have any annotations.";
                Severity = $Severity
            }
        }
    }
}
$SummaryTable += [PSCustomObject]@{
        IssueCount = $CheckCounter; 
        CheckDetail = $CheckDetail;
        Severity = $Severity
    }
$CheckCounter = 0

#############################################################################################
#Check for datasets not in use
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Dataset(s) not used by any other resource."
Write-Host "Running check... " $CheckDetail
$Severity = "Medium"
ForEach($RedundantResource in $RedundantResources | Where-Object {$_ -like "datasets*"})
{
    $Parts = $RedundantResource.Split('|')

    $CheckCounter += 1
    if($VerboseOutput)
    {  
        $VerboseDetailTable += [PSCustomObject]@{
            Component = "Dataset";
            Name = $Parts[1];
            CheckDetail = "Not used by any other resource.";
            Severity = $Severity
        }
    }
}
$SummaryTable += [PSCustomObject]@{
    IssueCount = $CheckCounter; 
    CheckDetail = $CheckDetail;
    Severity = $Severity
}
$CheckCounter = 0

#############################################################################################
#Check for dataset without description
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Dataset(s) without a description value."
Write-Host "Running check... " $CheckDetail
$Severity = "Low"
ForEach ($Dataset in $Datasets)
{
    $DatasetName = (CleanName -RawValue $Dataset.name.ToString())
    $DatasetDescription = $Dataset.properties.description
    if(([string]::IsNullOrEmpty($DatasetDescription)))
    {
        $CheckCounter += 1
        if($VerboseOutput)
        {  
            $VerboseDetailTable += [PSCustomObject]@{
                Component = "Dataset";
                Name = $DatasetName;
                CheckDetail = "Does not have a description.";
                Severity = $Severity
            }
        }
    }
}
$SummaryTable += [PSCustomObject]@{
        IssueCount = $CheckCounter; 
        CheckDetail = $CheckDetail;
        Severity = $Severity
    }
$CheckCounter = 0

#############################################################################################
#Check dataset not in folders
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Dataset(s) not organised into folders."
Write-Host "Running check... " $CheckDetail
$Severity = "Low"
ForEach ($Dataset in $Datasets)
{
    $DatasetName = (CleanName -RawValue $Dataset.name.ToString())
    $DatasetFolder = $Dataset.properties.folder.name
    if(([string]::IsNullOrEmpty($DatasetFolder)))
    {        
        $CheckCounter += 1
        if($VerboseOutput)
        {            
            $VerboseDetailTable += [PSCustomObject]@{
                Component = "Dataset";
                Name = $DatasetName;
                CheckDetail = "Not organised into a folder.";
                Severity = $Severity
            }
        }
    }
}
$SummaryTable += [PSCustomObject]@{
        IssueCount = $CheckCounter; 
        CheckDetail = $CheckDetail;
        Severity = $Severity
    }
$CheckCounter = 0

#############################################################################################
#Check for datasets without annotations
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Dataset(s) without annotations."
Write-Host "Running check... " $CheckDetail
$Severity = "Low"
ForEach ($Dataset in $Datasets)
{
    $DatasetName = (CleanName -RawValue $Dataset.name.ToString())
    $DatasetAnnotations = $Dataset.properties.annotations.Count
    if($DatasetAnnotations -le 0)
    {
        $CheckCounter += 1
        if($VerboseOutput)
        {  
            $VerboseDetailTable += [PSCustomObject]@{
                Component = "Dataset";
                Name = $DatasetName;
                CheckDetail = "Does not have any annotations.";
                Severity = $Severity
            }
        }
    }
}
$SummaryTable += [PSCustomObject]@{
        IssueCount = $CheckCounter; 
        CheckDetail = $CheckDetail;
        Severity = $Severity
    }
$CheckCounter = 0

#############################################################################################
#Check for triggers not in use
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Trigger(s) not used by any other resource."
Write-Host "Running check... " $CheckDetail
$Severity = "Medium"
ForEach($RedundantResource in $RedundantResources | Where-Object {$_ -like "triggers*"})
{
    $Parts = $RedundantResource.Split('|')

    $CheckCounter += 1
    if($VerboseOutput)
    {  
        $VerboseDetailTable += [PSCustomObject]@{
            Component = "Trigger";
            Name = $Parts[1];
            CheckDetail = "Not used by any other resource.";
            Severity = $Severity
        }
    }
}
$SummaryTable += [PSCustomObject]@{
    IssueCount = $CheckCounter; 
    CheckDetail = $CheckDetail;
    Severity = $Severity
}
$CheckCounter = 0

#############################################################################################
#Check for trigger descriptions
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Trigger(s) without a description value."
Write-Host "Running check... " $CheckDetail
$Severity = "Low"
ForEach ($Trigger in $Triggers)
{
    $TriggerName = (CleanName -RawValue $Pipeline.name.ToString())
    $TriggerDescription = $Trigger.properties.description

    if(([string]::IsNullOrEmpty($TriggerDescription)))
    {
        $CheckCounter += 1
        if($VerboseOutput)
        {  
            $VerboseDetailTable += [PSCustomObject]@{
                Component = "Trigger";
                Name = $TriggerName;
                CheckDetail = "Does not have a description.";
                Severity = $Severity
            }
        }
    }
}
$SummaryTable += [PSCustomObject]@{
        IssueCount = $CheckCounter; 
        CheckDetail = $CheckDetail;
        Severity = $Severity
    }
$CheckCounter = 0

#############################################################################################
#Check for trigger without annotations
#############################################################################################
$CheckNumber += 1
$CheckDetail = "Trigger(s) without annotations."
Write-Host "Running check... " $CheckDetail
$Severity = "Low"
ForEach ($Trigger in $Triggers)
{
    $TriggerName = (CleanName -RawValue $Trigger.name.ToString())
    $TriggerAnnotations = $Trigger.properties.annotations.Count

    if($TriggerAnnotations -le 0)
    {
        $CheckCounter += 1
        if($VerboseOutput)
        {  
            $VerboseDetailTable += [PSCustomObject]@{
                Component = "Trigger";
                Name = $TriggerName;
                CheckDetail = "Does not have any annotations.";
                Severity = $Severity
            }
        }
    }
}
$SummaryTable += [PSCustomObject]@{
        IssueCount = $CheckCounter; 
        CheckDetail = $CheckDetail;
        Severity = $Severity
    }
$CheckCounter = 0



#############################################################################################
Write-Host ""
Write-Host $Hr

if($SummaryOutput)
{    
    Write-Host ""
    Write-Host "Results Summary:"
    Write-Host ""
    Write-Host "Checks ran against template:" $CheckNumber
    Write-Host "Checks with issues found:" ($SummaryTable | Where-Object {$_.IssueCount -ne 0}).Count.ToString()
    Write-Host "Total issue count:" ($SummaryTable | Measure-Object -Property IssueCount -Sum).Sum

    $SummaryTable | Where-Object {$_.IssueCount -ne 0} | Format-Table @{
        Label = "Issue Count";Expression = {$_.IssueCount}; Alignment="Center"}, @{
        Label = "Check Details";Expression = {$_.CheckDetail}}, @{
        Label = "Severity"
        Expression =
        {
            switch ($_.Severity)
            {
                #https://docs.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#span-idtextformattingspanspan-idtextformattingspanspan-idtextformattingspantext-formatting
                'Low' {$color = "92"; break }
                'Medium' {$color = '93'; break }
                'High' {$color = "31"; break }
               default {$color = "0"}
            }
            $e = [char]27
           "$e[${color}m$($_.Severity)${e}[0m"
        }
    }
    Write-Host $Hr
}

if($VerboseOutput)
{
    Write-Host ""
    Write-Host "Results Details:"
    
    $VerboseDetailTable | Format-Table @{
        Label = "Component";Expression = {$_.Component}}, @{
        Label = "Name";Expression = {$_.Name}}, @{
        Label = "Check Detail";Expression = {$_.CheckDetail}}, @{
        Label = "Severity"
        Expression =
        {
            switch ($_.Severity)
            {
                #https://docs.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#span-idtextformattingspanspan-idtextformattingspanspan-idtextformattingspantext-formatting
                'Low' {$color = "92"; break }
                'Medium' {$color = '93'; break }
                'High' {$color = "31"; break }
               default {$color = "0"}
            }
            $e = [char]27
           "$e[${color}m$($_.Severity)${e}[0m"
        }
    }
    Write-Host $Hr
}

return $SummaryTable

}