# Settings to configure

AWS_S3_REGION_NAME=AWS region, it probably makes sense to set it to the same region in which the s3 bucket is located  
AWS_S3_ACCESS_KEY_ID=Access key id generated for the IAM user with read-write permissions to the s3 bucket  
AWS_S3_SECRET_ACCESS_KEY=Secret access key generated for the IAM user with read-write permissions to the s3 bucket  
AWS_S3_STORAGE_BUCKET_NAME=Name of already created bucket for storing static and media content  
AWS_S3_CUSTOM_DOMAIN=You need to configure a custom domain when hosting files through CloudFront # Optional  
BROKER_URL=broker URL e.g redis://something  
CELERY_LOG_LEVEL=celery log level (default WARNING) # Optional  
DJANGO_ALLOWED_HOSTS=list of allowed hosts e.g *. Specify the domain name pointing to the server on which the Django app  
DJANGO_CORS_ALLOW_CREDENTIALS=true or false, allows to pass cookies with HTTP request  
DJANGO_CORS_ORIGIN_ALLOW_ALL=false or true, makes it possible to allow all client hosts to send requests  
DJANGO_CORS_ALLOWED_ORIGINS= list of origins that can send requests to the Django app, applies when DJANGO_CORS_ORIGIN_ALLOW_ALL is set to false. [See article.](https://www.stackhawk.com/blog/django-cors-guide/)  
DJANGO_CSRF_TRUSTED_ORIGINS=list of origins that can send requests to the Django app. [See Django docs.](https://docs.djangoproject.com/en/4.0/ref/settings/#csrf-trusted-origins)  
DJANGO_DEBUG=debug mode (default False) # Optional  
DJANGO_LOG_LEVEL=django log level (default WARNING) # Optional  
DJANGO_SECRET_KEY=django secret key  
POSTGRES_DB=postgres database name  
POSTGRES_HOST=database service hostname  
POSTGRES_PASSWORD=postgres database password  
POSTGRES_PORT=database port number  
POSTGRES_USER=postgres database user  
SENDGRID_API_KEY=mailing service provider api key  
SENDGRID_SENDER_EMAIL=email address to be used to send emails from  
SENDGRID_ACCOUNT_ACTIVATION_TEMPLATE_ID=email html template id to be used when sending account activation emails  
TARGET_ENV=one of `production` or `development`  

## Notes

1. AWS settings are needed only when TARGET_ENV is set to `production`.
