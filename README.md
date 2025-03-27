# PHPMyAdmin Scripts

## Overview

This repository contains scripts for installing PHPMyAdmin and managing user creation.

## Scripts

### 1. `install.sh`
This script automates the installation of PHPMyAdmin on a Linux-based system. It performs the following actions:
- Updates system packages
- Installs required dependencies (Apache, MySQL, PHP, etc.)
- Downloads and configures PHPMyAdmin
- Sets up the necessary permissions
- Restarts services to apply changes


bash <(curl -s https://raw.githubusercontent.com/Leo-Galli/phpmyadmin_scripts/main/install.sh)

### 2. `create_user.sh`
This script simplifies the creation of a new MySQL user for PHPMyAdmin. It performs the following tasks:
- Prompts the user for a username and password
- Creates the MySQL user with the specified credentials
- Grants necessary privileges
- Reloads privileges to apply changes

## Usage

### Install PHPMyAdmin
```bash
chmod +x install.sh
./install.sh
