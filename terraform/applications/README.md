# Terraform configuration to provision the entire stack on AWS

## How to provision

1. Download and configure aws cli on your machine. You need a user for executing terraform commands and performing operations specified in bash scripts.
2. Go to the `base` folder and apply changes. You may override default values for variables. Outputs are needed to run scripts and provision other resoureces.
3. Login through AWS Console Manager to the ec2 jump host instance.
4. Connect to db and a create user that will be used for connecting to db from services. Never use master user for things other than db management.
5. Update api service config in `/api/service-config/api/production.env` with output values. URLs to db and redis for sure. Check other values too.
6. TBD

### TODO

- build base stack, add db user for app, update service-config, push config and docker image to aws, build backend stack
- make django app working with new resources like s3, user session in redis, current status: no db user, password authentication failed for user "bookme_user"
- make sure you follow security good practices
- Fix TLS certificate and domain, seems that it does not work now
- configure autoscaling of API service according to good practices, e.g CPU usage
- configure CI/CD with github actions, build docker image, push to registry, maybe trigger deployment automatically
- Improve logs configuration, add logs saving to relevant services, maybe save in s3 instead of CW
- configure allowed hosts, csrf etc. for django api container
- configure health checks for django api container
- configure s3 bucket as a remote state
- refactor the entire configuration
- add examples of service-config files
- enjoy the journey
