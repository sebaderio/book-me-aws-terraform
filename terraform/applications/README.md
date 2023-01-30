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
    --task 23a36a89ea4f4ce2b5ac3b3fe01c5b3d \
    --container book-me-prod-api \
    --command "/bin/bash" \
    --interactive

14. Follow steps described in the **Initial setup of Django based API on production** section of the main README of this project.
15. Confirm that API responds to health check request `curl https://<api-domain>/auth/ping/`.
16. Go to `frontend` folder and provision resources. You may need to specify values for required variables and override default values.
17. Push React client app static bundle to the s3 bucket `/frontend/scripts/push_client_app_to_bucket.sh`.
18. Confirm that client app is hosted properly, SSL certificate is valid and API - client app integration works as expected. Go to `https://<client-app-domain>` and play with the app.

## Notes

1. I tried to use as much of AWS Free Tier as possible, but some of provisioned resources may be costly even when there is no load because of per hour price + additional charge based on usage. NAT gateway and VPC endpoints cost at least a few $ per month.

## TODO

Currently this project can be described as a good foundation for a production-grade solution. There are a few things to do.

1. Configure CI/CD to automatically build, push and deploy the newest version of the app after merge.
2. Configure autoscaling of API service according to good practices e.g based on CPU usage.
3. Review and improve logging. Consider saving logs in S3 instead of CW.
4. Configure S3 bucket as a remote state for terraform configuration. Remember that there are sensitive values in tfstate files.
5. Configure encryption at rest and in transit for config_s3_bucket.
6. Check the entire codebase and consider what else should be done.

## Application specific issues

There are a few, application specific issues that should be resolved before going live. I decided to skip these steps, because the goal was to practice Terraform + AWS.

1. Django user session should be stored in redis instead of container's memory. With current configuration user session will not work properly when you start scaling out the API container. Another, temporary, quick fix solution would be to configure really long stickiness on load balancer level.
   1. [https://django-redis-cache.readthedocs.io/en/latest/index.html](https://django-redis-cache.readthedocs.io/en/latest/index.html)
   2. [https://stackoverflow.com/questions/39408722/how-to-connect-to-redis-in-django](https://stackoverflow.com/questions/39408722/how-to-connect-to-redis-in-django)
   3. [https://stackoverflow.com/questions/36725037/django-user-sessions-with-aws-load-balancer-stickiness-turned-off](https://stackoverflow.com/questions/36725037/django-user-sessions-with-aws-load-balancer-stickiness-turned-off)
2. When using S3 bucket as static and media storage, "This backend does not support absolute paths" exception is thrown when app handles images added by clients. It is a known issue when using s3 bucket storage.
   1. [https://forum.djangoproject.com/t/django-this-backend-doesnt-support-absolute-paths-after-integrating-aws-s3-bucket/11245](https://forum.djangoproject.com/t/django-this-backend-doesnt-support-absolute-paths-after-integrating-aws-s3-bucket/11245)
   2. [https://stackoverflow.com/questions/52867574/django-backend-doesnt-support-absolute-paths](https://stackoverflow.com/questions/52867574/django-backend-doesnt-support-absolute-paths)
3. Hosting React client app in S3 bucket and serving through CloudFront works, but the current solution is not SEO optimized. I did a workaround to make the app working, but community suggests another, far better workaround that requires code changes.
   1. See the comment in `/terraform/applications/frontend/main.tf:client_app_s3_bucket` explaining the problem.
4. Run Celery ECS service as background worker handling tasks. See `/terraform/applications/backend/main.tf:service_api` configuration. Reformat `ecs-fargate-service` to make it even more reusable and configure celery service based on this module. Both API and Celery services should use the same docker image and environment variables. The main difference are: command run in each container, exposed ports, CPU and memory configuration. See `/docker-compose.yml` to better understand similarities and differences between API and Celery services.
