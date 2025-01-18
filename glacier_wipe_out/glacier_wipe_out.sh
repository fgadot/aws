#!/bin/bash

# AWS GLACIER WIPE OUT
# 2024.04.18 - VERSION 1.0
# Made by Frank Gadot <fgadot@icloud.com>
# This script totally wipes out ALL of your AWS GLACIER Vaults




# Define color variables
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
GRAY='\033[1;37m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

accountID=""
totalNumberOfVaults=0
vault=()
jobID=()
statusCode=()
numberOfArchives=()

function presentation() {
  for (( i = 0; i < 5; i++ )); do
    echo -e "\n"
  done
  echo -e "${YELLOW}****************************"
  echo -e "${YELLOW}*** AWS GLACIER Wipe out ***"
  echo -e "${YELLOW}****************************"
}


# Check for AWS CLI
function check_aws_cli() {
  echo -ne "${CYAN}* Checking for AWS CLI: "
  if command -v aws &>/dev/null; then
      echo -e "${GREEN}installed."
  else
      echo -e "${RED}not installed. ${CYAN}"
      echo -e "${YELLOW}Please install it before proceeding.\n See https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html\n\n"
      exit 1
  fi
}

# Prompt user for account ID and make sure it is numbers only
function prompt_account_id() {
  # Check if a file accountid exist
  if [ -f "accountid" ]; then
      accountID=$(grep -oE '[0-9]{12}' "accountid")

      # Check if there is a value in it
      if [ -n "$accountID" ]; then
          echo -e "${GREEN}* Account ID read from file: ${YELLOW}$accountID"
      else
          echo -e "{RED}* No account ID found in the file. Either delete the file, or enter a single line with your AWS Account ID"
          exit 1
      fi
  else
    while true; do
    echo -en "\n${GREEN}* Enter your account ID (digits only): "
    read -r input_account_id
    if [[ $input_account_id =~ ^[0-9]+$ ]]; then
        accountID="$input_account_id"
        break
    else
        echo -e "${RED}Error: Account ID must contain only digits.\n"
    fi
  done

  fi
}


function list_vaults()
{
  # dump all vaults in a file
  aws glacier list-vaults --account-id "${accountID}" | grep -v VaultList > all_vaults.tmp

  # Let's figure out the total number of vaults
  totalNumberOfVaults=$(grep VaultName all_vaults.tmp | wc | awk "{print $1}")
  echo -ne "${CYAN}* Found ${totalNumberOfVaults} vault"
if [[ $totalNumberOfVaults -eq 1 ]]; then
    echo -e "${CYAN}s."
  else
    echo -e "${CYAN}."
  fi

  # Let's create an array with all the vault names
  counter=0
  while read -r line; do
      if [[ $(echo "$line"|grep -i vaultname) ]]; then
          vault[++counter]=$(echo "$line"|grep -i vaultname|awk '{print $2}')
          echo -e "${CYAN}* VaultName[${counter}]: ${MAGENTA} ${vault[counter]}"
      fi
  	done < all_vaults.tmp
}


function initiate_job() {
  echo ""
  for ((counter=1; counter <= totalNumberOfVaults; counter++)); do
    echo -e "${CYAN}* Initiating job request for vault ${MAGENTA}${vault[counter]}"
    aws glacier initiate-job --vault-name "${vault[counter]}" --account-id "${accountID}" --job-parameters="{\"Type\":\"inventory-retrieval\"}" > job-${counter}.tmp
  done
}


function check_job_completion() {
  echo ""
  for ((counter=1; counter<= totalNumberOfVaults; counter++)); do
    # Grab the jobID
    echo -ne "${CYAN}* Grabbing jobID for VAULT [${counter}]: "
    jobID[counter]=$(grep jobId job-${counter}.tmp|awk "{print $2}")
    echo -e "${MAGENTA}${jobID[counter]}"
  done

  # Now let's wait for the jobs to complete their inventories
  echo -e "\n\n"
  echo -e "${WHITE}* Now let's wait until all inventory retrieval jobs are done."
  echo -e "${WHITE}* This could take a LONG time depending on how much archive you have. ${YELLOW}Minutes, hours, or even days..."
  echo -e "${WHITE}* I will check the results every 10 minutes. ${RED}** DO NOT STOP THIS SCRIPT, OR CLOSE THIS TERMINAL WINDOW **"
  echo -e "${RED}\t\t --= BE VERY VERY PATIENT =--\n"

  COMPLETED=0
  # We grab each statusCode
  echo -e "\n${WHITE}* Checking at $(date)"
  while [[ COMPLETED -eq 0 ]]; do
    for ((counter=1; counter <= totalNumberOfVaults; counter++)); do
      statusCode[counter]=$(aws glacier describe-job --vault-name "${vault[counter]}" --account-id "${accountID}" --job-id "${jobID[counter]}" | grep StatusCode | awk '{print $2}')
      echo -e "${CYAN}* Checking VAULT ${counter}: ${statusCode[counter]}"
    done

    # We check if any of them is still InProgress
    temp=0
    for ((counter=1; counter <= totalNumberOfVaults; counter++)); do
      if [[ ${statusCode[counter]} != "InProgress" ]]; then
        temp=$((temp + 1))
      fi
    done

    # If they are all done, then we out!
    if [[ $temp -eq $totalNumberOfVaults ]]; then
      break;
    fi

    # If not, we keep wait a minute and roll again.
    echo -e "${GRAY}* Sleeping for 10 minutes..."
    sleep 600
    echo -e "\n${WHITE}* Checking at $(date)"
  done
}


