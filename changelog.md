﻿# Changelog - azure.datafactory.tools

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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
