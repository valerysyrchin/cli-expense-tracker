#! /bin/bash

# Load your secret variables from the local .env file (if it exists)
[ -f .env ] && source .env

# Set default values if they weren't loaded from the .env file

DB_USER=${DB_USER:-postgres}
DB_NAME=${DB_NAME:-finance}
DB_PASSWORD=${DB_PASSWORD:-""}

# Export the password so psql can use it automatically

export PGPASSWORD=$DB_PASSWORD

# Universal psql command shortcut

PSQL=${PSQL:-"psql --username=$DB_USER --dbname=$DB_NAME -t -A --no-align -c"}

# Fetch current currency rates with USD as base in JSON format (v2 API)
RESPONSE=$(curl -s "https://api.frankfurter.dev/v2/rates?base=USD")

# Extract the rate date from the first element of the JSON array
RATE_DATE=$(echo "$RESPONSE" | jq -r '.[0].date')

# Check if we already have any records for this date in the database
DATE_CHECK=$($PSQL "select count(*) from currency_rates where rate_date = '$RATE_DATE'")
DATE_CHECK=$(echo "$DATE_CHECK" | sed -r 's/^ *| *\r?$//g')

# If the count is greater than 0, stop the script
if [[ $DATE_CHECK -gt 0 ]]
then
    echo "Sorry, rates for $RATE_DATE have already been inserted!"
    exit 0
fi

# Get the unique currency_id for the base currency (USD) from the database
USD_ID=$($PSQL "select currency_id from currencies where code = 'USD'")

# Fetch the list of all currency codes currently registered in the database
CODE_LIST=$($PSQL "select code from currencies")

# Loop through each currency code from the list
echo "$CODE_LIST" | while read -r CODE
do
    CODE=$(echo "$CODE" | sed -r 's/^ *| *\r?$//g')
    # Get currency id for the current code from the database
    CURRENCY_ID=$($PSQL "select currency_id from currencies where code = '$CODE'")
    # Determine the conversion rate to USD
    if [[ $CODE == 'USD' ]]
    then
        # The rate for USD to itself is always 1
        CURRENCY_RATE='1'
    else 
        # For other currencies, find the matching object in the JSON array and extract its rate
        CURRENCY_RATE=$(echo "$RESPONSE" | jq --arg c "$CODE" '.[] | select(.quote == $c) | .rate')
    fi
    # Insert currency_id, rate and date into the currency_rates table
    INSERT_RATE_RESULT=$($PSQL "insert into currency_rates(from_currency_id, to_currency_id, rate, rate_date) values('$USD_ID', '$CURRENCY_ID', '$CURRENCY_RATE', '$RATE_DATE')")
    # Check if the insert was successful
    if [[ $INSERT_RATE_RESULT == "INSERT 0 1" ]]
    then 
        echo "USD rate to $CODE has been inserted to database for $RATE_DATE"
    fi
done

echo "All rates for $RATE_DATE have been inserted to database"




