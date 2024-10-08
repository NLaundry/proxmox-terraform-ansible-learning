#!/bin/bash

# Run Terraform commands
terraform init
terraform apply -var-file="test.tfvars"
