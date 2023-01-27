# Terraform configuration to provision the entire stack on AWS

## How to provision

1. Download and configure aws cli on your machine. You need a user for executing terraform commands and performing operations specified in bash scripts.
2. Go to the `base` folder and provision resources. You may override default values for variables. Outputs are needed to run scripts and provision other resoureces.
3. Change the db master user password. Terraform generated the random password for the master user. This password is exposed in the `.tfstate` file. After you change the master user password, the value in `.tfstate` will not be updated. Potential malicious actor will not be able to find the current password anymore. There are many ways to change the password. The easiest is to simply modify the master password in the db insatnce configuration in AWS console. It is fair enough for this project. In other cases like when using AWS Secrets Manager for storing the master user password procedure might be a bit different. [HERE](https://advancedweb.hu/how-to-remove-the-rds-master-user-password-from-the-terraform-state/) is a good article discussing the topic.
4. Connect to the ec2 bastion instance through the EC2 Instance Connect in AWS Console.
5. Connect to the default postgres db `psql -h <db instance url> -p <port:5432> -d postgres -U <master username specified when provisioning the db>`. You will be prompted to type the master user password.
   1. NOTE: It is forced to specify the database when connecting to postgres. Default postgres db is perfect for this.
6. Create a database `CREATE DATABASE book_me_prod;`.
   1. NOTE: Database name should consist of lowercase letters, numeric digits and underscores.
7. Create a user with required privileges for connecting to db from API services:
   1. `CREATE USER book_me_prod_api WITH PASSWORD '<some secure password>';`
   2. `ALTER ROLE book_me_prod_api SET client_encoding TO 'utf8';`
   3. `ALTER ROLE book_me_prod_api SET default_transaction_isolation TO 'read committed';`
   4. `ALTER ROLE book_me_prod_api SET timezone TO 'UTC';`
   5. `GRANT ALL PRIVILEGES ON DATABASE book_me_prod TO book_me_prod_api;`
   6. NOTE: `GRANT ALL PRIVILEGES` looks mighty, but it is not as powerful as it looks like. Reference [HERE](https://www.postgresql.org/docs/current/ddl-priv.html). Investigation if it makes sense to grant more strict privileges can a part of the security improvement process.
8. NOTE: Ultimately, steps 3-7 above should be automated with a script.
9. Update api service config in `/service-config/api/production.env` with output values. URLs to db and redis for sure. Check other values too.
10. Push api service config to the s3 bucket `/api/scripts/push_config_file_to_bucket.sh`.
11. Push backend app docker image to the ECR repository `/api/scripts/push_image_to_registry.sh`.
12. Go to `backend` folder and provision resources. You may need to specify values for required variables and override default values.
13. Connect to the ECS Fargate task running Django based API.
    1. When running ECS tasks on ec2 instances we can simply connect to the instance and run `docker exec -it`, but in case of ECS Fargate tasks it is more complicated. There is a ECS exec feature serving this purpose, but it requires additional setup. Before this feature was released, it was a hell to just get into container running on ECS Fargate.
    2. Useful resources, also for troubleshooting :) [(1)](https://aws.amazon.com/blogs/containers/new-using-amazon-ecs-exec-access-your-containers-fargate-ec2/)[(2)](https://aws.amazon.com/premiumsupport/knowledge-center/ecs-error-execute-command/)[(3)](https://www.simplethread.com/aws-ecs-exec-on-ecs-fargate-with-terraform/).
    3. In the third article author suggests to have a dedicated ECS task definition and run a dedicated ECS task for the time of managing the production environment with ECS exec. Thanks to this only the ECS exec task has a broader set of permissions. It is like having a separate ECS task for running db migrations.
    4. Example command to run:

    ```bash

    aws ecs execute-command  \
    --region eu-central-1 \
    --cluster book-me-prod-ecs-cluster \
    --task 03d11345e63f4cba8fb94e557a9ab0d6 \
    --container book-me-prod-api \
    --command "/bin/bash" \
    --interactive

14. Follow steps described in the **Initial setup of Django based API on production** section of the main README of this project.
15. TBD

### TODO

- make django app working with s3 as static and media storage, TESTING
- when deployed on prod, django shouts that CORS and CSRF config values should start from https:// or http:// or something.com
- configure allowed hosts, csrf etc. for django api container
- make sure you follow security good practices
- Fix TLS certificate and domain, seems that it does not work now
- configure CI/CD with github actions, build docker image, push to registry, maybe trigger deployment automatically
- Improve logs configuration, add logs saving to relevant services, maybe save in s3 instead of CW
- configure s3 bucket as a remote state
- refactor the entire configuration
- configure autoscaling of API service according to good practices, e.g CPU usage
- user session in redis, redis as broker, user session should work until we start scaling out the API container :)
- add password protection to redis, connection config in django app needs to be adjusted
- add examples of service-config files, move service-config folder to the root folder of the repo
- enjoy the journey
