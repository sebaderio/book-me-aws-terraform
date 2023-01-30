from storages.backends import s3boto3


class StaticStorage(s3boto3.S3Boto3Storage):
    location = 'static'
    default_acl = 'public-read'


class MediaStorage(s3boto3.S3Boto3Storage):
    location = 'media'
    default_acl = 'public-read'
