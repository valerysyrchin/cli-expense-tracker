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

    # Set terminal columns to 1 locally to force vertical layout for select menus
    local COLUMNS=1

    # Select an expense category
    echo -e "\nWhich expense category?"

    # Read query results into an array to properly handle category names with spaces
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

    # Select currency
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
    
    # Select transaction amount
    read -p "Enter expense amount: " EXPENSE_AMOUNT
    while [[ ! $EXPENSE_AMOUNT =~ ^[0-9]+$ ]]
    do
        read -p "Sorry, only numbers allowed. Try again: " EXPENSE_AMOUNT
    done
    echo "Expense amount has been set to $EXPENSE_AMOUNT"

    # Select transaction date
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

    # Select description (optional)
    read -p "Add description? [y/N]: " DESCRIPTION_ANSWER
    if [[ $DESCRIPTION_ANSWER == "y" || $DESCRIPTION_ANSWER == "Y" ]]
    then 
        read -p "Enter description: " USER_DESCRIPTION
        DESCRIPTION="'$USER_DESCRIPTION'"
        echo "Description has been added."
    else
        DESCRIPTION="NULL"
    fi

    # Insert transaction to database
    INSERT_EXPENSE_RESULT=$($PSQL "insert into transactions(expense_category_id, currency_id, amount, transaction_date, description) values ($CATEGORY_ID, $CURRENCY_ID, $EXPENSE_AMOUNT, '$EXPENSE_DATE', $DESCRIPTION)")
    
    MAIN_MENU "Expense has been added to database."
    return
}

EDIT_MENU() {

    # Force 'select' menus to render vertically by constraining terminal columns locally
    local COLUMNS=1

    # Display a status message if passed as an argument
    if [[ -n $1 ]]
    then
        echo -e "$1"
    fi

    echo "Select a method to find an expense to edit: " 
        echo -e "\n1. By category\n2. By date\n3. By currency\n4. By description\n5. Go back to main menu"
    read EDIT_MENU_SELECTION

    # Route the user based on the choice, passing the filter type and dynamic prompt as arguments
    case $EDIT_MENU_SELECTION in
        1) FIND_EXPENSE_MENU "category" "Enter category name: " ;;
        2) FIND_EXPENSE_MENU "date" "Enter date (YYYY-MM-DD): " ;;
        3) FIND_EXPENSE_MENU "currency" "Enter currency (USD, EUR, RUB...): " ;;
        4) FIND_EXPENSE_MENU "description" "Enter a keyword for description: " ;;
        5) MAIN_MENU ;;
        *) EDIT_MENU "Please enter a valid option." ;;
    esac
}

FIND_EXPENSE_MENU(){
    # Initialize a local variable to build the dynamic SQL WHERE clause
    local WHERE_CLAUSE=""

    case $1 in
        "category") 
            echo -e "\nSelect a category to filter expenses:"
            
            # Fetch existing categories from the database into a Bash array
            # The 'tr -d' command strips Carriage Return (\r) flags returned by PostgreSQL
            readarray -t CATEGORIES < <($PSQL "select name from expense_categories order by expense_category_id" | tr -d '\r')
            
            # Backup the original prompt and set a custom one for the native select menu
            local OLD_PS3=$PS3
            PS3="Enter category number: "

            # Display an interactive loop for category selection
            select SELECTED_CATEGORY in "${CATEGORIES[@]}"
            do
                if [[ -n $SELECTED_CATEGORY ]]
                then
                    # Build the filter condition using explicit table joins
                    WHERE_CLAUSE="where expense_categories.name = '$SELECTED_CATEGORY'"
                    break
                else
                    echo "Invalid choice. Please try again."
                fi
            done
            # Restore the global prompt state
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

    # Construct a raw SQL query concatenating fields with semicolons for easy parsing
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

    # Execute the query and parse raw rows into a Bash array
    readarray -t RAW_DATA < <($PSQL "$QUERY" | tr -d '\r')

    # Redirect back to the edit menu if no records match the criteria
    if [[ ${#RAW_DATA[@]} -eq 0 ]]
    then
        EDIT_MENU "\nNo expenses found matching your criteria."
        return
    fi

    echo -e "\nSelect the expense you want to edit:"

    # Format and display the datasets into a clean CLI table using the 'column' utility
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

    # Input validation loop to ensure the user selects a valid index from the generated table
    while true; do
        read -p "Enter transaction number (1-${#RAW_DATA[@]}): " CHOSEN_NUM 

        # Validate that input is a purely positive integer within the array's index boundaries
        if [[ "$CHOSEN_NUM" =~ ^[0-9]+$ ]] && [ "$CHOSEN_NUM" -ge 1 ] && [ "$CHOSEN_NUM" -le "${#RAW_DATA[@]}" ]
        then
            # Extract the actual database primary key (ID) from the first column of the chosen row
            SELECTED_ROW="${RAW_DATA[$((CHOSEN_NUM-1))]}"
            CHOSEN_ID=$(echo "$SELECTED_ROW" | cut -d';' -f1)
            
            UPDATE_EXPENSE_MENU "$CHOSEN_ID"
            break
        else
            echo "Invalid input. Please look at the [NUM] column."
        fi
    done
}

UPDATE_EXPENSE_MENU() {
    # Save the transaction ID to know which expense we are changing
    local CHOSEN_ID=$1

    # If the user made a mistake on the previous step, display the error message
    if [[ -n $2 ]]
    then
        echo -e "$2\n"
    fi

    echo "What would you like to update?"
    echo -e "\n1. Category\n2. Date\n3. Currency\n4. Description\n5. Go back to find expense menu\n6. Go back to main menu"
    read UPDATE_EXPENSE_MENU_SELECTION

    case $UPDATE_EXPENSE_MENU_SELECTION in
        1) UPDATE_EXPENSE_RESULT_MENU "category" "Enter new category name: " $CHOSEN_ID ;;
        2) UPDATE_EXPENSE_RESULT_MENU "date" "Enter new date (YYYY-MM-DD): " $CHOSEN_ID ;;
        3) UPDATE_EXPENSE_RESULT_MENU "currency" "Enter new currency code (USD, EUR, RUB...): " $CHOSEN_ID ;;
        4) UPDATE_EXPENSE_RESULT_MENU "description" "Enter new description: " $CHOSEN_ID ;;
        5) EDIT_MENU ;;
        6) MAIN_MENU ;;
        *) UPDATE_EXPENSE_MENU "$CHOSEN_ID" "Invalid choice. Please try again." ;;
    esac
}

