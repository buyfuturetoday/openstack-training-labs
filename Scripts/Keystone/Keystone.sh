#!/bin/sh
#
# About:Setup Dependences for Virtual Box Sandbox
#       meant for OpenStack Labs.
#
# Contact: pranav@aptira.com
# License: Apache Software License (ASL) 2.0

###############################################################################
#                                                                             #
# This Script will install keystone related packages and after installaion, it#
# will configure Keystone, populate the database.                             #
#                                                                             #
###############################################################################

# Note: You Do Not Need Internet for this due to the magic of --download-only
echo "Internet connection is not required for this script to run"

pre_keystone(){
    
    # 1. Database - MySQL and Python MySQL DB Connector
    debconf-set-selections  <<< 'mysql-server mysql-server/root_password password '$MySQL_RPaSS''
    debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password '$MySQL_RPaSS''
    apt-get install -y --force-yes mysql-server python-mysqldb

    # Configure MySQL to listen to other all IP addresses
    sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf

    # Restart MySQL service
    service mysql restart
      
    # 2. Install RabbitMQ
    apt-get install -y --force-yes rabbitmq-server
    apt-get install -y --force-yes ntp
    apt-get install -y --force-yes vlan bridge-utils

    # Enable IP Forwarding
    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    sysctl net.ipv4.ip_forward=1
}

keystone_conf() {

    # 1. Install Keystone
    apt-get -y --force-yes install keystone

    
    # Create Database Keystone, Glance, 
    mysql -u "root" -p"$MySQL_RPaSS" -e "create database keystone"
    mysql -u "root" -p"$MySQL_RPaSS" -e "GRANT ALL ON keystone.* TO 'keystoneUser'@'%' IDENTIFIED BY 'keystonePass';"
    mysql -u "root" -p"$MySQL_RPaSS" -e "create database glance"
    mysql -u "root" -p"$MySQL_RPaSS" -e "GRANT ALL ON glance.* TO 'glanceUser'@'%' IDENTIFIED BY 'glancePass';"
    mysql -u "root" -p"$MySQL_RPaSS" -e "create database quantum"
    mysql -u "root" -p"$MySQL_RPaSS" -e "GRANT ALL ON quantum.* TO 'quantumUser'@'%' IDENTIFIED BY 'quantumPass';"
    mysql -u "root" -p"$MySQL_RPaSS" -e "create database nova"
    mysql -u "root" -p"$MySQL_RPaSS" -e "GRANT ALL ON nova.* TO 'novaUser'@'%' IDENTIFIED BY 'novaPass';"
    mysql -u "root" -p"$MySQL_RPaSS" -e "create database cinder"
    mysql -u "root" -p"$MySQL_RPaSS" -e "GRANT ALL ON cinder.* TO 'cinderUser'@'%' IDENTIFIED BY 'cinderPass';"

    # 2. Configure keystone scripts (copy the template file)
    cp --no-preserve=mode,ownership Templates/Keystone.conf /etc/keystone/keystone.conf 

    # 3. Restart The Keystone Services
    service keystone restart

    # 4. Populate the database using db_sync
    keystone-manage db_sync

    # Create User and grant access to the user
    sh Scripts/keystone_basic.sh
    sh Scripts/keystone_endpoints_basic.sh
    
    # Load the Auth Creds
    source Scripts/Credentials.sh

    # Check The Keystone Useres
    keystone user-list
}


# Create required MySQL Databases and Populate It.
echo "Enter MySQL root pass"
read MySQL_RPaSS

echo "Running pre_keystone"
pre_keystone

echo "Running keystone_conf"
keystone_conf

