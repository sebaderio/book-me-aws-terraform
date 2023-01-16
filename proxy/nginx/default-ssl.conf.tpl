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

server {
    listen      443 ssl;
    server_name api.bookme.tk;

    client_max_body_size 10M;
    access_log /var/log/nginx/access.log upstream_time;
    error_log /var/log/nginx/error.log error;

    ssl_certificate     /etc/letsencrypt/live/api.bookme.tk/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.bookme.tk/privkey.pem;

    include     /etc/nginx/options-ssl-nginx.conf;

    ssl_dhparam /vol/proxy/ssl-dhparams.pem;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    location /websockets/ {
        proxy_http_version 1.1;
        proxy_set_header Connection "upgrade";
        proxy_set_header Upgrade $http_upgrade;
        proxy_pass http://api:8000/websockets/;
    }

    location / {
        proxy_read_timeout 60;
        proxy_connect_timeout 60;
        proxy_send_timeout 60; 
        proxy_set_header Host $http_host;
        proxy_pass http://api:8000;
    }
}

server {
    listen      443 ssl;
    server_name bookme.tk;

    client_max_body_size 10M;
    access_log /var/log/nginx/access.log upstream_time;
    error_log /var/log/nginx/error.log error;

    ssl_certificate     /etc/letsencrypt/live/bookme.tk/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/bookme.tk/privkey.pem;

    include     /etc/nginx/options-ssl-nginx.conf;

    ssl_dhparam /vol/proxy/ssl-dhparams.pem;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    location / {
        root   /vol/html;
        index  index.html index.htm;
        try_files $uri $uri/ /index.html;
    }

    error_page   500 502 503 504  /50x.html;

    location /50x.html {
        root   /vol/html;
    }
}

server {
    listen      443 ssl;
    server_name monitoring.bookme.tk;

    client_max_body_size 10M;
    access_log /var/log/nginx/access.log upstream_time;
    error_log /var/log/nginx/error.log error;

    ssl_certificate     /etc/letsencrypt/live/monitoring.bookme.tk/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/monitoring.bookme.tk/privkey.pem;

    include     /etc/nginx/options-ssl-nginx.conf;

    ssl_dhparam /vol/proxy/ssl-dhparams.pem;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    location / {
        proxy_read_timeout 60;
        proxy_connect_timeout 60;
        proxy_send_timeout 60; 
        proxy_set_header Host $http_host;
        proxy_pass http://grafana:3000;
    }
}
