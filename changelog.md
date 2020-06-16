# Changelog - azure.datafactory.tools

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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
