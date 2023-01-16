log_format upstream_time '$remote_addr - $remote_user [$time_local] '
                            '"$request" $status $body_bytes_sent '
                            '"$http_referer" "$http_user_agent"'
                            'rt=$request_time uct="$upstream_connect_time" uht="$upstream_header_time" urt="$upstream_response_time"';

server {
    listen 80;
    server_name api.bookme.tk bookme.tk monitoring.bookme.tk;

    access_log /var/log/nginx/access.log upstream_time;
    error_log /var/log/nginx/error.log error;

    location /.well-known/acme-challenge/ {
        root /vol/www/;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}
