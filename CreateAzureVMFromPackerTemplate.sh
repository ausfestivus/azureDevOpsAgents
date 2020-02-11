#!/usr/bin/env bash

# ##################################################
#
version="0.0.1"              # Sets version variable
#
# README:
# A bash script for building Azure DevOps Agent machines using Hashicorp Packer.
# https://packer.io/docs/builders/azure.html
#
# HISTORY:
#
# * 20200211 - v0.0.1  - First Creation
#
# TODO
# * setup tagging of packer resources per standard CPT tagging
# * fix all the FIXME
#
# ##################################################

function mainScript() {
  # invoke verbose usage when set
  if ${verbose}; then v="-v" ; fi

  # Helper Functions
  # ###################
  function displayVariables() {
    # variable dump for testing. #FIXME
    notice "Doing an environment variable dump."
    env | sort
  }

  function preflights() {
    # Preflight checks that must be successful for the script to run further. Checks are:
    # FIXME
    true
  }

  function buildVM() {
    true
    $vmSize = "Standard_DS2_v2"

  }

  # ###################
  # Run the script
  # ###################

# FIXME - remove or uncomment if needed.
#  # Ask for the administrator password upfront
#  echo "administrator authorisation required. Please enter your administrator password."
#  sudo -v
#
#  # Make sure we are signed into the app store
#  warning "You must be signed into the App Store for this script to work..."
#  warning "We will pause here while you go and do the sign in thing..."
#  read -n 1 -s -r -p "Press enter to continue"

#  checkTaps
#  brewCleanup
#  installHomebrewPackages
#  installCaskApps
#  installDevApps
  displayVariables
  preflights
  installSundry

}

## SET SCRIPTNAME VARIABLE ##
scriptName=$(basename "$0")

function trapCleanup() {
  # trapCleanup Function
  # -----------------------------------
  # Any actions that should be taken if the script is prematurely
  # exited.  Always call this function at the top of your script.
  # -----------------------------------
  echo ""
  # Delete temp files, if any
  if [[ -d "${tmpDir}" ]] ; then
    rm -r "${tmpDir}"
  fi
  die "Exit trapped."
}

function safeExit() {
  # safeExit
  # -----------------------------------
  # Non destructive exit for when script exits naturally.
  # Usage: Add this function at the end of every script.
  # -----------------------------------
  # Delete temp files, if any
  if [[ -d "${tmpDir}" ]] ; then
    rm -r "${tmpDir}"
  fi
  trap - INT TERM EXIT
  exit
}

function seek_confirmation() {
  # Asks questions of a user and then does something with the answer.
  # y/n are the only possible answers.
  #
  # USAGE:
  # seek_confirmation "Ask a question"
  # if is_confirmed; then
  #   some action
  # else
  #   some other action
  # fi
  #
  # Credt: https://github.com/kevva/dotfiles
  # ------------------------------------------------------

  input "$@"
  if ${force}; then
    notice "Forcing confirmation with '--force' flag set"
  else
    read -p " (y/n) " -n 1
    echo ""
  fi
}

function is_confirmed() {
  if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
    return 0
  fi
  return 1
}

function is_not_confirmed() {
  if [[ "${REPLY}" =~ ^[Nn]$ ]]; then
    return 0
  fi
  return 1
}

# Set Flags
# -----------------------------------
# Flags which can be overridden by user input.
# Default values are below
# -----------------------------------
quiet=false
printLog=false
verbose=false
force=false
strict=false
debug=false
args=()

# Set Temp Directory
# -----------------------------------
# Create temp directory with three random numbers and the process ID
# in the name.  This directory is removed automatically at exit.
# -----------------------------------
tmpDir="/tmp/${scriptName}.$RANDOM.$RANDOM.$RANDOM.$$"
(umask 077 && mkdir "${tmpDir}") || {
  die "Could not create temporary directory! Exiting."
}

# Logging
# -----------------------------------
# Log is only used when the '-l' flag is set.
#
# To never save a logfile change variable to '/dev/null'
# Save to Desktop use: $HOME/Desktop/${scriptName}.log
# Save to standard user log location use: $HOME/Library/Logs/${scriptName}.log
# -----------------------------------
logFile="${HOME}/Desktop/${scriptName}.log"


# Options and Usage
# -----------------------------------
# Print usage
usage() {
  echo -n "${scriptName} [OPTION]...

Creates an Azure VM from a template. Also generates network resources in Azure to make the VM accessible.
Based on https://github.com/actions/virtual-environments/blob/master/helpers/CreateAzureVMFromPackerTemplate.ps1

 ${bold}Options:${reset}

 Required Variables:

  -b | --SubscriptionId                 Azure Subscription ID to use.
  -g | --ResourceGroupName              Resource Group name to use.
  -t | --TemplateFilePath
  -n | --VirtualMachineName
  -u | --AdminUserName
  -p | --AdminPassword
  -r | --AzureLocation                  Azure Region to use in short hand notation. eg \"australiaeast\"

 Optional Variables:

  --force           Skip all user interaction.  Implied 'Yes' to all actions.
  -q, --quiet       Quiet (no output)
  -l, --log         Print log to file
  -s, --strict      Exit script with null variables.  i.e 'set -o nounset'
  -v, --verbose     Output more information. (Items echoed to 'verbose')
  -d, --debug       Runs script in BASH debug mode (set -x)
  -h, --help        Display this help and exit
      --version     Output version information and exit

 Example Usage:

 CreateAzureVMFromPackerTemplate.sh -SubscriptionId {YourSubscriptionId}  -ResourceGroupName {ResourceGroupName} -TemplateFile "C:\BuildVmImages\temporaryTemplate.json" -VirtualMachineName "testvm1" -AdminUsername "shady1" -AdminPassword "SomeSecurePassword1" -AzureLocation "australiaeast"


  "
}

