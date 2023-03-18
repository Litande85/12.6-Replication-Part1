#!/bin/bash
# Установка MySql
sudo dnf update -y
sudo dnf install mysql mysql-server -y

#Создаем дирректорию для логов
sudo mkdir -p /var/log/mysql

#Инициализируем базу и даем права mysql
sudo mysqld --initialize
sudo chown -R mysql: /var/lib/mysql
sudo chown -R mysql: /var/log/mysql

#Вносим исправления в конфигурационный файл
#server-id=1  - для мастера
#server-id=2  - для slave

sudo tee -a /etc/my.cnf.d/mysql-server.cnf  <<-EOF
bind-address=0.0.0.0
server-id=1
log_bin=/var/log/mysql/mybin.log

EOF

#Включаем MySql
sudo systemctl start mysqld
sudo systemctl enable mysqld
