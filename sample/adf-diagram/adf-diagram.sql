DROP TABLE IF EXISTS #Dependency
CREATE TABLE #Dependency(Source nvarchar(max), Target nvarchar(max))
INSERT INTO #Dependency(Source,Target) VALUES ('linkedService.LS_REST_Graph','linkedService.LS_KEYVAULT');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.pl_ingest_ecdc_data','dataset.ds_ecdc_file_list_json');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.pl_ingest_ecdc_data','dataset.ds_ecdc_raw_csv_http');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.pl_ingest_ecdc_data','dataset.ds_ecdc_raw_csv_dl');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.pl_ingest_population_data','dataset.ds_population_raw_gz');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.pl_ingest_population_data','pipeline.PL_Send_Email_On_Failure');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.pl_ingest_population_data','dataset.ds_population_raw_tsv');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.pl_ingest_population_data','linkedService.ls_blob_7ndjrhstorageaccountblob');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.PL_MicrosoftGraphData','dataset.DS_REST_Graph');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.PL_MicrosoftGraphData','dataset.DS_ADLS_Generic_JSON');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.PL_MovieAnalyticsLab','dataset.DS_S3_Movies_DelimitedText');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.PL_MovieAnalyticsLab','dataset.DS_ADLS_Generic_DelimitedText');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.PL_MovieAnalyticsLab','dataFlow.DF_MovieAnalyticsLab');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.PL_PowerBI_GetActivityEvents_ADLS','dataset.DS_REST_PowerBI');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.PL_PowerBI_GetActivityEvents_ADLS','dataset.DS_ADLS_Generic_JSON');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.PL_PowerBI_GetInventory_Objects_ADLS','dataset.DS_REST_PowerBI');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.PL_PowerBI_GetInventory_Objects_ADLS','dataset.DS_ADLS_Generic_JSON');
INSERT INTO #Dependency(Source,Target) VALUES ('pipeline.pl_SetSourceRelativeURLVariablesExample','dataset.ds_ecdc_file_list_json');
INSERT INTO #Dependency(Source,Target) VALUES ('dataset.DS_ADLS_Generic_DelimitedText','linkedService.ls_adlsdatanalytics');
INSERT INTO #Dependency(Source,Target) VALUES ('dataset.DS_ADLS_Generic_JSON','linkedService.ls_adlsdatanalytics');
INSERT INTO #Dependency(Source,Target) VALUES ('dataset.DS_ADLS_PowerBIActivityEvents_JSON','linkedService.ls_adlsdatanalytics');
INSERT INTO #Dependency(Source,Target) VALUES ('dataset.ds_ecdc_file_list_json','linkedService.ls_blob_7ndjrhstorageaccountblob');
INSERT INTO #Dependency(Source,Target) VALUES ('dataset.ds_ecdc_raw_csv_dl','linkedService.ls_adlsdatanalytics');
INSERT INTO #Dependency(Source,Target) VALUES ('dataset.ds_ecdc_raw_csv_http','linkedService.ls_http_opendata_ecdc_europa_eu');
INSERT INTO #Dependency(Source,Target) VALUES ('dataset.ds_population_raw_gz','linkedService.ls_blob_7ndjrhstorageaccountblob');
INSERT INTO #Dependency(Source,Target) VALUES ('dataset.ds_population_raw_tsv','linkedService.ls_adlsdatanalytics');
INSERT INTO #Dependency(Source,Target) VALUES ('dataset.DS_REST_Graph','linkedService.LS_REST_Graph');
INSERT INTO #Dependency(Source,Target) VALUES ('dataset.DS_REST_PowerBI','linkedService.ls_rest_pbi_generic');
INSERT INTO #Dependency(Source,Target) VALUES ('dataset.DS_S3_Movies_DelimitedText','linkedService.MoviesGitHub');
INSERT INTO #Dependency(Source,Target) VALUES ('dataflow.DF_MovieAnalyticsLab','linkedService.ls_adlsdatanalytics');
INSERT INTO #Dependency(Source,Target) VALUES ('dataflow.DF_Movie_CSV_to_Delta','linkedService.ls_adlsdatanalytics');
INSERT INTO #Dependency(Source,Target) VALUES ('trigger.tr_ingest_population_data','pipeline.pl_ingest_population_data');
--Staging Table #Dependency filled
