# Settings to configure

REACT_APP_REST_API_BASE_URL=https API base URL  
REACT_APP_WS_API_BASE_URL=websocket API base URL  

## DEV ENV ONLY

`CHOKIDAR_USEPOLLING=true` forces react app to use polling to watch file changes.
It isn't the optimal solution. There is a significant delay for hot reloading and higher CPU usage.
False is default. If hot reload works fine there is no need to set this env to true.

## Notes

1. Only custom env vars starting with `REACT_APP_` are embedded during the build time. It means that values of all other custom env vars used in the code will have "undefined" value. If you host the React client app statically, e.g in s3 bucket, use env vars with `REACT_APP` prefix.
