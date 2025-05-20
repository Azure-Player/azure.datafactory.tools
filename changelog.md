# Changelog - azure.datafactory.tools

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.13.0] - 2025-05-20
### Fixed
* Adopted to breaking change in Az.Accounts v5.0 with Get-AzAccessToken that doesn't support String anymore #449

## [1.12.0] - 2025-03-20
### Added
* Error during the import when required Az.Resource module is not loaded #336
* Az.DataFactory module is required to import adftools
* Added function `Set-AdfToolsAuthToken` to enable changing URL to API when target environment is different than default Global Azure #356 #441
### Fixed
* Error when deleting credentials #403

## [1.11.2] - 2024-12-04
### Fixed
* Unknown object type: SparkJobDefinition #428 by adding the type to the ignored list

## [1.11.1] - 2024-11-06
### Fixed
* Fixed saving deployment state file with UTF8 BOM-less regardless of PS version #425

## [1.11.0] - 2024-10-29
### Fixed / Added
* Incremental deploy feature causes payload limit issue #374
* Incremental state is no longer save into Global Parameter of ADF, but now it's store in provided Storage Account #374

## [1.10.0] - 2024-08-06
### Fixed
* Trigger Activation Failure Post-Selective Deployment when TriggerStopMethod = `DeployableOnly` #386
* Significantly improved performance of unit tests by mocking target ADF

## [1.9.1] - 2024-06-17
### Fixed
* `Test-AdfCode` failed when run on Docker image and $ConfigPath param is not provided #394

## [1.9.0] - 2024-03-01
### Fixed
* Fixed failure of publishing ADF when globalConfigurations exist in Factory file but Global Params does not #387

## [1.8.0] - 2023-09-12
### Fixed
* Incremental re-deployment of deleted and recreated objects #355

## [1.7.0] - 2023-08-17
### Fixed
* Deployment of Global Parameters might not work sometimes #354

## [1.6.3] - 2023-07-17
### Added
* Stop and restart only changed triggers #264 #332
* New option to Stop/Start only the triggers that are already Started #291
### Fixed
* `RootFolder` must be absolute otherwise temp files cannot be written #335
* Catch InvalidOperation exception when reading empty FilterFilePath in New-AdfPublishOption.ps1 #338
* Purview configuration gets overwritten when deploy Global Parameters using ADF deployment task #343
* Incremental Deployment seems to not work when factory folder does not exist #346
* The publish cmdlet tries to delete enabled (active) trigger (not in source) when TriggerStartMethod = KeepPreviousState #350

## [1.5.0] - 2023-06-18
### Added
* Remove pipeline's from check (`Test-AdfCode`) for dashes in name #309
* Test-AdfLinkedService can use internally Invoke-AzRestMethod #144
* Test-AdfLinkedService return an object #165
* Test-AdfLinkedService accepts parameters of testing LS #222
### Fixed
* Bug #311: Fixed deletion of credential type of objects
* Bug #331: Fixed `Test-AdfCode` for [credential] objects

## [1.4.0] - 2023-04-26
### Added
* More precise error message when value in config is empty #300
* Incremental deployment!!! #195
* Support for credentials deployment & delete #156

## [1.3.0] - 2023-02-27
### Fixed
* Defined ignored types in references and added `BigDataPool` to it #289

## [1.2.0] - 2023-02-24
### Fixed
* Validation of ADF files fails when JSON contains property with single quote #287
* Validation of ADF files fails when a pipeline has reference to Synapse notebook

## [1.1.0] - 2023-02-23
* Support for new SynapseNotebook activity #279

## [1.0.0] - 2023-01-02
* Version 1.0 released
* 100% tests passed

## [0.110.1] - 2022-12-03
### Fixed
* Bug #260: Test-AdfCode function: The property 'globalParameters' cannot be found on this object.

## [0.101.0] - 2022-11-19 
### Fixed
* Bug #226: Cannot overwrite/set DateTime type of value via config file

## [0.100.0] - 2022-11-18 
### Fixed
* Bug #229: Wildcard in name not working in json config file

## [0.99.0] - 2022-10-24 
### Fixed
* The module accepts **Credentials** type of object (when loading from files), but the deployment is skipped and not supported yet. #156

## [0.97.0] - 2022-04-25
### Fixed
* `Publish-AdfV2UsingArm` cmdlet to make it compatible with PS 5.1
* Updating value of global params of boolean types #203
### Added
* Added tests for `Publish-AdfV2UsingArm`
* Added `OutputFolder` input parameter to `Export-AdfToArmTemplate`
* Added new cmdlet: `Test-AdfArmTemplate` #191

