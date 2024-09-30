# pterodactyl-panel-wings-reverseproxy

# Setting Up Environment with setup_script.sh

This README provides step-by-step instructions to configure your environment using the `setup_script.sh` script on Ubuntu.

## Prerequisites

Before you begin, ensure you have:

- Access to a terminal on Ubuntu.
- Superuser permissions (or use `sudo` as needed).
- Internet connectivity to download additional resources (if required).
- A domain and a SSL certificate for it.

## Steps for Configuration

### Step 1: Download the `setup_script.sh` Script

Clone the repository

```bash
git clone https://github.com/jopnine/pterodactyl-panel-wings-reverseproxy.git
```

# Step 2: Grant Execution Permissions
Grant execution permissions to the setup script:

```bash
chmod +x setup_script.sh
```

# Step 3: Configure the .env File
Edit the .env file with your specific configurations. Here's a basic example:

```bash
NGINX_INSTALLED=false
SSL_CERT_DIR=/etc/nginx/ssl
PANEL_DOMAIN=painel.example.com
NODE_DOMAIN=node.example.com
```

Adjust the variables as necessary to reflect your domain settings and directory paths.

# Step 4: Execute the setup_script.sh Script
Run the setup_script.sh script to set up your environment:

```bash
./setup_script.sh
```

# Step 5: Verify the Configuration
Ensure the configuration has been successfully completed. This may involve checking Nginx installation, configuration file setups, and testing the expected service functionality.

# Final Considerations
This repository is just something to help people without much knowledge with docker and nginx to get things runnings fast.

```
php artisan p:user:make
```

# Credits

https://www.youtube.com/watch?v=cbr8tddvAWw
