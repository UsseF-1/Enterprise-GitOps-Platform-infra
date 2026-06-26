#!/bin/bash
set -euxo pipefail

# ===========================
# Kernel Configuration
# ===========================
cp /etc/sysctl.conf /root/sysctl.conf_backup || true

cat <<EOF >/etc/sysctl.conf
vm.max_map_count=262144
fs.file-max=65536
EOF

sysctl -p

cp /etc/security/limits.conf /root/sec_limit.conf_backup || true

cat <<EOF >/etc/security/limits.conf
sonar - nofile 65536
sonar - nproc 4096
EOF

# ===========================
# Update Packages
# ===========================
apt-get update -y

# ===========================
# Java 21
# ===========================
apt-get install -y openjdk-21-jdk

java -version

# ===========================
# Utilities
# ===========================
apt-get install -y \
curl \
wget \
unzip \
zip \
gnupg \
software-properties-common

# ===========================
# PostgreSQL
# ===========================
wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
> /etc/apt/sources.list.d/pgdg.list

apt-get update -y

apt-get install -y postgresql postgresql-contrib

systemctl enable postgresql
systemctl start postgresql

# ===========================
# PostgreSQL User
# ===========================
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='sonar'" | grep -q 1
then
    sudo -u postgres createuser sonar
fi

sudo -u postgres psql <<EOF
ALTER USER sonar WITH ENCRYPTED PASSWORD 'admin123';
EOF

if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='sonarqube'" | grep -q 1
then
    sudo -u postgres createdb -O sonar sonarqube
fi

sudo -u postgres psql <<EOF
GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;
EOF

systemctl restart postgresql

# ===========================
# Download SonarQube
# ===========================
mkdir -p /sonarqube
cd /sonarqube

curl -LO https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-26.4.0.121862.zip

unzip -o sonarqube-26.4.0.121862.zip -d /opt/

rm -rf /opt/sonarqube

mv /opt/sonarqube-26.4.0.121862 /opt/sonarqube

# ===========================
# Sonar User
# ===========================
getent group sonar >/dev/null || groupadd sonar

id sonar >/dev/null 2>&1 || \
useradd -c "SonarQube User" -d /opt/sonarqube -g sonar sonar

chown -R sonar:sonar /opt/sonarqube

chmod 1777 /tmp

# ===========================
# sonar.properties
# ===========================
cat <<EOF >/opt/sonarqube/conf/sonar.properties

sonar.jdbc.username=sonar
sonar.jdbc.password=admin123
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube

sonar.web.host=0.0.0.0
sonar.web.port=9000

sonar.web.javaAdditionalOpts=-server -Xmx1024m
sonar.search.javaOpts=-Xms512m -Xmx512m

sonar.log.level=INFO
sonar.path.logs=logs

EOF

# ===========================
# Systemd Service
# ===========================
cat <<EOF >/etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube
After=network.target

[Service]
Type=forking

ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

User=sonar
Group=sonar

Restart=always

LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl enable sonarqube

systemctl start sonarqube

# ===========================
# Nginx
# ===========================
apt-get install -y nginx

rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

cat <<EOF >/etc/nginx/sites-available/sonarqube
server {

    listen 80;

    server_name _;

    location / {

        proxy_pass http://127.0.0.1:9000;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

    }

}
EOF

ln -sf /etc/nginx/sites-available/sonarqube \
/etc/nginx/sites-enabled/sonarqube

systemctl enable nginx

systemctl restart nginx

# ===========================
# Firewall
# ===========================
if command -v ufw >/dev/null 2>&1
then
    ufw allow 80/tcp || true
    ufw allow 9000/tcp || true
fi

# ===========================
# Status
# ===========================
systemctl status postgresql --no-pager || true
systemctl status sonarqube --no-pager || true
systemctl status nginx --no-pager || true

echo "=========================================="
echo "SonarQube Installation Completed"
echo "Open: http://<EC2_PUBLIC_IP>:9000"
echo "Username: admin"
echo "Password: admin"
echo "=========================================="