## [0.96.0] - 2022-02-24
### Fixed
* Bug: Error in replacing property using config.csv when empty element exists #186
* Bug: Replacing properties from json-config for managedPrivateEndpoints #184 #185

## [0.95.1] - 2021-12-07
* Bug fixed: Loading ADF from code fails when excluding any object and ManagedVNET exist #171

## [0.95.0] - 2021-10-23
* Added structure to return object for Test-AdfCode which allows to check number of warnings too
* Fixed tests

## [0.94.0] - 2021-10-20
* Fixed bug: add 'properties' node to ManagedVirtualNetwork if does not exist in default.json file #157

## [0.93.0] - 2021-10-17
* Added cmdlet: `Export-AdfToArmTemplate`
* Added cmdlet: `Publish-AdfV2UsingArm` (preview)
* Fixed `Test-AdfCode` which complete exec even if some issue is found
* Added workaround for ManagedVirtualNetwork object without 'properties' node #149

## [0.91.0] - 2021-10-01
* Fixed #147: Pipeline could be broken when contains array with 1 item in JSON file and any property was updated

## [0.90.0] - 2021-09-25
* Added cmdlet to generate mermaid diagram to be used in MarkDown type of documents
* Added public command `Start-AdfTriggers`
* Added retry action on failure of starting trigger #107

## [0.80.0] - 2021-08-17
* Fixed `Get-ReferencedObjects` which fails for files with empty element in JSON #128

## [0.75.0] - 2021-08-05
* Fixed `Test-AdfCode` when validating empty factory #125

## [0.74.0] - 2021-08-03
* Cmdlet `Test-AdfCode` validates config files #62
* Support configuration for Managed Private Endpoint #95
* Implement Dry Run Functionality for Publishing #120 (Thanks [Liam](https://github.com/liamejdunphy)!)

## [0.73.0] - 2021-06-15
* Added option to index into arrays by element name #98 (Thanks [Niall](https://github.com/NJLangley)!)

