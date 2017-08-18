The scripts up5h.sh  and up12h.sh to setup Apigee Edge Private Cloud version 16.x and 17.x

[1] Installation 

-Preparation

Please add the files on the same directory where the scripts exist

1. license file
2. ConfigFile(s) (for components setup as described on OPDK Installation Guide)
3. ConfigFileOrg (for organization and user setup as described on OPDK Installation Guide)


- Running commands

On Mac/Linux terminal

- Commandline arguments
# arg1: instnace name: ex. edge-1705
# arg2: OPDK version: ex. 4.17.05
# arg3: apigee-ftp user  
# arg4: apigee-ftp password

The usage example of this script is:

- For 5-host profile setup,
./up5h.sh edge-1705 4.17.05 user password

- For 12-host profile,
./up12h.sh edge-1705 4.17.05 user password

[2] Stop/Restart/Remove all the instances

# arg1: instnace name: ex. edge-1705
# arg2: status to change: ex. stop/restart/remove

- For 5-host and 12-hots profiles,
./sc5h.sh edge-1705 stop|restart|remove
./sc12h.sh edge-1705 stop|restart|remove


Note: GCP users with free of charrge can only create instances up to 8.
So, the 5-host profile only is available for the case.
 

