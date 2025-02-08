#!/usr/bin/env bash

# Creates a self-signed certificate with a 10-year validity period.
generate_self_signed_cert() {
    selfSignDomainName="localhost"
    selfSignDomainIp="127.0.0.1"
    openssl req -x509 \
        -newkey rsa\:4096 \
        -sha256 \
        -nodes \
        -days 3650 \
        -keyout .certs/${selfSignDomainName}.key \
        -out .certs/${selfSignDomainName}.pem \
        -subj "/CN=${selfSignDomainName}" \
        -addext "subjectAltName=DNS\:${selfSignDomainName},DNS\:*.${selfSignDomainName},IP\:${selfSignDomainIp}"
}

copy_example_files() {
    find .envs/ -type f | grep -Po '([a-z\-]+)(?=.example.env)' | xargs -i cp --update=none .envs/{}.example.env .envs/{}.env
    cp --update=none .env.example .env
    cp --update=none docker-compose.override.example.yml docker-compose.override.yml
}

nginx_add_otel() {
    # Remove empty lines from start of file
    sed -i '/./,$!d' ./nginx/etc-nginx/nginx.conf

    # Remove multiple empty lines to 1 line
    sed -i '/^$/N;/^\n$/D' ./nginx/etc-nginx/nginx.conf

    sed -i '1s/^/load_module modules\/ngx_otel_module.so;\n\n/' ./nginx/etc-nginx/nginx.conf

    sed -i '/include \/etc\/nginx\/conf.d\/\*.conf/i \
    otel_service_name app:nginx;\
    otel_span_name "$request_method $request_uri";\
    otel_trace on;\
    otel_trace_context propagate;\
    otel_exporter {\
        endpoint localhost:4317;\
    }\
' ./nginx/etc-nginx/nginx.conf

    # Add otel image tag suffix
    sed -i 's/^#\s*NGINX_TAG_SUFFIX/NGINX_TAG_SUFFIX/' ./.env
    sed -i 's/^\(NGINX_TAG_SUFFIX=.*\)/\1-otel/' ./.env
}

nginx_remove_otel() {
    sed -i '/load_module modules\/ngx_otel_module.so;/d' ./nginx/etc-nginx/nginx.conf

    sed -i '/otel_service_name app:nginx;/d' ./nginx/etc-nginx/nginx.conf
    sed -i '/otel_span_name "$request_method $request_uri";/d' ./nginx/etc-nginx/nginx.conf
    sed -i '/otel_trace on;/d' ./nginx/etc-nginx/nginx.conf
    sed -i '/otel_trace_context propagate;/d' ./nginx/etc-nginx/nginx.conf
    sed -i '/otel_exporter {/,/}/d' ./nginx/etc-nginx/nginx.conf

    # Remove multiple empty lines to 1 line
    sed -i '/^$/N;/^\n$/D' ./nginx/etc-nginx/nginx.conf

    # Remove empty lines from start of file
    sed -i '/./,$!d' ./nginx/etc-nginx/nginx.conf

    # Remove otel image tag suffix
    sed -i 's/^\(NGINX_TAG_SUFFIX=.*\)-otel/\1/' ./.env
    sed -i 's/^\s*NGINX_TAG_SUFFIX/# NGINX_TAG_SUFFIX/' ./.env
}

if [ $# -eq 0 ]; then
    declare -a execSequence=("generate_self_signed_cert" "copy_example_files")
    for func in "${execSequence[@]}"; do
        $func
    done
else
    if declare -f "$1" > /dev/null; then
        "$1"
    else
        echo "Error: Function '$1' does not exist."
        exit 1
    fi
fi