function ETA() {
  # Compute total seconds, multiply by 0.8, using awk for floating point calculations
  total_seconds=$(awk "BEGIN {print int($1 * 0.8 + 0.999999)}")  # Adding just below 1 to round up.

  # Now convert seconds into weeks, days, hours, minutes
  weeks=$((total_seconds / 604800))
  remaining_seconds=$((total_seconds % 604800))

  days=$((remaining_seconds / 86400))
  remaining_seconds=$((remaining_seconds % 86400))

  hours=$((remaining_seconds / 3600))
  remaining_seconds=$((remaining_seconds % 3600))

  minutes=$((remaining_seconds / 60))
  remaining_seconds=$((remaining_seconds % 60))

  # If there are any remaining seconds, bump the minutes count by one
  if [[ $remaining_seconds -gt 0 ]]; then
      minutes=$((minutes + 1))
  fi

  # Adjust for overflow of minutes into hours, hours into days, etc.
  if [[ $minutes -ge 60 ]]; then
      hours=$((hours + 1))
      minutes=$((minutes - 60))
  fi

  if [[ $hours -ge 24 ]]; then
      days=$((days + 1))
      hours=$((hours - 24))
  fi

  if [[ $days -ge 7 ]]; then
      weeks=$((weeks + 1))
      days=$((days - 7))
  fi

  echo -e "${YELLOW}* Total estimated time: $weeks weeks, $days days, $hours hours, $minutes minutes"
  sleep 2
}


function read_job() {
  echo ""
  echo -e "${WHITE}* I'm now going to read the job outputs, and clean the JSON files..."
  for ((counter=1; counter <= totalNumberOfVaults; counter++)); do
    echo -e "${CYAN}* Getting ArchiveID for VAULT ${MAGENTA}${vault[counter]}"
    aws glacier get-job-output --vault-name "${vault[counter]}" --account-id "${accountID}" --job-id "${jobID[counter]}" archiveID-"${counter}".tmp > /dev/null

    numberOfArchives[counter]=$(grep -o ArchiveId archiveID-${counter}.tmp | wc | awk '{print $1}')
    echo -e "${CYAN}* Number of archives: ${GREEN}${numberOfArchives[counter]}"
    if [[ numberOfArchives[counter] -gt 0 ]]; then
      ETA numberOfArchives[counter]
    elif [[ numberOfArchives[counter] -eq 0 ]]; then
      echo -e "${YELLOW}* Nothing to delete here."
    fi

    # Let's clean up the JSON output
    echo -e "${CYAN}* Cleaning up JSON Output for archiveID-${counter}.tmp into cleanArchiveID-${counter}.tmp"
    tr ',' '\n' < archiveID-${counter}.tmp | sed 's/}/}\n/g' > cleanArchiveID-${counter}.json
    echo ""
  done

  echo -e "${WHITE}* STARTING DELETION IN 5 Seconds..."
  sleep 5
}

function delete_archives() {
  echo ""
  echo -e "${WHITE}* Starting deletion process. This might take a massive amount of time too (0.8 second/archive). ${RED}**BE PATIENT**"

  # And off we go...
  for ((counter=1; counter <= totalNumberOfVaults; counter++)); do

     if [ ! -s "cleanArchiveID-${counter}.json" ] || ! grep -q "ArchiveId" "cleanArchiveID-${counter}.json"; then
        echo -e "${RED}* No archives found to delete in VAULT ${counter}."
        continue
    fi

    cat "cleanArchiveID-${counter}.json" | sed -n 's/.*"ArchiveId":"\([^"]*\).*/\1/p' | while IFS= read -r archiveId; do
      echo -e "${CYAN}* Deleting ArchiveID ${MAGENTA}${archiveId} ${WHITE}from ${MAGENTA}VAULT ${counter}"
      aws glacier delete-archive --vault-name "${vault[counter]}" --account-id "${accountID}" --archive-id "\"${archiveId}\""
    done
  done
}


function delete_vaults () {
  echo ""
  echo -e "${WHITE}* Deleting VAULTS"

  for ((counter=1; counter <= totalNumberOfVaults; counter++)); do
    echo -e "${CYAN}"* Deleting VAULT "${counter}" / "${vault[counter]}"
    aws glacier delete-vault --vault-name "${vault[counter]}" --account-id "${accountID}"
  done

  echo -e "${WHITE}* ALL DONE  ** Thank you for using this script. ** Feedback appreciated - fgadot@icloud.com\n\n\n${NC}"
}


###########
# M A I N #
###########
tput setab 0
presentation
check_aws_cli
prompt_account_id
list_vaults
initiate_job
check_job_completion
read_job
delete_archives
delete_vaults
tput sgr0
