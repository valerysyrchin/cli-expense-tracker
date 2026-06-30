#! /bin/bash

# postgreSQL connection path and flags
export PGPASSWORD='YOUR_DATABASE_PASSWORD'

PSQL="/c/Progra~1/PostgreSQL/18/bin/psql.exe --username=postgres --dbname=finance -t -c"

# fetch current currency rates with USD as base in JSON format (v2 API)
RESPONSE=$(curl -s "https://api.frankfurter.dev/v2/rates?base=USD")

# extract the rate date from the first element of the JSON array
RATE_DATE=$(echo "$RESPONSE" | jq -r '.[0].date')

# check if we already have any records for this date in the database
DATE_CHECK=$($PSQL "select count(*) from currency_rates where rate_date = '$RATE_DATE'")
DATE_CHECK=$(echo "$DATE_CHECK" | sed -r 's/^ *| *\r?$//g')

# if the count is greater than 0, stop the script
if [[ $DATE_CHECK -gt 0 ]]
then
    echo "Sorry, rates for $RATE_DATE have already been inserted!"
    exit 0
fi

# get the unique currency_id for the base currency (USD) from the database
USD_ID=$($PSQL "select currency_id from currencies where code = 'USD'")

# fetch the list of all currency codes currently registered in the database
CODE_LIST=$($PSQL "select code from currencies")

# loop through each currency code from the list
echo "$CODE_LIST" | while read -r CODE
do
    CODE=$(echo "$CODE" | sed -r 's/^ *| *\r?$//g')
    # get currency id for the current code from the database
    CURRENCY_ID=$($PSQL "select currency_id from currencies where code = '$CODE'")
    # determine the conversion rate to USD
    if [[ $CODE == 'USD' ]]
    then
        # the rate for USD to itself is always 1
        CURRENCY_RATE='1'
    else 
        # for other currencies, find the matching object in the JSON array and extract its rate
        CURRENCY_RATE=$(echo "$RESPONSE" | jq --arg c "$CODE" '.[] | select(.quote == $c) | .rate')
    fi
    # insert currency_id, rate and date into the currency_rates table
    INSERT_RATE_RESULT=$($PSQL "insert into currency_rates(from_currency_id, to_currency_id, rate, rate_date) values('$USD_ID', '$CURRENCY_ID', '$CURRENCY_RATE', '$RATE_DATE')")
    # check if the insert was successful
    if [[ $INSERT_RATE_RESULT == "INSERT 0 1" ]]
    then 
        echo "USD rate to $CODE has been inserted to database for $RATE_DATE"
    fi
done

echo "All rates for $RATE_DATE have been inserted to database"




