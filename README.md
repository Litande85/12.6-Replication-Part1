# Домашнее задание к занятию 12.6. «Репликация и масштабирование. Часть 1» - `Елена Махота`

- [Ответ к Заданию 1](#1)
- [Ответ к Заданию 2](#2)
- [Ответ к Заданию 3*](#3)

---

### Задание 1

На лекции рассматривались режимы репликации master-slave, master-master, опишите их различия.

*Ответить в свободной форме.*

### *<a name="1">Ответ к Заданию 1</a>*

| **Различия**                                     | **master-slave**                                                                                                                                                     | **master-master**                                                                                                                                                                               |
|--------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Чтение/Запись**                                | Master - Чтение/Запись, Slave - Чтение                                                                                                                               | Все ноды в режиме Чтение/Запись, нагрузка записи рапределена между обоими главными узлами                                                                                                       |
| **Последовательность и целостность базы данных** | Последовательность и целостность базы данных обеспечена, копии всей базы данных slave относительно не влияют на master                                               | Являются  слабо последовательными, могут возникать неразрешимые конфликты (например, при одновременном вводе, при вводе в перид потери связи), что приведет к нарушению целостности базы данных |
| **Отказоустойчивость при падении  master**       | Slave должен быть повышен до master, чтобы занять его место. Нет автоматической отработки отказа, может быть время простоя и возможно потеря данных при сбое мастера | Автоматическая и быстрая отработка отказа, все обращения на оставшийся мастер без потери данных                                                                                                 |

Использованные источники:

- https://stackoverflow.com/questions/3736969/master-master-vs-master-slave-database-architecture
- https://en.wikipedia.org/wiki/Multi-master_replication 

---

### Задание 2

Выполните конфигурацию master-slave репликации, примером можно пользоваться из лекции.

*Приложите скриншоты конфигурации, выполнения работы: состояния и режимы работы серверов.*


### *<a name="2">Ответ к Заданию 2</a>*

Создано две ноды `almalinux-9`:
1) master - makhota-vm20 10.128.0.20
2) slave - makhota-vm21 10.128.0.21

Устанавливаем MySql на обе ноды [mysql_alma.sh](mysql_alma.sh)

```bash
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
```

![status](img/img%202023-03-18%20224648.png)

Смотрим предустановленный пароль для `root@localhost`.

```bash
sudo cat /var/log/mysql/mysqld.log
```
![pass](img/img%202023-03-18%20225002.png)

Заходим в базу и меняем пароль, ставим одинаковый в обе ноды

```bash
sudo mysql -p
```

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY '11111';
FLUSH PRIVILEGES;
```

Создаем пользователя для репликации на обеих нодах

```sql
CREATE USER 'replication'@'%' IDENTIFIED WITH mysql_native_password BY '22222';
GRANT REPLICATION SLAVE ON *.* TO 'replication'@'%';
```

![replication](img/img%202023-03-18%20225408.png)

На мастере

```sql
SHOW MASTER STATUS;
```

На slave 

```sql
CHANGE MASTER TO MASTER_HOST='10.128.0.20', MASTER_USER='replication', MASTER_PASSWORD='22222', MASTER_LOG_FILE = 'mybin.000001', MASTER_LOG_POS = 1160;
START SLAVE;
SHOW SLAVE STATUS\G;
```

![slave](img/img%202023-03-18%20225923.png)

```sql

mysql> SHOW SLAVE STATUS\G;
*************************** 1. row ***************************
               Slave_IO_State: Waiting for source to send event
                  Master_Host: 10.128.0.20
                  Master_User: replication
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mybin.000001
          Read_Master_Log_Pos: 1160
               Relay_Log_File: makhota-vm21-relay-bin.000002
                Relay_Log_Pos: 322
        Relay_Master_Log_File: mybin.000001
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: 
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 1160
              Relay_Log_Space: 539
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
                  Master_UUID: 6a789412-c5c2-11ed-b97b-d00d12a003a1
             Master_Info_File: mysql.slave_master_info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Replica has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 
                Auto_Position: 0
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
       Master_public_key_path: 
        Get_master_public_key: 0
            Network_Namespace: 
1 row in set, 1 warning (0.00 sec)

ERROR: 
No query specified
```

![conf](img/img%202023-03-18%20230827.png)


![test](img/img%202023-03-18%20231802.png)


---

## Дополнительные задания (со звёздочкой*)
Эти задания дополнительные, то есть не обязательные к выполнению, и никак не повлияют на получение вами зачёта по этому домашнему заданию. Вы можете их выполнить, если хотите глубже шире разобраться в материале.

---

### Задание 3* 

Выполните конфигурацию master-master репликации. Произведите проверку.

*Приложите скриншоты конфигурации, выполнения работы: состояния и режимы работы серверов.*


### *<a name="3">Ответ к Заданию 3*</a>*


На мастере

```sql
CHANGE MASTER TO MASTER_HOST='10.128.0.21', MASTER_USER='replication', MASTER_PASSWORD='22222', MASTER_LOG_FILE = 'mybin.000001', MASTER_LOG_POS = 1163;
START SLAVE;
SHOW SLAVE STATUS\G;
```

![add master2](img/img%202023-03-19%20001907.png)

```sql
mysql> SHOW SLAVE STATUS\G;
*************************** 1. row ***************************
               Slave_IO_State: Waiting for source to send event
                  Master_Host: 10.128.0.21
                  Master_User: replication
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mybin.000001
          Read_Master_Log_Pos: 1163
               Relay_Log_File: makhota-vm20-relay-bin.000002
                Relay_Log_Pos: 322
        Relay_Master_Log_File: mybin.000001
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: 
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 1163
              Relay_Log_Space: 539
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 2
                  Master_UUID: fd711c4f-c5d0-11ed-9ed5-d00d64279f8d
             Master_Info_File: mysql.slave_master_info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Replica has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 
                Auto_Position: 0
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
       Master_public_key_path: 
        Get_master_public_key: 0
            Network_Namespace: 
1 row in set, 1 warning (0.01 sec)

ERROR: 
No query specified
```

![test2](img/img%202023-03-19%20002232.png)