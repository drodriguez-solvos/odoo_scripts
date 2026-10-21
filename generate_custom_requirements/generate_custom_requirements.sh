#!/bin/bash

# ---------------------------------------------------------------------------

# Preparation script for Odoo Build

# 

# This script scans the './custom' folder looking for any

# 'requirements.txt' file belonging to custom addons.

# It then concatenates all found requirements into a single file

# named 'custom_requirements.txt' in the project root.

# 

# This master file will be the only one Docker copies and watches during

# the build, thus preserving the build cache if there are no real changes

# in the dependencies.

# ---------------------------------------------------------------------------



echo "Collecting custom addons dependencies..."



# Clear or create empty master file

> custom_requirements.txt



# Find all requirements.txt in the ./custom folder and concatenate them

# 'find' with '-exec cat' is used to dump the content safely.

find ./custom -name "requirements.txt" -type f -exec cat {} + >> custom_requirements.txt



# Sort alphabetically, remove duplicate lines and delete empty lines

# This ensures pip receives a clean list without conflicts.

sort -u custom_requirements.txt -o custom_requirements.txt

sed -i '/^$/d' custom_requirements.txt



echo "Dependencies successfully unified in custom_requirements.txt"