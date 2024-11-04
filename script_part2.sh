#!/bin/bash

# Variables
DB_NAME="login_app"
DB_USER="root"        # Adjust for your MySQL username
DB_PASS="root"    # Adjust for your MySQL password

# Install apache 

apt install -y php8.2-fpm php8.2-mysql

# Configure MySQL for login

echo "Setting up MySQL database and user..."
mysql -u root -p$DB_PASS <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME;
USE $DB_NAME;
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL
);
INSERT INTO users (username, password) VALUES ('admin', 'supersecure');
EOF

# Create a  vulnerable login PHP form
tee /var/www/html/login.php > /dev/null <<EOF
<?php
\$servername = "localhost";
\$username = "$DB_USER";
\$password = "$DB_PASS";
\$dbname = "$DB_NAME";

// Create connection
\$conn = new mysqli(\$servername, \$username, \$password, \$dbname);

// Check connection
if (\$conn->connect_error) {
    die("Connection failed: " . \$conn->connect_error);
}

if (\$_SERVER["REQUEST_METHOD"] == "POST") {
    \$username = \$_POST['username'];
    \$password = \$_POST['password'];

    // Vulnerable SQL query (Time-based SQL Injection)
    \$sql = "SELECT * FROM users WHERE username = '\$username' AND password = '\$password'";
    \$result = \$conn->query(\$sql);

    if (\$result->num_rows > 0) {
        echo "Login successful!";
    } else {
        echo "Invalid credentials!";
    }
}

\$conn->close();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login</title>
</head>
<body>
    <h2>Login</h2>
    <form action="login.php" method="POST">
        <label for="username">Username:</label>
        <input type="text" id="username" name="username" required>
        <br><br>
        <label for="password">Password:</label>
        <input type="password" id="password" name="password" required>
        <br><br>
        <input type="submit" value="Login">
    </form>
</body>
</html>
EOF

# Configure NGINX
echo "Configuring NGINX..."
tee /etc/nginx/sites-available/default > /dev/null <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.php;

    server_name _;
	
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
    }
	
    location / {
        try_files \$uri \$uri/ =404;
    }

}
EOF

# Restart NGINX and PHP services
echo "Restarting NGINX and PHP services..."
systemctl restart nginx
systemctl restart php8.2-fpm  # Adjust for your PHP version if necessary
