FROM nginx:latest
COPY nginx.conf /etc/nginx/conf.d/default.conf.template
CMD envsubst '$ALB_DNS' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'