# Iterate over options breaking -ab into -a -b when needed and --foo=bar into
# --foo bar
optstring=h
unset options
while (($#)); do
  case $1 in
      # If option is of type -ab
    -[!-]?*)
      # Loop over each character starting with the second
      for ((i=1; i < ${#1}; i++)); do
        c=${1:i:1}

        # Add current char to options
        options+=("-$c")

        # If option takes a required argument, and it's not the last char make
        # the rest of the string its argument
        if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
          options+=("${1:i+1}")
          break
        fi
      done
      ;;

      # If option is of type --foo=bar
    --?*=*) options+=("${1%%=*}" "${1#*=}") ;;
      # add --endopts for --
    --) options+=(--endopts) ;;
      # Otherwise, nothing special
    *) options+=("$1") ;;
  esac
  shift
done
set -- "${options[@]}"
unset options

# Print help if no arguments were passed.
# Uncomment to force arguments when invoking the script
# -------------------------------------
[[ $# -eq 0 ]] && set -- "--help"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) usage >&2; safeExit ;;
    --version) echo "$(basename $0) ${version}"; safeExit ;;
    -u|--username) shift; ADMINUSERNAME="${1}" ;;
    -p|--password) shift; echo "Enter the password you want to use on the VM: "; stty -echo; read ADMINPASSWORD; stty echo;
      echo ;;
    -b|--subscriptionid) shift; YOURSUBSCRIPTIONID="${1}" ;;
    -g|--resourcegroupname) shift; RGNAME="${1}" ;;
    -t|--TemplateFilePath) shift; TEMPLATEPATH="${1}" ;;
    -n|--VirtualMachineName) shift; VMNAME="${1}" ;;
    -r|--AzureLocation) shift; REGION="${1}" ;;
    -v|--verbose) verbose=true ;;
    -l|--log) printLog=true ;;
    -q|--quiet) quiet=true ;;
    -s|--strict) strict=true ;;
    -d|--debug) debug=true ;;
    --force) force=true ;;
    --endopts) shift; break ;;
    *)
        die "invalid option: '$1'." ;;
  esac
  shift
done

# Store the remaining part as arguments.
args+=("$@")


# Logging and Colors
# -----------------------------------------------------
# Here we set the colors for our script feedback.
# Example usage: success "sometext"
#------------------------------------------------------

# Set Colors
bold=$(tput bold)
reset=$(tput sgr0)
purple=$(tput setaf 171)
red=$(tput setaf 1)
green=$(tput setaf 76)
tan=$(tput setaf 3)
blue=$(tput setaf 38)
underline=$(tput sgr 0 1)

function _alert() {
  if [[ "${1}" = "emergency" ]]; then local color="${bold}${red}"; fi
  if [[ "${1}" = "error" ]]; then local color="${bold}${red}"; fi
  if [[ "${1}" = "warning" ]]; then local color="${red}"; fi
  if [[ "${1}" = "success" ]]; then local color="${green}"; fi
  if [[ "${1}" = "header" ]]; then local color="${bold}""${tan}"; fi
  if [[ "${1}" = "input" ]]; then local color="${bold}"; printLog="false"; fi
  if [[ "${1}" = "info" ]] || [[ "${1}" = "notice" ]]; then local color=""; fi
  # Don't use colors on pipes or non-recognized terminals
  if [[ "${TERM}" != "xterm"* ]] || [[ -t 1 ]]; then color=""; reset=""; fi

  # Print to $logFile
  if ${printLog}; then
    echo -e "$(date +"%m-%d-%Y %r") $(printf "[%9s]" "${1}") ${_message}" >> "${logFile}";
  fi

  # Print to console when script is not 'quiet'
  if ${quiet}; then
    return
  else
    echo -e "$(date +"%r") ${color}$(printf "[%9s]" "${1}") ${_message}${reset}";
  fi
}
function die ()       { local _message="${*} Exiting."; echo "$(_alert emergency)"; safeExit;}
function error ()     { local _message="${*}"; echo "$(_alert error)"; }
function warning ()   { local _message="${*}"; echo "$(_alert warning)"; }
function notice ()    { local _message="${*}"; echo "$(_alert notice)"; }
function info ()      { local _message="${*}"; echo "$(_alert info)"; }
function debug ()     { local _message="${*}"; echo "$(_alert debug)"; }
function success ()   { local _message="${*}"; echo "$(_alert success)"; }
function input()      { local _message="${*}"; echo -n "$(_alert input)"; }
function header()     { local _message="${*}"; echo "$(_alert header)"; }

# Log messages when verbose is set to "true"
verbose() { if ${verbose}; then debug "$@"; fi }

# Trap bad exits with your cleanup function
trap trapCleanup EXIT INT TERM

# Set IFS to preferred implementation
IFS=$' \n\t'

# Exit on error. Append '||true' when you run the script if you expect an error.
set -o errexit

# Run in debug mode, if set
if ${debug}; then set -x ; fi

# Exit on empty variable
if ${strict}; then set -o nounset ; fi

# Bash will remember & return the highest exitcode in a chain of pipes.
# This way you can catch the error in case mysqldump fails in `mysqldump |gzip`, for example.
set -o pipefail

# Run your script
mainScript

# Exit cleanly
safeExit
