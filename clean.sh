#!/bin/bash

function clean_setup() {
    rm -f   terraform.tfstate
    rm -f   terraform.tfstate.backup
    rm -rf  .terraform
    rm -rf  .terraform.lock.hcl
    rm -rf  terraform.tfstate.d
    rm -f   vars.tf
    rm -f   terraform.tfvars
}

clean_setup
