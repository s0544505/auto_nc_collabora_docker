#!/bin/sh
#inform User
echo "Welcome to the semiautomatic Nextcloud installation script."
echo "You will be often asked to enter passwords, make sure they are entered correctly."
echo "Write down newly assigned user names and passwords and keep them in a safe place."
echo "KEEP IN MIND: everything (including passwords) can just be entered once. Therefore passwords sometimes are shown while typing..."
#retrieve User-inputs and save them to variables
read -p 'Please enter the root-Username provided by your Server hoster, usually its simply root: ' rootuservar
read -p 'Now enter the IP-Adress to your server: ' serveraddressvar
echo "We will create a new User for security purposes... Please enter the name for the new User..."
read -p 'Username: ' newuservar
read -p 'Please provide a password for the new User: ' newuserpasswordvar
#read -p 'Please provide a User for the PostreSQL-Database : ' postgresuservar
read -p 'Please provide a password for the PostreSQL-Database. Use a very strong one!: ' postgresqlpwvar
read -p 'Please provide the Domain to your new Nextcloud (usually cloud.yourdomain.com): ' ncdomainvar
read -p 'Please provide the Domain for your new Collabora-CODE (usually office.yourdomain.com): ' officedomainvar
read -p 'Please provide a working mailaddress to receive securityconserned mails from Letsencrypt: ' lemailvar

# remove the known host, ifn needed
#sudo ssh-keygen -f "/home/$User/.ssh/known_hosts" -R "$serveraddress"

echo "Please enter the root passwort for your server, then choose yes and hit [Return] when aksed to.."
#ssh to remote, login as root, create new user and enable sudo
ssh -tY $rootuservar@$serveraddressvar "echo 'Creating new User...'; sudo useradd $newuservar -d /home/$newuservar -m; sudo usermod -aG sudo $newuservar; usermod -s /bin/bash $newuservar; sudo echo $newuservar:$newuserpasswordvar | sudo chpasswd; echo 'preparing docker group...'; sudo groupadd docker ; sudo usermod -aG docker $newuservar;"

echo "Will try to login as $newuservar, please provide the password when promted and hit [Return]:"
#ssh to remote with prviously created user  user, install git, docker, enable sudo for docker deamon, install docker-compose, clone git repository with env-files and docker-compose-file, replace environmet variables with userinputs via SED, create container with docker-compose
ssh -tY $newuservar@$serveraddressvar "echo 'Successfully logged in as user $newuservar, now its required to enter $newuservar s password again. this is necessary to run in sudo:';
sudo apt-get update -y --no-install-recommends; echo '..installing Git'; sudo apt-get install git -y --no-install-recommends;
sudo apt-get update -y --no-install-recommends; echo '..installing docker'; sudo apt-get -y --no-install-recommends install curl apt-transport-https ca-certificates software-properties-common && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable' && sudo apt-get -y --no-install-recommends install docker-ce;
echo 'installing docker-compose'; sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose; echo 'Applying executable permissions to the docker-compose binary'; 
sudo chmod +x /usr/local/bin/docker-compose;
echo 'cloning the needed git repository'; git clone https://github.com/s0544505/nc-collabora-docker-compose.git; cd nc-collabora-docker-compose;
echo '..copying environmentvariables'; 
sed -e 's@ENV_POSTGRESUSER@'"$postgresqluservar"'@' -e 's@ENV_POSTGRESPW@'"$postgresqlpwvar"'@' -e 's@ENV_VIRTUALHOST@'"$ncdomainvar"'@' -e 's@ENV_LETSENCRYPTHOST@'"$ncdomainvar"'@' -e 's@ENV_LETSENCRYPTEMAIL@'"$lemailvar"'@' ./env_files/nc_db.env > ./nc_collabora_docker/nc_db.env;
sed -e 's@ENV_CVIRTUALHOST@'"$officedomainvar"'@' -e 's@ENV_DOMAIN@'"$ncdomainvar"'@' -e 's@ENV_HOSTNAME@'"$officedomainvar"'@' -e 's@ENV_LETSENCRYPTHOST@'"$officedomainvar"'@' -e 's@ENV_LETSENCRYPTEMAIL@'"$lemailvar"'@' ./env_files/collabora.env > ./nc_collabora_docker/collabora.env; 
echo 'running docker-compose';
cd nc_collabora_docker; docker-compose up -d"

echo "Overview of your specific settings:"
echo "rootuser: $rootuservar"
echo "Serveradress: $serveraddressvar"
echo "Fresh Created User: $newuservar" 
echo "Password of User $newuservar: $newuserpasswordvar"
echo "PostgreSQL-Databasepassword: $postgresqlpwvar"
echo "Your Nextcloud Domain: $ncdomainvar"
echo "Your Collabora-Code-Domain: $officedomainvar"
echo "Script ran successfully, the terminalwindow may be closed now.."

# in case you want to remove the env files (with all provided information) 
#ssh -tyq $newuservar@$serveraddressvar "sudo rm ./nc-collabora-docker-compose/nc_collabora_docker/collabora.env ; sudo rm ./nc-collabora-docker-compose/nc_collabora_docker/collabora.env"