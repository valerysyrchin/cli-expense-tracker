#! /bin/bash

# load your secret variables from the local .env file (if it exists)
[ -f .env ] && source .env

# set default values if they weren't loaded from the .env file

DB_USER=${DB_USER:-postgres}
DB_NAME=${DB_NAME:-finance}
DB_PASSWORD=${DB_PASSWORD:-""}

# export the password so psql can use it automatically

export PGPASSWORD=$DB_PASSWORD

# universal psql command shortcut

PSQL=${PSQL:-"psql --username=$DB_USER --dbname=$DB_NAME -t -A --no-align -c"}

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
    
    MAIN_MENU "Expense has been added to database."
}

EDIT_MENU() {

    # set terminal columns to 1 locally to force vertical layout for select menus
    local COLUMNS=1

    if [[ -n $1 ]]
    then
        echo -e "$1"
    fi

    echo "How would you like to find an expense for editing?" 
        echo -e "\n1. By category\n2. By date\n3. By currency\n4. By description\n5. Go back to main menu"
    read EDIT_MENU_SELECTION

    case $EDIT_MENU_SELECTION in
        1) FIND_EXPENSE "category" "Enter category name: " ;;
        2) FIND_EXPENSE "date" "Enter date (YYYY-MM-DD): " ;;
        3) FIND_EXPENSE "currency" "Enter currency (USD, EUR, RUB...): " ;;
        4) FIND_EXPENSE "description" "Enter search word for description: " ;;
        5) MAIN_MENU ;;
        *) EDIT_MENU "Please enter a valid option." ;;
    esac
}

FIND_EXPENSE(){
    local WHERE_CLAUSE=""

    case $1 in
        "category") 
            echo -e "\nSelect a category to filter expenses:"
    
            readarray -t CATEGORIES < <($PSQL "select name from expense_categories order by expense_category_id" | tr -d '\r')
            
            local OLD_PS3=$PS3
            PS3="Enter the number of category: "

            select cat_item in "${CATEGORIES[@]}"
            do
                if [[ -n $cat_item ]]
                then
                    WHERE_CLAUSE="where expense_categories.name = '$cat_item'"
                    break
                else
                    echo "Invalid choice. Try again."
                fi
            done
            PS3=$OLD_PS3
            ;;

        "date")     
            read -p "$2" SEARCH_VALUE
            WHERE_CLAUSE="where transactions.transaction_date = '$SEARCH_VALUE'" 
            ;;
        "currency") 
            read -p "$2" SEARCH_VALUE
            WHERE_CLAUSE="where currencies.code ilike '%$SEARCH_VALUE%'" 
            ;;
        "description") 
            read -p "$2" SEARCH_VALUE
            WHERE_CLAUSE="where transactions.description ilike '%$SEARCH_VALUE%'" 
            ;;
    esac

    QUERY="
    select 
        transactions.transaction_id || ';' || 
        transactions.transaction_date || ';' || 
        expense_categories.name || ';' || 
        round(transactions.amount) || ' ' || currencies.code || ';' || 
        coalesce(transactions.description, '')
    from transactions
    join expense_categories on transactions.expense_category_id = expense_categories.expense_category_id
    join currencies on transactions.currency_id = currencies.currency_id
    $WHERE_CLAUSE
    order by transactions.transaction_date desc;"

    # read the query results into an array
    readarray -t RAW_DATA < <($PSQL "$QUERY" | tr -d '\r')

    # check if the array is empty
    if [[ ${#RAW_DATA[@]} -eq 0 ]]
    then
        EDIT_MENU "\nNo expenses found matching your criteria."
        return
    fi

    echo -e "\nSelect the expense you want to edit:"

    {
    echo "NUM;ID;DATE;CATEGORY;AMOUNT;DESCRIPTION"
    echo "---;--;----;--------;------;-----------"
    
    INDEX=1

    for row in "${RAW_DATA[@]}"; do
        echo "[$INDEX];$row"
        ((INDEX++))
    done
    } | column -t -s ';' 

    echo ""

    while true; do

        read -p "Enter the number of transaction (1-${#RAW_DATA[@]}): " CHOSEN_NUM 
        if [[ "$CHOSEN_NUM" =~ ^[0-9]+$ ]] && [ "$CHOSEN_NUM" -ge 1 ] && [ "$CHOSEN_NUM" -le "${#RAW_DATA[@]}" ]; then
            SELECTED_ROW="${RAW_DATA[$((CHOSEN_NUM-1))]}"
            CHOSEN_ID=$(echo "$SELECTED_ROW" | cut -d';' -f1)
            UPDATE_EXPENSE_MENU "$CHOSEN_ID"
            break
        else
            echo "Invalid number. Please look at the [NUM] column."
        fi
    done
}

ANALYZE_MENU() {
    MAIN_MENU "Sorry, this function is under development."
}

EXIT() {
    echo -e "\nThank you, see you again!"
}

MAIN_MENU