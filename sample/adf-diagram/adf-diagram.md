::: mermaid
graph LR
linkedService.LS_REST_Graph --> linkedService.LS_KEYVAULT
pipeline.pl_ingest_ecdc_data --> dataset.ds_ecdc_file_list_json
pipeline.pl_ingest_ecdc_data --> dataset.ds_ecdc_raw_csv_http
pipeline.pl_ingest_ecdc_data --> dataset.ds_ecdc_raw_csv_dl
pipeline.pl_ingest_population_data --> dataset.ds_population_raw_gz
pipeline.pl_ingest_population_data --> pipeline.PL_Send_Email_On_Failure
pipeline.pl_ingest_population_data --> dataset.ds_population_raw_tsv
pipeline.pl_ingest_population_data --> linkedService.ls_blob_7ndjrhstorageaccountblob
pipeline.PL_MicrosoftGraphData --> dataset.DS_REST_Graph
pipeline.PL_MicrosoftGraphData --> dataset.DS_ADLS_Generic_JSON
pipeline.PL_MovieAnalyticsLab --> dataset.DS_S3_Movies_DelimitedText
pipeline.PL_MovieAnalyticsLab --> dataset.DS_ADLS_Generic_DelimitedText
pipeline.PL_MovieAnalyticsLab --> dataFlow.DF_MovieAnalyticsLab
pipeline.PL_PowerBI_GetActivityEvents_ADLS --> dataset.DS_REST_PowerBI
pipeline.PL_PowerBI_GetActivityEvents_ADLS --> dataset.DS_ADLS_Generic_JSON
pipeline.PL_PowerBI_GetInventory_Objects_ADLS --> dataset.DS_REST_PowerBI
pipeline.PL_PowerBI_GetInventory_Objects_ADLS --> dataset.DS_ADLS_Generic_JSON
pipeline.pl_SetSourceRelativeURLVariablesExample --> dataset.ds_ecdc_file_list_json
dataset.DS_ADLS_Generic_DelimitedText --> linkedService.ls_adlsdatanalytics
dataset.DS_ADLS_Generic_JSON --> linkedService.ls_adlsdatanalytics
dataset.DS_ADLS_PowerBIActivityEvents_JSON --> linkedService.ls_adlsdatanalytics
dataset.ds_ecdc_file_list_json --> linkedService.ls_blob_7ndjrhstorageaccountblob
dataset.ds_ecdc_raw_csv_dl --> linkedService.ls_adlsdatanalytics
dataset.ds_ecdc_raw_csv_http --> linkedService.ls_http_opendata_ecdc_europa_eu
dataset.ds_population_raw_gz --> linkedService.ls_blob_7ndjrhstorageaccountblob
dataset.ds_population_raw_tsv --> linkedService.ls_adlsdatanalytics
dataset.DS_REST_Graph --> linkedService.LS_REST_Graph
dataset.DS_REST_PowerBI --> linkedService.ls_rest_pbi_generic
dataset.DS_S3_Movies_DelimitedText --> linkedService.MoviesGitHub
dataflow.DF_MovieAnalyticsLab --> linkedService.ls_adlsdatanalytics
dataflow.DF_Movie_CSV_to_Delta --> linkedService.ls_adlsdatanalytics
trigger.tr_ingest_population_data --> pipeline.pl_ingest_population_data
:::
