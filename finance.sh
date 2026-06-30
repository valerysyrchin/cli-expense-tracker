#! /bin/bash

export PGPASSWORD='YOUR_DATABASE_PASSWORD'

PSQL="/c/Progra~1/PostgreSQL/18/bin/psql.exe --username=postgres --dbname=finance -t -A --no-align -c"

echo -e "\n~~~~~ EXPENCES TRACKER ~~~~~\n"

MAIN_MENU() {
    if [[ $1 ]]
    then
        echo -e "\n$1"
    fi

    echo "What would you like to do?" 
        echo -e "\n1. Insert an expense to database\n2. Edit an expense from database\n3. Analyze expenses\n4. Exit"
    read MAIN_MENU_SELECTION
    
    case $MAIN_MENU_SELECTION in
        1) INSERT_MENU ;;
        2) EDIT_MENU ;;
        3) ANALYZE_MENU ;;
        4) EXIT ;;
        *) MAIN_MENU "Please enter a valid option." ;;
    esac
}

INSERT_MENU() {

    # set terminal columns to 1 locally to force vertical layout for select menus
    local COLUMNS=1

    # select an expense category
    echo -e "\nWhich expense category?"

    # read query results into an array to properly handle category names with spaces
    readarray -t CATEGORIES < <($PSQL "select name from expense_categories order by expense_category_id" | tr -d '\r')
    PS3="Enter the number of category: "

    select item in "${CATEGORIES[@]}"
    do

        if [[ -n $item ]]
        then 
            echo "You selected: $item"
            CATEGORY_ID=$($PSQL "select expense_category_id from expense_categories where trim(name)=trim('$item')")
            break
        else
            echo "Invalid choice. Try again."
        fi
    done

    # select currency
    echo "Which currency?"
    readarray -t CURRENCIES < <($PSQL "select code from currencies order by currency_id" | tr -d '\r')
    PS3="Enter the currency: "

    select item in "${CURRENCIES[@]}"
    do
        if [[ -n $item ]]
        then 
            echo "You selected: $item"
            CURRENCY_ID=$($PSQL "select currency_id from currencies where trim(code)=trim('$item')")
            break
        else
            echo "Invalid choice. Try again."
        fi
    done
    
    # select transaction amount
    read -p "Enter expense amount: " EXPENSE_AMOUNT
    while [[ ! $EXPENSE_AMOUNT =~ ^[0-9]+$ ]]
    do
        read -p "Sorry, only numbers allowed. Try again: " EXPENSE_AMOUNT
    done
    echo "Expense amount has been set to $EXPENSE_AMOUNT"

    # select transaction date
    read -p "Use today's date? [Y/n]: " DATE_ANSWER
    if [[ -z $DATE_ANSWER || $DATE_ANSWER == "y" || $DATE_ANSWER == "Y" ]]
    then 
        EXPENSE_DATE=$(date +%Y-%m-%d)
        echo "Date automatically set to: $EXPENSE_DATE"
    else
        read -p "Enter date (YYYY-MM-DD): " EXPENSE_DATE
        while ! date -d "$EXPENSE_DATE" &>/dev/null 
        do
            read -p "Sorry, wrong data. Try again (YYYY-MM-DD): " EXPENSE_DATE
        done
    fi

    # select description (optional)
    read -p "Add description? [y/N]: " DESCRIPTION_ANSWER
    if [[ $DESCRIPTION_ANSWER == "y" || $DESCRIPTION_ANSWER == "Y" ]]
    then 
        read -p "Enter description: " USER_DESCRIPTION
        DESCRIPTION="'$USER_DESCRIPTION'"
        echo "Description has been added."
    else
        DESCRIPTION="NULL"
    fi

    # insert transaction to database
    INSERT_EXPENSE_RESULT=$($PSQL "insert into transactions(expense_category_id, currency_id, amount, transaction_date, description) values ($CATEGORY_ID, $CURRENCY_ID, $EXPENSE_AMOUNT, '$EXPENSE_DATE', $DESCRIPTION)")
    echo "Expense has been added to database."
}

EDIT_MENU() {
    MAIN_MENU "Sorry, this function is under development."
}

ANALYZE_MENU() {
    MAIN_MENU "Sorry, this function is under development."
}

EXIT() {
    echo -e "\nThank you, see you again!"
}

MAIN_MENU