#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~"
echo -e "\nWelcome to My Salon, how can I help you?\n"

MAIN_MENU() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  # Get and display available services
  AVAILABLE_SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
  echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR NAME
  do
    echo "$SERVICE_ID) $NAME"
  done

  # Read user input
  read SERVICE_ID_SELECTED

  # Check if input is a valid number
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    # Send back to main menu
    MAIN_MENU "I could not find that service. What would you like today?"
  else
    # Check if the service exists in the database
    SERVICE_AVAILABILITY=$($PSQL "SELECT service_id FROM services WHERE service_id = $SERVICE_ID_SELECTED")
    
    if [[ -z $SERVICE_AVAILABILITY ]]
    then
      # Send back to main menu if service doesn't exist
      MAIN_MENU "I could not find that service. What would you like today?"
    else
      # Prompt for phone number
      echo -e "\nWhat's your phone number?"
      read CUSTOMER_PHONE

      # Check if customer exists
      CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
      
      if [[ -z $CUSTOMER_NAME ]]
      then
        # If not, prompt for name and insert into database
        echo -e "\nI don't have a record for that phone number, what's your name?"
        read CUSTOMER_NAME
        INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
      else
        # Remove leading/trailing spaces from database query result
        CUSTOMER_NAME=$(echo $CUSTOMER_NAME | sed -E 's/^ *| *$//g')
      fi
      
      # Fetch the service name and remove spaces for output
      SERVICE_NAME=$(echo $($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED") | sed -E 's/^ *| *$//g')
      
      # Prompt for time
      echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
      read SERVICE_TIME

      # Fetch the customer's ID
      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")

      # Insert the appointment
      INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

      # Final confirmation message
      echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
    fi
  fi
}

MAIN_MENU