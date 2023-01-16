# **BookMe - hairdresser service booking platform**

App for matching hairdressers with potential clients. Backend in Django + Django Admin. Frontend in React. Monitoring covered by Prometheus + Grafana. Everything containerized and ready to run as a docker-compose stack. Auto renewal of SSL certificates with certbot.

## Deployment

Great tutorial [LONDON APP DEV](https://londonappdeveloper.com/django-docker-deployment-with-https-using-letsencrypt/) -> [YT VERSION](https://www.youtube.com/watch?v=3_ZJWlf25bY). Description here is an extended version of this tutorial adjusted for the BookMe use case.

1. Buy a free domain on www.freenom.com. Country will be quite unknown like `bookme.tk`, but it does not matter.
   1. When searching for a free domain you need to specify a full domain, with country code like `example.tk`. Otherwise you will see that the domain you are insterested in is not available in any country.
2. Add a ssh key pair for ec2 instances - import the public ssh key for your local machine. It is needed to log into ec2 instace via ssh.
   1. Other solution is to log into ec2 instance only through AWS management console.
3. Spin up AWS ec2 t2.micro instance with 25GB of disk space.No need of Elastic IP address. You just need Public IPv4 DNS address that is assigned automatically.
   1. Remember to specify the ssh key pair you just created.
4. Create a hosted zone in AWS Route 53 for the domain.
5. Create hosted zone A records pointing to the default name (hosted zone name) and subdomains like `api.bookme.tk`. All domains should target the ec2 instance Public IPv4 address.
   1. You can create CNAME record pointing to the Public IPv4 DNS address, but then you need to specify the subdomain.
   2. Remember that both Public IPv4 and Public IPv4 DNS addresses change when you shutdown and restart the ec2 instance! In case you don't want such behaviour you should use an instance offered by other cloud provider with a stable public IP address or purchase Elastic IP address in AWS.
6. Go to Freenom and configure custom domain nameservers for your domain. Take nameservers specified in the AWS hosted zone NS record. [Useful Link](https://medium.com/@kcabading/getting-a-free-domain-for-your-ec2-instance-3ac2955b0a2f). Nameserver is like a phonebook. DNS records are like phone numbers in the phonebook. By changing nameservers to AWS ones you move the management of DNS from Freenom to AWS hosted zone.
7. Log into ec2 instance `ssh ec2-user@<Public IPv4 DNS>`.
8. Run `ssh-keygen -t ed25519 -C 'Github BookMe Deploy key'` to generate a new ssh key.
9. Take the newly created ssh public key and add this key to the remote repo deploy keys. This way you grant access to the remote repo for the ec2 instance.
10. Run `sudo yum install -y git` to install git.
11. Pull the app repo from remote. Use ssh based URL.
12. Run `install_deps.sh` script. You might be prompted to type sudo password a few times.
13. Configure env vars for each container. Copy/paste the correct `env_vars/*-sample` file to the same directory, remove `-sample` suffix from the file name and specify correct values for variables in the file.
    1. Article explaining CORS configuration in Django [LINK](https://www.stackhawk.com/blog/django-cors-guide/#what-is-cors).
    2. The best would be to take a look at values that were specified for these variables on some server running in the past.
    3. Django app is configured to use Sendgrid as a mailing provider. Sendgrid offers free 100 emails/day and you can create custom email templates.
14. Check nginx config files and `run.sh` script located in the `proxy` directory. Adjust domain names and other values accordingly, if needed.
15. Run `make up-prod`. To see the full list of available commands run `make help`.
16. Containers should be running now. If there are some problems start investigation from checking docker container logs.
    1. It is possible that `prometheus` and `grafana` are dead because of missing permissions (check container logs). You need to run `sudo chmod og+w persistent_data/grafana/` and `sudo chmod og+w persistent_data/prometheus/`. This is not the best way to solve the issue, but works. Other way would be to e.g create a custom Dockerfile based on default docker image, add a new user and chown mounted volume's path to this user.
17. Django based API needs some manual steps to have it ready for the production use:
    1. Apply db migrations by running `make migrate-prod`.
    2. Collect static files needed to make Django Admin Panel working properly by running `make collectstatic-prod`.
    3. By default green Django theme is used, but theme should be changed to USWDS. Add USWDS theme by running `make django-prod cmd='loaddata admin_interface_theme_uswds.json'`.
    4. Change Django Admin Panel theme to USWDS:
       1. Login to Django Admin Panel using your admin account credentials.
       2. Go to Home -> Admin Interface -> Themes and change theme to USWDS.
       3. In case you don't have the admin account created yet you can create a superuser/admin account by running `make django-prod cmd=createsuperuser`.
       4. List of available themes [here](https://github.com/fabiocaccamo/django-admin-interface#optional-themes).
    5. Adjust texts and logos in Django Admin Panel to follow the context of the BookMe app. Go to Django Admin Panel -> Home -> Admin Interface -> Themes -> USWDS and change:
       1. Logo to the one located in `frontend/public/media/bookme_200_white.png`.
       2. Favicon to the one located in `frontend/public/media/bookme_200_white.png`.
       3. Title to `BookMe`.
18. Trigger `get_certbot_certificates.sh` script that creates ssl certificate in the cerbot container and saves this certificate in docker volume to make it reusable. After certificate is created you need to reload the proxy container to start using the newly created ssl certificate.
    1. There will be separate Let's Encrypt certificates for api, client and monitoring apps. Check scripts and nginx config to get more details
    2. It is possible to have only one certificate for all domains specified when generating the certificate, but I decided to generate separate ones.
    3. It is also possible to generate a wildcard SSL certificate that will be handling all subdomains. Such certificate do not use ACME, but DNS challenge. You need to configure DNS record of type TXT etc. More robust, but also more complicated to configure and setup auto-renewal.
    4. Channel on YT with many good tutorials about server configuration [LINK](https://www.youtube.com/watch?v=VJPfdXN-dSc).
19. Configure cron job to run `renew_certbot_certificates.sh` script to update the ssl certificate automatically:
    1. Run `crontab -e`.
    2. Add `0 0 * * 2 sh /home/ec2-user/book-me/scripts/renew_certbot_certificates.sh` to cron configuration to renew the certificate weekly at MON-TUE midnight.

## Additional Deployment Steps

These steps are not needed to have the production stack working. Follow the steps below to make the production stack more robust.

1. Configure custom dashboards in Grafana:
   1. Go to Grafana.
   2. Login. You should be able to login with initial credentials -> username: admin, password: admin. Then You have to change these credentials to more secure ones.
   3. Configure dashboards with charts and so on that will help you monitoring BookMe app.

## Code formatting and linting

There are linting tools configured to keep the python code in the same style across the entire BE part. Before merging new changes to the `develop` you should run `make format-api` to automatically format code e.g line lenght. After that you should run `make lint-api` to check if linting is correct and make changes accordingly if linting tools found some inconsistencies.

## Database ERD diagram

To see ERD diagram of the current database structure go to `resources/database_diagram/erd.png`.

## Manage database

#### Restore database from gzip dump:

```bash
gunzip < DUMP_NAME | sudo psql -h 0.0.0.0 -U <postgres-user> <db-name>
```

#### Restore database from plain dump:

```bash
cat DUMP_NAME | sudo psql -h 0.0.0.0 -U <postgres-user> <db-name>
```

#### Dump database to gzip:
```bash
sudo docker exec <container name> pg_dumpall -U <postgres-user> | gzip > <file name>.sql.gzip
```
