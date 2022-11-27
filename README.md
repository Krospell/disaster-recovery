# Backup scripts for various needs
The scripts present in this repository may be used as a starting point for backing up databases.

- The `postgres` folder contains a script to backup a standalone PostgreSQL database. This script has to be used on the remote (backup receiver) server.
- The `mongodb` folder contains a script to backup a standalone MongoDB database in it's entirety. This script has to be used on the remote (backup receiver) server.
- The `docker-postgres` folder contains a script to backup a PostgreSQL database contained in a Docker installation. This script has to be used on the client (source host) server.

For more details about how these scripts work, please see the comments.

>Maintainer: <loan.joliveau@numigi.com>