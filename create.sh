#!/bin/bash

# Declaration
terraform_action=("init" "validate" "plan" "apply -auto-approve")
terraform_action_instruction=("Initiating....." "Validating....." "Planning & Previewing....." "Setting Up Infra.....")
terraform_error_message=("Error: Terraform Initiating failed. Exiting script..." "Error: Terraform validating failed. Exiting script..." "Error: Terraform Planning & Previewing failed. Exiting script..." "Error: Terraform Setting Up Infra failed. Exiting script...")

short_project_name=""


# Adding Busy Indicator
busy_char="⣾⣽⣻⢿⡿⣟⣯⣷"

function busy() {
   local i=0
   while true; do
   # echo $(($(date +%s%N)/1000000))
   echo -ne "${busy_char:$i:1} :- $(($(date +%s%N)/1000000))\r"
   i=$(( (i+1) % ${#busy_char} ))
   sleep 0.1
   done
}

# Reusing Functions
function run_terraform() {
   TF_BIN=`which terraform`
   
   for ((i=0; i<${#terraform_action[@]}; i++)); do
      echo ${terraform_action_instruction[i]}
      TF_OUTPUT=$($TF_BIN ${terraform_action[i]})
      if [ $? -ne 0 ] ; then
         echo ${terraform_error_message[i]}
         kill $! 2>/dev/null
         exit 1
      fi
   done
}

if ! command -v terraform  >/dev/null 2>&1 ; then
   echo "Terraform not found; installing..."
   wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install -y terraform
fi

filename="variables.tf"

if [ ! -f $filename ]; then
  read -p "Enter AWS Accesss Key: " aws_access_key
  read -p "Enter AWS Secret Key: " aws_secret_key
  read -p "Enter Region [ap-south-1]: " region

  read -p "Enter Unique Project Name in short (Only lowercase alpha numeric allowed): " short_project_name

  read -p "Enter Instance Family [t3.small]: " instance_type
  read -p "Specify the desired number of nodes required at any point of time [1]: " desired_size
  read -p "Specify the maximum number of nodes to be used [1]: " max_size
  read -p "Specify Minimum number of nodes to be running at all time [1]: " min_size

  echo 'variable access_key {}' > vars.tf
  echo 'variable secret_key {}' >> vars.tf
  echo "variable region {}" >> vars.tf
  
  echo "variable short_project_name  {}" >> vars.tf
  
  echo 'variable instance_types {}' >> vars.tf
  echo 'variable desired_size {}' >> vars.tf
  echo 'variable max_size {}' >> vars.tf
  echo 'variable min_size {}' >> vars.tf

   echo '' >> vars.tf
   echo "variable vpc_main_cidrblk {}" >> vars.tf
   echo "variable cidr_private_subnet1 {}" >> vars.tf
   echo "variable cidr_private_subnet2 {}" >> vars.tf
   echo "variable cidr_public_subnet1 {}" >> vars.tf
   echo "variable cidr_public_subnet2 {}" >> vars.tf
   echo "variable environment {}" >> vars.tf

  echo 'secret_key="'${aws_secret_key}'"' > terraform.tfvars
  echo 'access_key="'${aws_access_key}'"' >> terraform.tfvars
  if [ "${region:-}" == "" ]; then
   region="ap-south-1"
  fi
  echo 'region="'${region}'"' >> terraform.tfvars


  echo 'short_project_name="'${short_project_name}'"' >> terraform.tfvars

  if [ "${instance_type:-}" == "" ]; then
   instance_type="t3.small"
  fi 
  echo 'instance_types="'${instance_type}'"' >> terraform.tfvars

  if [ "${desired_size:-}" == "" ]; then
   desired_size="1"
  fi 
  echo 'desired_size="'${desired_size}'"' >> terraform.tfvars

  if [ "${max_size:-}" == "" ]; then
   max_size="1"
  fi 
  echo 'max_size="'${max_size}'"' >> terraform.tfvars

  if [ "${min_size:-}" == "" ]; then
   min_size="1"
  fi 
  echo 'min_size="'${min_size}'"' >> terraform.tfvars

   echo  >> terraform.tfvars
   echo "environment=\"Dev\"" >> terraform.tfvars

   echo "vpc_main_cidrblk=\"12.0.0.0/16\"" >> terraform.tfvars

   echo "cidr_private_subnet1=\"12.0.1.0/24\"" >> terraform.tfvars
   echo "cidr_private_subnet2=\"12.0.2.0/24\"" >> terraform.tfvars

   echo "cidr_public_subnet1=\"12.0.3.0/24\"" >> terraform.tfvars
   echo "cidr_public_subnet2=\"12.0.4.0/24\"" >> terraform.tfvars

fi

# start displaying busy animation
start_time=$(date +%s)
busy &

# perform tasks
# Calling the Function
MESSAGE="EC2 Instance with Custom User"
echo "Setting of $MESSAGE..."
run_terraform

#stop displaying busy animation
kill $! 2>/dev/null
echo -ne "\r\n"

end_time=$(date +%s)
elapsed_time=$(($end_time - $start_time))
echo "$MESSAGE created in ${elapsed_time}s. "