## [0.72.0] - 2021-06-12
### Fixed
* Removing excluded ADF objects when option $DoNotDeleteExcludedObjects = $false ([#108](https://github.com/SQLPlayer/azure.datafactory.tools/issues/108))
* Changed method of discovering referenced objects (Get-ReferencedObjects) #95

## [0.70.0] - 2021-06-10
### Added
* Support for ADF Managed Virtual Network & Managed Private Endpoint (preview)

## [0.61.0] - 2021-04-21
### Fixed
* Deploy global Parameter type object ([#92](https://github.com/SQLPlayer/azure.datafactory.tools/issues/92))
### Added
* Cmdlet `Test-AdfCode` returns number of found errors.

## [0.60.0] - 2021-02-10
### Added
* Add Test method for Linked Services ([#48](https://github.com/SQLPlayer/azure.datafactory.tools/issues/48)) Preview

## [0.50.0] - 2021-01-20
### Fixed
* JSON file corrupted when contained object is located deeper than 15 nodes ([[#80](https://github.com/SQLPlayer/azure.datafactory.tools/issues/80)])

## [0.40.0] - 2021-01-13
### Added
* New function: Test-AdfCode [#62](https://github.com/SQLPlayer/azure.datafactory.tools/issues/62)]

## [0.30.0] - 2021-01-08
### Added
* Better control of which: (see new publish flags below)
  * triggers could be stop/start
  * objects could be removed (if apply)
* Publish flag: `DoNotDeleteExcludedObjects` ([#47](https://github.com/SQLPlayer/azure.datafactory.tools/issues/47))
* Publish flag: `DoNotStopStartExcludedTriggers` allows stopping selected triggers ([#51](https://github.com/SQLPlayer/azure.datafactory.tools/issues/51))
* Numbers to all error messages ([full list](./en-us/messages_index.md))

## [0.20.0] - 2020-12-28
### Fixed
* Do not start trigger which has not been deployed and thus does not exist (#51)

## [0.19.0] - 2020-12-23
### Added
* Support wildcard when specifying object(s) name in config file (#58)
* Added option `$IgnoreLackOfReferencedObject` (#64)
* Add object name to the msg before action (#49)
* Exit publish cmd when ADF name is already in use (#43)
* Allow selecting objects in given folder (#68)
### Fixed
* Finding dependencies miss objects when the same object names occurs (#65)
* DeleteNotInSource fails when attempting to remove active trigger or found many dependant objects (#67)

## [0.18.0] - 2020-12-04
### Added
* Added the ability to only warn on missing paths in config (#59 by @chris5287)
### Fixed
* JSON file could be corrupted when config update has happened on a very deep path (#33)
* Special characters deployed wrong (#50)

## [0.17.0] - 2020-10-02
### Added
* Added new publish option: FailsWhenConfigItemNotFound

## [0.16.1] - 2020-09-10
### Fixed
* Bug during a publication when General Parameters are not existed (#39)
* Bug in GetObjectsByFolderName when General Parameters are not existed (#38)

## [0.16.0] - 2020-09-09
### Added
* Added public function: Stop-AdfTriggers

## [0.15.0] - 2020-09-08
### Added
* Support of JSON format for config files
* Support of Global Parameters (#29)
### Changed
* Function GetObjectsByFolderName (Adf class) uses LIKE operator (#31)

## [0.14.0] - 2020-07-26
### Changed
* Removed workaround for deployment of Azure Integration Runtimes.
### Added
* List of filtering rules (Includes/Excludes) can be provided by file
* Config file allows defining a property to be added or removed

## [0.13.0] - 2020-07-08
### Fixed
* All lines were being ignored in config file after commented line (#24)
### Added
* Precise error message once path provided in config file cannot be found in json file

## [0.12.0] - 2020-06-17
### Added
* Config file allows using tokens in `value` column to be replaced by environment variables value

## [0.11.0] - 2020-06-16
### Added
* Validates config file during loading when `stage` parameter is provided
* Config files allows defining whole nested JSON object (in addition to string or number only) (#16)
* A line in CSV config file can be commented with hash character

## [0.10.0] - 2020-06-06
### Changed
* DeleteNotInSource option is $false by default now
* Creates copy of files when replacing properties with values from config
### Fixed
* When DeleteNotInSource=True and a trigger vanished from the source then the active trigger was not removing from service (#17)
* Starting triggers based on properties replaced within config values (#18)
* Encoding UTF8 is set when reading all objects from disk (#19)
* Changed encoding to UTF8 when writing files with replaced properties

## [0.9.0] - 2020-06-03
### Added
* Additional method of deployment by New-AzResource cmdlet (default)
### Fixed
* Correct casing for folder "linkedService" in Import-AdfObjects cmdlet

## [0.8.0] - 2020-05-26
### Added
* Creation of ADF (if does not exist) is optional now
* The first set of unit tests for the module
* Capability to pass full path to csv config file location via `stage` parameter 

## [0.7.0] - 2020-05-09
### Fixed
* Fixed RegEx to scanning dependant objects (references). They were not found when multiple whitespaces figured.
* Function `Import-AdfFromFolder` throws an exception when passed folder doesn't exist.
### Added
* Capability to publish only objects located in the selected folder(s) in ADF
  * Function `Import-AdfFromFolder` is public now. Return instance of ADF class
  * Functions in ADF class allows returning a list of objects by name or folder

## [0.6.1] - 2020-05-02
### Fixed
* Restarting triggers fails for *Tumbling Window* type of Trigger [[#4](https://github.com/SQLPlayer/azure.datafactory.tools/issues/4)]

## [0.6.0] - 2020-05-02
### Added
* Filtering (include or exclude) objects to be deployed by name and/or type
* Publish options allow you to control:
  * Whether stop and restarting triggers
  * Whether delete or not objects not in the source

## [0.5.0] - 2020-04-24
### Added
* Drop objects not in the source
* New function: Get-AdfFromService
### Fixed
* Supports different objects with the same name

## [0.4.2] - 2020-04-20
### Fixed
* Stop-Triggers : The property 'Count' cannot be found on this object. Verify that the property exists. (#2)
* PS module reads only ps1 files as cmdlets during its loading

## [0.4.1] - 2020-04-15
### Added
* Support (deployment) of Azure Managed Integration Runtimes

## [0.4.0] - 2020-04-13
### Added
* Support (deployment) of Integration Runtimes type of connections (inc. Self-Hosted only)

## [0.3.0] - 2020-04-11
### Added
* Support (deployment) of triggers, including stop/start
### Fixed
* Skip importing particular type of objects when folder doesn't exist
* Location is required when ADF instance doesn't exist and need to be created
### Changed
* Az.DataFactory minimum version 1.7.0 is required

## [0.2.3] - 2020-04-09
### Features
* Added support of dataflows
* Shows Elapsed time at the end of publish process

## [0.2.0] - 2020-04-08
### Features
* Replace property values defined in csv config file (per environment)

## [0.1.0] - 2020-03-28
### Features
* Deploy ADF from code written in JSON files
* Deployment process takes care of the order in which files are deployed
