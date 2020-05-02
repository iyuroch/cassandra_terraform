You will need to setup creds file with access key and secret key and choose region.
This terraform will generate 3 instances (you can control count with count variable), security groups to allow internode connectivity and client connectivity as well as jumpserver.
You will need to configure cassandra by yourself. To connect use jumpserver. You will need to generate id_rsa in this folder to add public key

TODO:
0. Redo listen address to listen interface as we usually have one
1. Add configuration for cassandra-env.sh
2. Add template configuration of Cassandra
3. Add private/public subnet
4. Move to module
5. Add different id_rsa for instances
6. Add session manager policy
