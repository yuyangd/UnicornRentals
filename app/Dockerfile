FROM golang:alpine

ADD ./server /server
RUN chmod +x /server

ENTRYPOINT [ "/server" ]