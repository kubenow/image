#!/bin/bash

# GENERAL IDEA:
#
# We want to make sure that every time security updates are issued,
# then building of a new kubenow image release is triggered.
# Perhaps running a daily or weekly cron job could be the best frequence.

# Exit immediately if a command exits with a non-zero status
set -e

# Update repos and make a dry run for unattended-upgrades to evaluate whether
# there are new security updates
sudo apt-get update -q
echo -e "Executing a dry-run for unattended-upgrades...\n"
upgrades_status=$(sudo unattended-upgrades --dry-run -d | grep "All upgrades installed" | tee dry-run_log.txt)

# Check unattended-upgrade output to evaluate if any updates are available
if [ -z "$upgrades_status" ]; then
  echo -e "No packages found that can be upgraded unattended and no pending auto-removals\n"

elif [ -n "$upgrades_status" ] && [ "$upgrades_status" == "All upgrades installed" ]; then
  echo -e "\nNew Security Updates Are Available. Proceeding to install them...\n"
  sudo unattended-upgrades

else
  echo -e "Something went wrong while checking wheter unattended upgrades are available or not. Manual intervention is required.\n"

fi
