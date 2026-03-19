FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y gnucobol4 curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN cobc -free -x -o hello hello.cob

EXPOSE 8080
CMD ["./hello"]
