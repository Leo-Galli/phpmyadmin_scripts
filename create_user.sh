#!/bin/bash

# Advanced MySQL User and Database Management Script
# Features:
# 1. Creates users with different permission levels (Admin/Standard User)
# 2. Creates databases with username or custom name
# 3. Manages specific permissions
# 4. Checks for existing users/databases
# 5. Interactive interface

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Utility functions

# Check if MySQL is installed
check_mysql_installed() {
    if ! command -v mysql &> /dev/null; then
        echo -e "${RED}MySQL client is not installed. Please install it first.${NC}"
        exit 1
    fi
}

# Check MySQL connection
check_mysql_connection() {
    if ! mysql -u root -p"$rootpass" -e "SELECT 1" &> /dev/null; then
        echo -e "${RED}MySQL connection failed. Please check password.${NC}"
        exit 1
    fi
}

# Check if user exists
user_exists() {
    local user="$1"
    local count=$(mysql -u root -p"$rootpass" -s -N -e "SELECT COUNT(*) FROM mysql.user WHERE user = '$user'")
    [ "$count" -eq 1 ]
}

# Check if database exists
db_exists() {
    local dbname="$1"
    local count=$(mysql -u root -p"$rootpass" -s -N -e "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = '$dbname'")
    [ "$count" -eq 1 ]
}

# Show main menu
show_main_menu() {
    clear
    echo -e "${GREEN}=== MySQL User and Database Management ==="
    echo "1. Create new user and database"
    echo "2. Modify existing user permissions"
    echo "3. Delete user"
    echo "4. Exit"
    echo -e "==========================================${NC}"
}

# Show permissions menu
show_permissions_menu() {
    clear
    echo -e "${YELLOW}=== User Type Selection ==="
    echo "1. Administrator (all privileges on all databases)"
    echo "2. Standard User (all privileges only on own database)"
    echo "3. Custom User (select specific permissions)"
    echo -e "============================${NC}"
}

# Create new user
create_user() {
    read -p "Enter new username: " username
    
    if user_exists "$username"; then
        echo -e "${RED}Error: User $username already exists!${NC}"
        return 1
    fi
    
    read -sp "Enter password for $username: " userpass
    echo ""
    read -sp "Confirm password: " userpass_confirm
    echo ""
    
    if [ "$userpass" != "$userpass_confirm" ]; then
        echo -e "${RED}Error: Passwords don't match!${NC}"
        return 1
    fi
    
    show_permissions_menu
    read -p "Select user type [1-3]: " user_type
    
    case $user_type in
        1) # Admin
            mysql -u root -p"$rootpass" -e "CREATE USER '$username'@'localhost' IDENTIFIED BY '$userpass';"
            mysql -u root -p"$rootpass" -e "GRANT ALL PRIVILEGES ON *.* TO '$username'@'localhost' WITH GRANT OPTION;"
            echo -e "${GREEN}Created admin user $username with all privileges${NC}"
            ;;
        2) # Standard User
            read -p "Create database with same name as user? [y/n]: " same_db
            if [[ "$same_db" == "y" ]]; then
                dbname="${username}_db"
            else
                read -p "Enter database name: " dbname
            fi
            
            if db_exists "$dbname"; then
                echo -e "${YELLOW}Warning: Database $dbname already exists.${NC}"
                read -p "Confirm granting permissions to user $username on database $dbname? [y/n]: " confirm
                if [[ "$confirm" != "y" ]]; then
                    echo -e "${RED}Operation canceled.${NC}"
                    return 1
                fi
            else
                mysql -u root -p"$rootpass" -e "CREATE DATABASE $dbname;"
                echo -e "${GREEN}Created database $dbname${NC}"
            fi
            
            mysql -u root -p"$rootpass" -e "CREATE USER '$username'@'localhost' IDENTIFIED BY '$userpass';"
            mysql -u root -p"$rootpass" -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$username'@'localhost';"
            echo -e "${GREEN}Created user $username with all privileges on database $dbname${NC}"
            ;;
        3) # Custom User
            read -p "Enter database name: " dbname
            if ! db_exists "$dbname"; then
                mysql -u root -p"$rootpass" -e "CREATE DATABASE $dbname;"
                echo -e "${GREEN}Created database $dbname${NC}"
            fi
            
            echo -e "${YELLOW}Select permissions to grant (comma separated):"
            echo "CREATE, DROP, ALTER, INSERT, SELECT, UPDATE, DELETE, INDEX, CREATE VIEW, SHOW VIEW"
            echo -e "Example: SELECT,INSERT,UPDATE${NC}"
            read -p "Permissions: " permissions
            
            mysql -u root -p"$rootpass" -e "CREATE USER '$username'@'localhost' IDENTIFIED BY '$userpass';"
            mysql -u root -p"$rootpass" -e "GRANT $permissions ON $dbname.* TO '$username'@'localhost';"
            echo -e "${GREEN}Created user $username with custom permissions on database $dbname${NC}"
            ;;
        *)
            echo -e "${RED}Invalid choice!${NC}"
            return 1
            ;;
    esac
    
    mysql -u root -p"$rootpass" -e "FLUSH PRIVILEGES;"
    return 0
}

