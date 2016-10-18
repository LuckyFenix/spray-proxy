#!/usr/bin/env bash
#variables
activatorVersion="1.3.10"
sbtVersion="0.13.11"

cd ~

echo "=========================================="
echo "Provision VM START"
echo "=========================================="

sudo apt-get update

# locales
echo '
LANG=en_US.UTF-8
LANGUAGE=en_US.UTF-8
LC_CTYPE="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_PAPER="en_US.UTF-8"
LC_NAME="en_US.UTF-8"
LC_ADDRESS="en_US.UTF-8"
LC_TELEPHONE="en_US.UTF-8"
LC_MEASUREMENT="en_US.UTF-8"
LC_IDENTIFICATION="en_US.UTF-8"
LC_ALL=en_US.UTF-8
' | sudo tee /etc/default/locale

sudo dpkg-reconfigure locales

# time to UTC
sudo unlink /etc/localtime
sudo ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime

###############################################
# install prerequisits
###############################################
sudo apt-get -y -q upgrade
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get -y -q update
sudo apt-get -y -q install software-properties-common htop
sudo apt-get -y -q install build-essential
sudo apt-get -y -q install tcl8.5
sudo apt-get -y -q install git-core curl zlib1g-dev libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev libgdbm-dev libncurses5-dev automake libtool bison

###############################################
# Install Java 8
###############################################
# sudo apt-get install -y openjdk-8-jdk
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
sudo apt-get -y -q install oracle-java8-installer
sudo update-java-alternatives -s java-8-oracle

###############################################
# In case you need Java 7
###############################################
# sudo apt-get install -y openjdk-7-jdk
#echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
#sudo apt-get -y -q install oracle-java7-installer

###############################################
# Install Git
###############################################
sudo apt-get -y install git

###############################################
# Install imagemagick
###############################################
#sudo apt-get -y install imagemagick

###############################################
# Install Scala
###############################################
sudo apt-get -y install scala

###############################################
# Install Unzip
###############################################
sudo apt-get -y install unzip

###############################################
# Install NodeJS
###############################################
curl --silent --location https://deb.nodesource.com/setup_6.x | sudo bash -
sudo apt-get -y install nodejs
ln -s /usr/bin/nodejs /user/bin/node
# Add node_modules to environment variables
echo "export NODE_PATH=/usr/local/lib/node_modules" >> ~/.bashrc

###############################################
# Install NPM
###############################################
sudo apt-get -y install npm

###############################################
# Install CoffeeScript
###############################################
sudo npm install -g coffee-script

###############################################
# Install YO Gulp Bower
###############################################
sudo npm install -g yo gulp bower

###############################################
# Install Sass
###############################################
sudo gem install sass

###############################################
# Install Redis
# More info about it: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-redis
###############################################
echo "Download Redis..."
wget http://download.redis.io/releases/redis-stable.tar.gz
tar xzf redis-stable.tar.gz
cd redis-stable
make
make test
sudo make install
cd utils
sudo ./install_server.sh
cd /home/vagrant/
rm redis-stable.tar.gz
echo "Redis done."

###############################################
# Install Redis-cli
###############################################
sudo apt-get install Redis-cli

###############################################
# Install PostgreSQL
###############################################
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql postgresql-contrib postgresql-client-common postgresql-common

###############################################
# Install SBT
###############################################
echo "Download SBT..."
wget http://dl.bintray.com/sbt/debian/sbt-$sbtVersion.deb
sudo dpkg -i sbt-$sbtVersion.deb
sudo apt-get update
sudo apt-get install sbt
rm sbt-$sbtVersion.deb

echo "SBT done."
# Use node as default JavaScript Engine
echo "export SBT_OPTS=\"\$SBT_OPTS -Dsbt.jse.engineType=Node\"" >> ~/.bashrc

###############################################
# Install typesafe activator
###############################################
cd /home/vagrant
echo "Download Typesafe Activator..."
wget http://downloads.typesafe.com/typesafe-activator/$activatorVersion/typesafe-activator-$activatorVersion.zip
unzip -d /home/vagrant typesafe-activator-$activatorVersion.zip
rm typesafe-activator-$activatorVersion.zip
echo "Typesafe Activator done."
# Add activator to environment variables
echo "export PATH=/home/vagrant/activator-dist-$activatorVersion/bin:\$PATH" >> ~/.bashrc

###############################################
# Reset bash
###############################################
source ~/.bashrc

###############################################
# Install MongDB
###############################################
echo "Download MongoDB..."
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
sudo apt-get update
sudo apt-get -y install mongodb-org
echo "MongDB done."

###############################################
# Reset bash
###############################################
source ~/.bashrc

sudo -u postgres psql -c "CREATE DATABASE just_click;"
sudo -u postgres psql -c "CREATE USER just_click_admin WITH PASSWORD 'WrejaQATrUs7';"
sudo -u postgres psql -c  "GRANT ALL privileges ON DATABASE just_click TO just_click_admin;"

echo 'host  all  all 0.0.0.0/0 md5' | sudo tee --append /etc/postgresql/9.5/main/pg_hba.conf > /dev/null
echo "listen_addresses='*'" | sudo tee --append /etc/postgresql/9.5/main/postgresql.conf > /dev/null
sudo service postgresql restart

###############################################
# Show installation summary
###############################################
echo "=========================================="
echo "Provision VM summary"
echo "=========================================="
echo "Dependencies installed:"
echo " "
echo "jdk version:"
javac -version
echo " "
echo "ruby version:"
ruby -v
echo " "
echo "NodeJS version:"
node -v
echo " "
echo "NPM version"
npm -v
echo " "
echo "CoffeeScript version:"
coffee -v
echo " "
echo "Bower version:"
bower -v
echo " "
echo "Sass version:"
sass -v
echo " "
echo "Redis version"
redis-server -v
echo " "
echo "PostgreSQL version"
psql --version
echo " "
echo "mongoDB version"
mongod --version
echo " "
echo "=========================================="
echo "Provision VM finished"
echo "=========================================="
