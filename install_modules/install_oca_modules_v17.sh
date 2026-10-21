#!/bin/bash
BRANCH="17.0"
BASE="https://github.com/OCA"

REPOS=(
  account-analytic
  account-financial-reporting
  account-financial-tools
  account-invoice-reporting
  account-invoicing
  account-payment
  account-reconcile
  bank-payment
  bank-statement-import
  calendar
  community-data-files
  contract
  crm
  edi
  edi-framework
  helpdesk
  hr
  hr-attendance
  hr-expense
  hr-holidays
  l10n-spain
  mis-builder
  payroll
  project
  project-reporting
  reporting-engine
  server-tools
  server-ux
  stock-logistics-workflow
  web
)

for repo in "${REPOS[@]}"; do
  git clone -b "$BRANCH" --single-branch --depth 1 "$BASE/$repo.git"
done

# --single-branch --depth 1 descarga solo la rama que se indica en BRANCH y el último commit, lo que acelera mucho el clonado y ahorra espacio (importante en repos grandes como l10n-spain o server-tools). Si necesitas el historial completo, quita --depth 1.