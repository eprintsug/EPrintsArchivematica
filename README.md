![EPrints to Archivematica Transfer](https://github.com/eprintsug/EPrintsArchivematica/blob/master/lib/static/epm/images/EPrintsArchivematica.png)

Table of Contents
=================

   * [EPrints - Archivematica Integration](#eprints---archivematica-integration)
   * [Usage](#usage)
      * [BIN Scripts:](#bin-scripts)
         * [Run these scripts with the command line](#run-these-scripts-with-the-command-line)
      * [Config Files:](#config-files)
   * [Summary](#summary)
   * [Implementation details](#implementation-details)
      * [Derivatives](#derivatives)
      * [Checksum manifest](#checksum-manifest)
      	 * [Checksum Mismatch](#checksum-mismatch)
      	 * [Files with no MD5 value in the EPrints database](#files-with-no-md5-value-in-the-eprints-database) 
      * [Preservation Management Screen](#preservation-management-screen)
      * [Preservation Triggers](#preservation-triggers)
      * [Archivematica Sending Information Back to EPrints](#archivematica-sending-information-back-to-eprints)

# EPrints - Archivematica Integration

Digital Preservation through EPrints-Archivematica Integration - An EPrints export plugin for contents to be preserved with Archivematica

The EPrints-Archivematica integration proposal was first presented at Archivematica Camp and OR2018 in Bozeman.
The OR2018 presentation is available here:

Neugebauer, Tomasz , Simpson, Justin and Bradley, Justin (2018) Digital Preservation through EPrints-Archivematica Integration. In: International Conference on Open Repositories, June 3-7, 2018, Bozeman, Montana, USA
https://spectrum.library.concordia.ca/983933/

# Bazaar Plugin

Bazaar plugin (version 1.2.2) EPM now available here: 

https://bazaar.eprints.org/1206/

# Usage

## BIN Scripts:

* /archives/REPOID/bin/create_transfers
* /archives/REPOID/bin/process_transfers
* /archives/REPOID/bin/touch_transfers

### Run these scripts with the command line

**create_transfers** will create the missing archivematica dataset records for all live eprints.  (You’ll have to edit the script if you want review instead of archive.)

**touch_transfers** will set is_dirty=TRUE on those existing archivematica records where its not already set.  Optionally, adding the flag --unset does the reverse: sets is_dirty=FALSE on those records that have is set to TRUE.  

./touch_transfers REPOID --dataobj=1 --unset

**process_transfers** exports all eprints to archivematica that are flagged as "is_dirty".  

All three of these scripts can also take an optional parameter to limit the operation to a specific EPrintID.  This is especially useful for testing or troubleshooting the export of a specific eprint.  For example, to limit to eprintid 1:

./create_transfers REPOID --dataobj=1 

All three of these scripts can also take an optional parameter to limit the number of records it will process before exiting. For example, to create up-to 10 archivematica records for those that are missing: 

./create_transfers REPOID --limit=10

All three of these scripts can also take the optional --verbose argument, to make the output more detailed.  For example:

./create_transfers REPOID --verbose --limit=5

## Config Files:

* /archives/REPOID/cfg/cfg.d/z_archivematica.pl   (set where the Archivematica transfer folder is in this file, this is where exports are written to)

### Export Folder Locations:

You will need to set the two folder locations in z_archivematica.pl:

`$c->{archivematica}->{path} = '/opt/eprints3/var/archivematica/test';`

`$c->{archivematica}->{metadata_only_path} = '/opt/eprints3/var/archivematica/metadata-only';`

{path} is where the plugin will export the packages for Archivematica to transfer from. 

{metadata_only_path} is where the plugin will export metadata-only records it encounters.  If you set this to "" or leave it undefined, the plugin will not export matadata-only records to the file system.

# Summary

The following is a summary of the proposed workflow for EPrints-Archivematica integration:

* “Digital Preservation Export” batch script runs periodically that identifies new/updated items to
export and generates the exports in a directory structure optimized for [Archivematica transfers](https://www.archivematica.org/en/docs/archivematica-1.7/user-manual/transfer/transfer/#transfer-checksums) described below.

* The export plugin will create a transfer for each eprint. Each transfer includes: 
	* An `objects` directory containing the uploaded digital files that are part of the eprint as well as any derivative access files generated by EPrints
	* An `objects/documents` folder containing all uploaded digital files that are a part of the eprint
	* A `objects/derivatives` folder containing any derivative access files that were generated by EPrints, such as thumbnail images, audio access files, video access files
	* A `metadata` folder with Dublin Core metadata (in JSON format), EPrints XML metadata, EPrints-generated "revision" XML files, and an `md5deep`-style checksum manifest for digital files in the `objects` directory
	* A `metadata/revisions` folder containing all EPrints-generated “revision” XML files

Transfers are moved to a specified shared storage location. 

![Eprint Export Folder Structure](https://github.com/photomedia/EPrintsArchivematica/blob/master/eprint-export-folder-structure.png)

* The following would be the structure of the documents folder:

![Eprint Export Folder Structure - Documents](https://github.com/photomedia/EPrintsArchivematica/blob/master/eprint-export-documents-folder-structure.png)

* The following would be the structure of the derivatives folder:

`fileid-XXXXX -> folder# -> filename`

* Archivematica's [Automation Tools](https://github.com/artefactual/automation-tools) monitors shared storage for new export directory, creates transfers/ingests in Archivematica according to a user-defined processing configuration, and then stores AIPs in archival storage.

This integration is currently in the technical specification phase.

# Implementation details

## Derivatives

$c->{DPExport}->{include_derivatives}=1;

Setting this to 0 would exclude anything such as thumbnail images and web accessible versions of the audio and video files.

## Checksum manifest

The `metadata/checksum.md5` file should follow the specifications detailed in the [Archivematica documentation for creating a transfer with existing checksums](https://www.archivematica.org/en/docs/archivematica-1.8/user-manual/transfer/transfer/#create-a-transfer-with-existing-checksums).

Specifically, in this implementation, each line of the `checksum.md5` manifest should contain the md5 hash value for a file in the `objects` directory, followed by two spaces, followed by the relative path to the file from the `checksum.md5` file itself.

Example:

`2121dca88ad7f701d3f3e2d041004a56  ../objects/documents/my-doc.pdf`

### Checksum Mismatch

For files with MD5 values already recorded in the EPrints database, use these values in the manifest.  For these values already recorded in EPrints database, they should be checked (ie., recalculated for the file and compared to what is stored in EPrints) signalling an error if there is a mismatch.  These errors indicate that file corruption may have already taken place.  There should be a configuration option to control what happens in case of a checksum mismatch:

$c->{DPExport}={on-checksum-mismatch}=skip-proceed|halt 

NOTE: this option is not yet implemented, current default behaviour for checksum mismatch (not checksum missing) is to halt

skip-proceed should be the default, meaning that the problematic eprint is flagged with an error in the eprint's digital preservation errors field, but the batch job continues.  If 'halt' is chosen, the entire batch job that the problematic eprint is a part of halts.

In addition, there should be an option to communicate checksum-mismatch error by email:
$c->{DPExport}={on-checksum-mismatch-email-notification}= 1|0

NOTE: this option is not yet implemented

It should be set to 0 by default, and if set to 1, in addition to the problematic eprint not exporting, an email with the error information is sent to the address selected in the following config:

$c->{DPExport}={DP-admin-email}="[email address]"

NOTE: this option is not yet implemented

### Files with no MD5 value in the EPrints database - Checksum Missing

The following option is used to control if the export routines generate the missing checksum and add it to the EPrints database:

$c->{DPExport}->{add_missing_checksums} = 1|0;

If this is set to 1, the following happens:

* Generate a new MD5 from the file on disk
* Write the MD5 to the EPrints database
* Write the MD5 to the `checksum.md5` manifest
* Note that the MD5 was generated for the given file in the eprints' digital preservation warnings log

If it is set to 0, the missing checksum will result in a checksum mismatch.

## Preservation Management Screen

An EPrintsArchivematica preservation management screen allows the administrator to browse eprints, including by last exported date, and export status (success or failure - with reason).  For example, an eprint fails the checksum rechecking prior to export  and so is not exported, or is exported with new checksum.

## Preservation Triggers

Plugin configuration file will include a list of metadata elements who's change would flag an eprint as in need of preservation. 
Default triggers:

$c->{DPExport}->{trigger_fields}->{meta_fields} = [ qw/ title creators_name creators_id fileinfo / ]; 

There should be a command line bin script that will export entire "live" archive dataset, or a list of eprintIDs.

## Archivematica Sending Information Back to EPrints

It would be very useful from a management and quality assurance perspective to be able to confirm, in EPrints, that an EPrint was succesfully exported, Archivematica picked up the transfer, and Archivematica successfully created and stored an AIP (Archival Information Package) for the transfer all from the same management screen.   

The Archivematica Storage Service application has in-built functionality to make REST calls to external services following certain actions (e.g. successfully storing an AIP). The Archidora Archivematica-Islandora integration, for example, makes use of this functionality to trigger actions in Islandora following the AIP storage event.  Since a RESTful endpoint is  supported in EPrints, this is the preferred way to send back the following information from Archivematica for each of the processed eprints:

* The UUID of the eprint in Archivematica

The Archivematica Storage Service will send back the AIP transfer folder name, which is the EPrintsArchivemticaDatasetID and the AM UUID using a CRUD callback (http://wiki.eprints.org/w/API:EPrints/Apache/CRUD). 

`curl -v -H "Content-Type: application/json;" -X PUT --data-binary "@/path/to/data.json" -u <username>:<password> http://myrepository.org/cgi/archivematica/set_uuid`

where 
```
<amid> = EPrintsArchivematicaDatasetID = transfer name = <package_name>
<uuid> = Archivematica Assigned UUID = <package_uuid>
```
and 
`/path/to/data.json` contains the JSON file with the `<amid>` and `<uuid>`:
```
{
"uuid": "<uuid>",
"amid": "<amid>"
} 
```
	
In the Archivematica Storage Service (https://www.archivematica.org/en/docs/storage-service-0.17/administrators/#administration), the Callback is defined under Administration > Edit Callback as follows:

```
Event: Post-store AIP
URI: [YOUR REPOSITORY URL]/cgi/archivematica/set_uuid
Method: POST
```

Headers (key/value):
```
Content-type: application/json
Authorization: Basic [encoded username:password]
```

Body: 
```
{
"uuid": "<package_uuid>",
"amid": "<package_name>"
} 
```
