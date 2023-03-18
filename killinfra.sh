#!/bin/bash

# Adding Busy Indicator
busy_char="⣾⣽⣻⢿⡿⣟⣯⣷"

function busy() {
   local i=0
   while true; do
   echo -ne "${busy_char:$i:1}\r"
   i=$(( (i+1) % ${#busy_char} ))
   sleep 0.1
   done
}

echo "Warning: Deleting Infrastructure is permenant loss of entire setup....."
read -p "Do you want to delete the Infrastructure? type 'yes' for final confirmation or press any key to exit: " answer

# start displaying busy animation
start_time=$(date +%s)
busy &

# perform tasks

if [ "$answer" == "yes" ]; then
   echo "deleting infrastructure....."
   TF_BIN=`which terraform`
   TF_OUTPUT=$($TF_BIN destroy -auto-approve)
   if (echo "$TF_OUTPUT" | grep -q "Error:";) then
      echo "Terraform failed to destroy Infra!"
      echo "$TF_OUTPUT"
      exit 1 # Unsuccessfull Termination of the Program
   else
      rm -f terraform.tfvars
      rm -f vars.tf
   fi
else
  echo "No changes made....."
fi

# stop displaying busy animation
kill $! 2>/dev/null
echo -ne "\r\n"

end_time=$(date +%s)
elapsed_time=$(($end_time - $start_time))
echo "Finished in ${elapsed_time}s"
