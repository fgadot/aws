# glacier_wipe_out
 AWS GLACIER wipe out

Problem:
It is impossible to connect to your AWS Account and delete all Glacier Vaults.
You need to go into each vault through the AWS API, delete all archives, then delete the vaults themselves. 

Resolution:
This script allows you to wipe out your entire GLACIER hierarchy.

This bash script was made on macOS, and most likely will work on any Linux-like Operating System.
This script should have executable rights. It's not bullet proof, but worked for me (5 Vaults, 1Billion+ items, 10Tb)
<br><br><br>

#### 2024.04.18 - V1.0
- Initial script

<br><br><br>
## Instructions
- You need to have AWS CLI Installed and configured (see link at the bottom)<br>
- Download the script to your computer<br>
- Launch a terminal<br>
- Make sure the script has execute rights (**chmod 700 glacier_wipe_out.sh**)<br>
- OPTION: Add a file **accountid** with your amazon account ID in it (single line) - If the file is not present, the script will ask you for your AWS Account ID<br>
- Run the script **./glacier_wipe_out.sh** and wait. **BE PATIENT.** Everything will be explained on the screen. 

<br><br><br>
### AWS DOCUMENTATION
- **AWS CLI** https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html <br>
- **AWS GLACIER - ARCHIVE DELETION CLI** https://docs.aws.amazon.com/amazonglacier/latest/dev/deleting-an-archive-using-cli.html <br>
- **AWS GLACIER - VAULT DELETION CLI** https://docs.aws.amazon.com/cli/latest/reference/glacier/delete-vault.html

<br><br><br>
If you have any request or issue with this script, please create a issue request.