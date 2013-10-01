#!/bin/sh
#
# About:Setup Dependences for Virtual Box Sandbox
#       meant for OpenStack Labs.
#
# Contact: pranav@aptira.com
# License: Apache Software License (ASL) 2.0
###############################################################################
#                                                                             #
# This Script will install Glance related packages and after installaion, it  #
# will configure Glance                                                       #
#                                                                             #
###############################################################################

# Note: You DoNot Need Internet for this due to the magic of --download-only
echo "Internet connection is not required for this script to run"

glance_conf(){

    #1. Install Glance
    apt-get install -y glance

    #2. Configure the Config Files
    cp --no-preserve=mode,ownership Templates/glance-api.conf /etc/glance/glance-api.conf
    cp --no-preserve=mode,ownership Templates/glance-api-paste.ini /etc/glance/glance-api-paste.ini
    cp --no-preserve=mode,ownership Templates/glance-registry-paste.ini /etc/glance/glance-registry-paste.ini
    cp --no-preserve=mode,ownership Templates/glance-registry.conf /etc/glance/glance-registry.conf

    #3. Restart Glance Services
    service glance-api restart
    service glance-registry restart
    
    #5. Sync Glance Database
    glance-manage db_sync

    #4. Upload Cirros Image to Glance
    source ../Keystone/Scripts/Credentials.sh
    glance image-create --name myFirstImage --is-public true --container-format bare --disk-format qcow2 < Templates/cirros-0.3.1-x86_64-disk.img

    #5. Check The Image
    glance image-list
}

echo "Running Glance Configuration"
glance_conf
