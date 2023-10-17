# Overview

This directory contains configurations and utilities for setting up AWS infrastructure required
for a devops implimentation.

The main configuration file is the environment_vars.sh file. This is a BASH file containing
variables which will be used in the provisioning / configuring process.

Variables with the TF_VAR_ prefix will be consumed by the terraform relate utilities.
