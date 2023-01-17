# **BookMe - hairdresser service booking platform**

App for matching hairdressers with potential clients. Backend in Django + Django Admin. Frontend in React. Everything containerized and ready to run as a docker compose stack in the development environment. For the production use there is a dedicated, AWS + Terraform configuration.

## Deployment AWS with Terraform

1. TODO

## Running the stack locally

1. Run `sudo yum install -y git` to install git.
2. Pull the app repo from remote. Use ssh based URL.
3. Run `install_deps.sh` script. You might be prompted to type sudo password a few times.
4. Configure env vars for each container. Copy/paste the correct `env_vars/*-sample` file to the same directory, remove `-sample` suffix from the file name and specify correct values for variables in the file.
    1. Article explaining CORS configuration in Django [LINK](https://www.stackhawk.com/blog/django-cors-guide/#what-is-cors).
    2. The best would be to take a look at values that were specified for these variables on some server running in the past.
    3. Django app is configured to use Sendgrid as a mailing provider. Sendgrid offers free 100 emails/day and you can create custom email templates.
5. Run `make up-dev`. To see the full list of available commands run `make help`.
6. Django based API needs some manual steps to have it ready for the production-like use:
    1. Apply db migrations by running `make migrate-dev`.
    2. Collect static files needed to make Django Admin Panel working properly by running `make collectstatic-dev`.
    3. By default green Django theme is used, but theme should be changed to USWDS. Add USWDS theme by running `make django-dev cmd='loaddata admin_interface_theme_uswds.json'`.
    4. Change Django Admin Panel theme to USWDS:
       1. Login to Django Admin Panel using your admin account credentials.
       2. Go to Home -> Admin Interface -> Themes and change theme to USWDS.
       3. In case you don't have the admin account created yet you can create a superuser/admin account by running `make django-dev cmd=createsuperuser`.
       4. List of available themes [here](https://github.com/fabiocaccamo/django-admin-interface#optional-themes).
    5. Adjust texts and logos in Django Admin Panel to follow the context of the BookMe app. Go to Django Admin Panel -> Home -> Admin Interface -> Themes -> USWDS and change:
       1. Logo to the one located in `frontend/public/media/bookme_200_white.png`.
       2. Favicon to the one located in `frontend/public/media/bookme_200_white.png`.
       3. Title to `BookMe`.

## Code formatting and linting

There are linting tools configured to keep the python code in the same style across the entire BE part. Before merging new changes to the `develop` you should run `make format-api` to automatically format code e.g line lenght. After that you should run `make lint-api` to check if linting is correct and make changes accordingly if linting tools found some inconsistencies.

## Manage database

### Restore database from gzip dump

```bash
gunzip < DUMP_NAME | sudo psql -h 0.0.0.0 -U <postgres-user> <db-name>
```

#### Restore database from plain dump

```bash
cat DUMP_NAME | sudo psql -h 0.0.0.0 -U <postgres-user> <db-name>
```

### Dump database to gzip

```bash
sudo docker exec <container name> pg_dumpall -U <postgres-user> | gzip > <file name>.sql.gzip
```