# Modify user permissions
modify_permissions() {
    read -p "Enter username to modify: " username
    
    if ! user_exists "$username"; then
        echo -e "${RED}Error: User $username not found!${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Current permissions for $username:${NC}"
    mysql -u root -p"$rootpass" -e "SHOW GRANTS FOR '$username'@'localhost';"
    
    show_permissions_menu
    read -p "Select new permission type [1-3]: " user_type
    
    # First revoke all privileges
    mysql -u root -p"$rootpass" -e "REVOKE ALL PRIVILEGES, GRANT OPTION FROM '$username'@'localhost';"
    
    case $user_type in
        1) # Admin
            mysql -u root -p"$rootpass" -e "GRANT ALL PRIVILEGES ON *.* TO '$username'@'localhost' WITH GRANT OPTION;"
            echo -e "${GREEN}Updated $username to administrator${NC}"
            ;;
        2) # Standard User
            read -p "Enter database name: " dbname
            if ! db_exists "$dbname"; then
                echo -e "${RED}Error: Database $dbname not found!${NC}"
                return 1
            fi
            mysql -u root -p"$rootpass" -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$username'@'localhost';"
            echo -e "${GREEN}Updated permissions for $username on database $dbname${NC}"
            ;;
        3) # Custom User
            read -p "Enter database name: " dbname
            if ! db_exists "$dbname"; then
                echo -e "${RED}Error: Database $dbname not found!${NC}"
                return 1
            fi
            echo -e "${YELLOW}Select permissions to grant (comma separated):"
            echo "CREATE, DROP, ALTER, INSERT, SELECT, UPDATE, DELETE, INDEX, CREATE VIEW, SHOW VIEW"
            echo -e "Example: SELECT,INSERT,UPDATE${NC}"
            read -p "Permissions: " permissions
            mysql -u root -p"$rootpass" -e "GRANT $permissions ON $dbname.* TO '$username'@'localhost';"
            echo -e "${GREEN}Updated permissions for $username on database $dbname${NC}"
            ;;
        *)
            echo -e "${RED}Invalid choice!${NC}"
            return 1
            ;;
    esac
    
    mysql -u root -p"$rootpass" -e "FLUSH PRIVILEGES;"
    return 0
}

# Delete user
delete_user() {
    read -p "Enter username to delete: " username
    
    if ! user_exists "$username"; then
        echo -e "${RED}Error: User $username not found!${NC}"
        return 1
    fi
    
    read -p "Also delete databases owned by this user? [y/n]: " delete_dbs
    if [[ "$delete_dbs" == "y" ]]; then
        databases=$(mysql -u root -p"$rootpass" -s -N -e "SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE '${username}_%'")
        
        if [ -n "$databases" ]; then
            echo -e "${YELLOW}Databases to delete:${NC}"
            echo "$databases"
            read -p "Confirm deletion? [y/n]: " confirm
            if [[ "$confirm" == "y" ]]; then
                for db in $databases; do
                    mysql -u root -p"$rootpass" -e "DROP DATABASE $db;"
                    echo -e "${GREEN}Deleted database $db${NC}"
                done
            fi
        else
            echo -e "${YELLOW}No databases found with prefix ${username}_${NC}"
        fi
    fi
    
    mysql -u root -p"$rootpass" -e "DROP USER '$username'@'localhost';"
    echo -e "${GREEN}User $username deleted successfully${NC}"
    
    mysql -u root -p"$rootpass" -e "FLUSH PRIVILEGES;"
    return 0
}

## Main Program ##

check_mysql_installed

# Request MySQL root password
while true; do
    read -sp "Enter MySQL root password: " rootpass
    echo ""
    check_mysql_connection && break
done

while true; do
    show_main_menu
    read -p "Select an option [1-4]: " option
    
    case $option in
        1) create_user ;;
        2) modify_permissions ;;
        3) delete_user ;;
        4) 
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0 ;;
        *)
            echo -e "${RED}Invalid choice!${NC}" ;;
    esac
    
    read -p "Press Enter to continue..." dummy
done