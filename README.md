# README #

This README describes how to run the scripts for the install/manage of Edge PrivateCloud (OPDK) version 4.17.x and 4.16.x on GCP Compute Engine (GCE) instances.

### What is this repository for? ###

* Installing OPDK 17.x/16.x on GCP instances 
* ver. 0.1

### How do I get set up? ###

The scripts ***setup5h.sh***  and ***setup12h.sh*** to setup Apigee Edge Private Cloud version 16.x and 17.x respectively.

##[1] Installation 

### Preparation
- First you need to setup GCP account and prepare it as to run wiht gcloud commands on the terminal of Mac, Linux or Bash on Windows.
- https://cloud.google.com/sdk/docs/quickstarts
- Then please add the following files on the same directory where the scripts exist.

1. license file (***license.txt*** fixed for the file name - modify scripts as needed)
2. configFile (as described on OPDK Installation Guide, ***configFile*** for 5-host and ***configFile-D1***, ***configFile-D2*** for 12-host)
3. configFileOrg (as described on OPDK Installation Guide, ***configFileOrg*** fixed)

### Running commands on Mac/Linux terminal

Command: ***setup5h.sh***, ***setup12h.sh***

Arguments:

- arg1: GCE instnace name: ex. edge-1705
- arg2: OPDK version: ex. 4.17.05
- arg3: apigee-ftp user: {user} as provided
- arg4: apigee-ftp password: {password} as provided

The usage example of this script is:

**For 5-host profile:**

*./setup5h.sh edge-1705 4.17.05 {user} {password}*

**For 12-host profile:**

*./setup12h.sh edge-1705 4.17.05 {user} {password}*

##[2] Stop/Restart/Remove all the Edge components on GCE instances

Command: ***state.sh***

Arguments:

- arg1: instnace name: ex. edge-1705
- arg2: number of the instances according to the profile: ex. 5 
- arg3: state of the GCE instances changed to: ex. stop/restart/remove

**For 5-host and 12-host profiles:**

*./state.sh edge-1705 5 stop|restart|remove*

**Note**: GCP users with free of charge can create new GCE instances up to 8 instances.
So, the 5-host profile only is available for free accounts.
