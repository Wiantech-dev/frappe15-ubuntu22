#!/bin/bash

# Update and Upgrade Packages
echo "Updating and upgrading system packages..."
sudo apt update && sudo apt upgrade -y

# Install Required Packages
echo "Installing required packages..."
sudo apt install -y python3-dev python3.10-dev python3-setuptools python3-pip python3-distutils python3.10-venv \
    software-properties-common mariadb-server mariadb-client redis-server xvfb libfontconfig wkhtmltopdf \
    libmysqlclient-dev curl git npm

# Configure MySQL
echo "Installing and configuring MariaDB..."
sudo apt install -y mariadb-server mariadb-client
sudo mysql_secure_installation <<EOF
Y
kiaanerp@32!
Y
Y
N
Y
Y
EOF
sudo tee -a /etc/mysql/my.cnf > /dev/null <<EOL
[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
EOL
sudo service mysql restart

# Install Redis Server
echo "Installing Redis server..."
sudo apt install -y redis-server

# Install Node.js, NPM, and Yarn
echo "Installing Node.js, NPM, and Yarn..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
source $NVM_DIR/nvm.sh
nvm install 18
npm install -g yarn

# Install Frappe Bench
echo "Installing Frappe Bench..."
pip3 install --upgrade pip
pip3 install frappe-bench

# Initialize Frappe Bench
echo "Initializing Frappe Bench..."
bench init --frappe-branch version-15 frappe-bench
cd frappe-bench

# Create a New Site
echo "Creating a new site for ERPNext..."
bench new-site erp.example.com --admin-password kiaanadm@32! --mariadb-root-password kiaanerp@32!

# Install ERPNext
echo "Installing ERPNext app..."
bench get-app --branch version-15 erpnext
bench --site erp.example.com install-app erpnext

# Production Setup
read -p "Do you want to set up ERPNext for production? (yes/no): " PRODUCTION_SETUP
if [[ $PRODUCTION_SETUP == "yes" ]]; then
  echo "Setting up ERPNext for production..."
  sudo bench setup production $USER
  echo "Production setup complete. Access ERPNext at http://<YOUR_SERVER_IP>"
else
  echo "Starting development server..."
  bench start
fi

echo "ERPNext installation script complete."
