#!/bin/bash

# Update and Upgrade Packages
echo "Updating and upgrading system packages..."
sudo apt update && sudo apt upgrade -y

# Install Python 3.10 and pip3
echo "Installing Python 3.10 and pip3..."
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.10 python3.10-dev python3.10-venv python3-pip

# Install Required Packages
echo "Installing required dependencies..."
sudo apt install -y software-properties-common mariadb-server mariadb-client redis-server xvfb \
    libfontconfig wkhtmltopdf libmysqlclient-dev curl git npm

# Install Node.js and Yarn using nvm
echo "Installing Node.js and Yarn..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 18
npm install -g yarn

# Configure MariaDB
echo "Configuring MariaDB..."
sudo systemctl enable mariadb
sudo systemctl start mariadb
sudo mysql -u root <<MYSQL_SCRIPT
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('kiaanerp@32!');
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

sudo tee -a /etc/mysql/my.cnf > /dev/null <<EOF
[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
EOF

sudo systemctl restart mariadb

# Install Frappe Bench
echo "Installing Frappe Bench..."
pip3 install --upgrade pip
pip3 install frappe-bench

# Initialize Bench
echo "Initializing Frappe Bench..."
bench init --frappe-branch version-15 frappe-bench
cd frappe-bench

# Create a new site
echo "Creating a new site..."
bench new-site erp.example.com --admin-password kiaanadm@32! --mariadb-root-password kiaanerp@32!

# Install ERPNext app
echo "Installing ERPNext..."
bench get-app --branch version-15 erpnext
bench --site erp.example.com install-app erpnext

# Production Setup
read -p "Do you want to set up ERPNext for production? (yes/no): " PRODUCTION_SETUP
if [[ $PRODUCTION_SETUP == "yes" ]]; then
  echo "Setting up ERPNext for production..."
  sudo bench setup production $(whoami)
  echo "Production setup complete. Access ERPNext at http://<YOUR_SERVER_IP>"
else
  echo "Skipping production setup. You can run 'bench start' for development."
fi

echo "ERPNext installation completed."
