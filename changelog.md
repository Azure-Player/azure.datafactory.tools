# Changelog - azure.datafactory.tools

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.4.0] - 2020-04-13
### Added
* Support (deployment) of Integration Runtimes type of connections (inc. Self-Hosted, Managed)

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
