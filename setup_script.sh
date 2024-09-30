#!/bin/bash

# Function to generate a random string of 20 characters containing numbers and symbols
generate_random_string() {
  tr -dc 'A-Za-z0-9!@#$%^&*()_+{}|:<>?-=[];,./' < /dev/urandom | head -c 20
}

# Random string generated
RANDOM_STRING=$(generate_random_string)

# Check if the docker-compose.yml file exists
if [ -f "./pterodactyl/docker-compose.yml" ]; then
  # Replace "HASHID_CHANGEME" with the random string
  sed -i "s/HASHID_CHANGEME/$RANDOM_STRING/g" ./pterodactyl/docker-compose.yml
  echo "Replacement completed. The string 'HASHID_CHANGEME' has been replaced with '$RANDOM_STRING'."
else
  echo "File ./pterodactyl/docker-compose.yml not found!"
  exit 1
fi

# Check if the .env file exists
if [ -f "./.env" ]; then
  # Check for NGINX_INSTALLED variable
  NGINX_INSTALLED=$(grep -E '^NGINX_INSTALLED=' ./.env | cut -d '=' -f 2)
  if [ -z "$NGINX_INSTALLED" ]; then
    echo "Variable NGINX_INSTALLED not found in .env file."
    INSTALL_NGINX=true
  elif [ "$NGINX_INSTALLED" = "true" ]; then
    echo "NGINX_INSTALLED is set to true. Skipping Nginx installation."
    INSTALL_NGINX=false
  else
    INSTALL_NGINX=true
  fi

  # Check for SSL_CERT_DIR variable
  SSL_CERT_DIR=$(grep -E '^SSL_CERT_DIR=' ./.env | cut -d '=' -f 2)
  if [ -z "$SSL_CERT_DIR" ]; then
    echo "Variable SSL_CERT_DIR not found in .env file."
    exit 1
  else
    echo "SSL_CERT_DIR=$SSL_CERT_DIR"
  fi

  # Check for PANEL_DOMAIN variable
  PANEL_DOMAIN=$(grep -E '^PANEL_DOMAIN=' ./.env | cut -d '=' -f 2)
  if [ -z "$PANEL_DOMAIN" ]; then
    echo "Variable PANEL_DOMAIN not found in .env file."
    exit 1
  else
    echo "PANEL_DOMAIN=$PANEL_DOMAIN"
  fi

  # Check for NODE_DOMAIN variable
  NODE_DOMAIN=$(grep -E '^NODE_DOMAIN=' ./.env | cut -d '=' -f 2)
  if [ -z "$NODE_DOMAIN" ]; then
    echo "Variable NODE_DOMAIN not found in .env file."
    exit 1
  else
    echo "NODE_DOMAIN=$NODE_DOMAIN"
  fi
else
  echo ".env file not found!"
  exit 1
fi

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
  echo "Docker is not installed. Installing Docker..."

  # Install prerequisites
  sudo apt-get update
  sudo apt-get install -y curl apt-transport-https ca-certificates software-properties-common

  # Add Docker's official GPG key
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

  # Add Docker repository for Ubuntu
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

  # Update package index
  sudo apt-get update

  # Install Docker
  sudo apt-get install -y docker-ce

  # Enable Docker service
  sudo systemctl enable docker

  echo "Docker installation completed."
else
  echo "Docker is already installed."
fi
# Example: Configure pterodactyl.conf and node.conf files
# Create pterodactyl.conf
cat <<EOF | sudo tee /etc/nginx/sites-enabled/pterodactyl.conf
server {
    ssl_certificate $SSL_CERT_DIR/fullkey.pem;
    ssl_certificate_key $SSL_CERT_DIR/privkey.key;
    listen 443 ssl;
    server_name $PANEL_DOMAIN;

    location / {
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header X-Nginx-Proxy true;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_pass http://127.0.0.1:802;
    }
}
EOF

# Create node.conf
cat <<EOF | sudo tee /etc/nginx/sites-enabled/node.conf
server {
    ssl_certificate $SSL_CERT_DIR/fullkey.pem;
    ssl_certificate_key $SSL_CERT_DIR/privkey.key;
    listen 443 ssl;
    server_name $NODE_DOMAIN;

    # Add Alt-Svc headers to negotiate HTTP/3
    add_header Alt-Svc  'h3=":$server_port"; ma=3600, h2=":$server_port"; ma=3600';
    add_header Alt-Svc  'h2=":$server_port"; ma=2592000; persist=1';
    add_header Alt-Svc  'h2=":$server_port"; ma=2592000;';

    location ~ ^\/api\/servers\/(?<serverid>.*)?\/ws$ {
        proxy_pass http://127.0.0.1:8443/api/servers/\$serverid/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        client_max_body_size 50m;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        proxy_buffering off;
        proxy_request_buffering off;
    }

    location / {
        proxy_pass http://127.0.0.1:8443/;
        proxy_set_header Host \$host;
        client_max_body_size 50m;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
EOF

# Check Nginx configuration and restart if necessary
sudo nginx -t
sudo systemctl restart nginx

echo "Configuration completed successfully."

# Execute docker-compose.yml
echo "Starting docker-compose..."
cd ./pterodactyl
docker compose up -d

echo "docker compose started."