UPDATE_EXPENSE_RESULT_MENU() {
    # Get the transaction ID from the third argument
    local CHOSEN_ID=$3

    case $1 in
        "category") 
            echo -e "\nSelect a new category for the expense:"
            
            # Get all available categories from the database
            readarray -t CATEGORIES < <($PSQL "select name from expense_categories order by expense_category_id" | tr -d '\r')

            # Change the menu prompt helper locally
            local OLD_PS3=$PS3
            PS3="Enter category number: "

            # Display categories list to the user
            select SELECTED_CATEGORY in "${CATEGORIES[@]}"
            do
                if [[ -n $SELECTED_CATEGORY ]]
                then
                    UPDATE_CATEGORY=$SELECTED_CATEGORY
                    # Get the ID for the chosen category name
                    UPDATE_CATEGORY_ID=$($PSQL "select expense_category_id from expense_categories where name='$UPDATE_CATEGORY'" | tr -d '\r')
                    break
                else
                    echo "Invalid choice. Please try again."
                fi
            done
            # Restore the original menu prompt helper
            PS3=$OLD_PS3
            ;;
        "date")     
            read -p "$2" UPDATE_DATE
            ;;
        "currency") 
            read -p "$2" UPDATE_CURRENCY
            # Find the currency ID using the code entered by the user
            UPDATE_CURRENCY_ID=$($PSQL "select currency_id from currencies where code = '$UPDATE_CURRENCY'" | tr -d '\r')
            ;;
        "description") 
            read -p "$2" UPDATE_DESCRIPTION
            ;;
    esac

    # Execute the database updates based on the selected field type
    if [[ $1 == 'category' ]]
    then 
        UPDATE_CATEGORY_TRANSACTION_RESULT=$($PSQL "update transactions set expense_category_id = '$UPDATE_CATEGORY_ID' where transaction_id = $CHOSEN_ID")
        MAIN_MENU "Category has been updated."
        return
    fi

    if [[ $1 == 'date' ]]
    then
        UPDATE_DATE_TRANSACTION_RESULT=$($PSQL "update transactions set transaction_date = '$UPDATE_DATE' where transaction_id = $CHOSEN_ID")
        MAIN_MENU "Date has been updated."
        return
    fi

    if [[ $1 == 'currency' ]]
    then
        UPDATE_CURRENCY_TRANSACTION_RESULT=$($PSQL "update transactions set currency_id = '$UPDATE_CURRENCY_ID' where transaction_id = $CHOSEN_ID")
        MAIN_MENU "Currency code has been updated."
        return
    fi

    if [[ $1 == 'description' ]]
    then
        UPDATE_DESCRIPTION_TRANSACTION_RESULT=$($PSQL "update transactions set description = '$UPDATE_DESCRIPTION' where transaction_id = $CHOSEN_ID")
        MAIN_MENU "Description has been updated."
        return
    fi
}

ANALYZE_MENU() {
    MAIN_MENU "Sorry, this function is under development."
}

EXIT() {
    echo -e "\nThank you, see you again!"
}

MAIN_MENU