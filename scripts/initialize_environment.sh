# Install MineGCG
sudo git clone https://github.com/jvc56/MineGCG.git

# Install Postgres

sudo apt-get install postgresql

# Install perl modules with sudo privileges
sudo apt-get install libdbd-pg-perl
sudo apt-get install libpg-perl
sudo apt-get install libjson-perl
sudo apt-get install libdbi-perl
sudo apt-get install libclone-perl

# Alter password of postgres user and create database with:
# $            sudo -u postgres psql
# postgres=#   ALTER USER postgres WITH PASSWORD 'new_password';
# postgres=#   CREATE DATABASE minegcg