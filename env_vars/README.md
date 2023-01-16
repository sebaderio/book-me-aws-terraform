# Env samples for each docker container that requires some env variables to be specified

1. Just copy/paste the content of `-sample` file, remove the `-sample` suffix and specify a correct value for each env variable.

## Notes

1. Reduncancy, but it makes configuring env vars simple and we are sure that only required env vars are passed to the container.
2. `env_file` parameter specified in the docker-compose file only passes env vars to the container, but you cannot use these env vars in docker-compose file itself. e.g `${CELERY_LOG_LEVEL}` is not possible, even if this setting is specified in the file with env vars. In case you want reference env vars in docker-compose file, you need to specify env vars in `.env` that is used implicitly or configure env vars straight in the docker-compose.
