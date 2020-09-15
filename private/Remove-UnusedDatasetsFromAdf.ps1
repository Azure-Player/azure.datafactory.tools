function Remove-UnusedDatasetsFromAdf {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Adf] $Adf,
        [Parameter(Mandatory = $false)] [switch] $SoftDelete
    )

    $dataset_list = $Adf.GetUnusedDatasets()
    
    foreach($dataset_name in $dataset_list){
        # get the dataset object
        $obj = Get-AdfObjectByName -adf $Adf -type "Dataset" -name $dataset_name

        # remove it from the ADF object
        $Adf.DataSets.Remove($obj)

        # if softdelete is not activated, then also delete the json file.
        if(!$SoftDelete){
            Remove-Item $obj.FileName
        }
    }

}