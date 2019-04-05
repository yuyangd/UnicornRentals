
FROM nginx:1.15.10-alpine

# Remove origin default config
RUN rm /etc/nginx/conf.d/default.conf
RUN mkdir -p /app/cache/tmp && chown -R nginx /app/cache

COPY config /app/config
COPY run.sh /app/run.sh

CMD ["/app/run.sh"]

VOLUME /app/cache
EXPOSE 80