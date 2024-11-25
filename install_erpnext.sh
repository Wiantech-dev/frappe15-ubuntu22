#!/bin/bash

# Update and Upgrade Packages
echo "Updating and upgrading system packages..."
sudo apt update && sudo apt upgrade -y

# Create a New User (Bench User)
read -p "Enter username for bench user (e.g., frappe): " BENCH_USER
sudo adduser --gecos "" $BENCH_USER
sudo usermod -aG sudo $BENCH_USER

# Switch to the Bench User
sudo su - $BENCH_USER <<'USER_SETUP'

# Install Required Packages
echo "Installing required packages..."
sudo apt install -y python3-dev python3.10-dev python3-setuptools python3-pip python3-distutils python3.10-venv \
    software-properties-common mariadb-server mariadb-client redis-server xvfb libfontconfig wkhtmltopdf \
    libmysqlclient-dev curl git npm

# Install GIT
echo "Installing Git..."
sudo apt install -y git

# Install Python
echo "Installing Python..."
sudo apt install -y python3 python3-pip python3.10-venv

# Install Software Properties Common
echo "Installing software-properties-common..."
sudo apt install -y software-properties-common

# Install MariaDB
echo "Installing MariaDB..."
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

# Configure MYSQL Server
echo "Configuring MySQL server..."
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

# Install CURL, Node.js, NPM, and Yarn
echo "Installing CURL, Node.js, NPM, and Yarn..."
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
source ~/.bashrc
nvm install 18
sudo npm install -g yarn

# Install Frappe Bench
echo "Installing Frappe Bench..."
pip3 install --upgrade pip
pip3 install frappe-bench

# Initialize Frappe Bench
echo "Initializing Frappe Bench..."
bench init --frappe-branch version-15 frappe-bench
cd frappe-bench

# Set Permissions
echo "Setting permissions for the bench user..."
chmod -R o+rx /home/$USER

# Create a New Site
echo "Creating a new site for ERPNext..."
bench new-site erp.example.com --admin-password kiaanadm@32! --mariadb-root-password kiaanerp@32!

# Install ERPNext and Other Apps
echo "Installing ERPNext app..."
bench get-app --branch version-15 erpnext
bench --site kiaanerp.technowitty.in install-app erpnext

USER_SETUP

# Ask for Production Setup
read -p "Do you want to set up ERPNext for production? (yes/no): " PRODUCTION_SETUP
if [[ $PRODUCTION_SETUP == "yes" ]]; then
  echo "Setting up ERPNext for production..."
  sudo su - $BENCH_USER <<'PRODUCTION'
  cd frappe-bench
  sudo bench setup production $USER
  echo "Production setup complete. Access ERPNext at http://<YOUR_SERVER_IP>"
PRODUCTION
else
  echo "Starting development server..."
  sudo su - $BENCH_USER <<'DEV'
  cd frappe-bench
  bench start
DEV
fi

echo "ERPNext installation script complete."
