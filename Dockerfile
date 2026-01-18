FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    fpc \
    make \
    git \
    binutils \
    && rm -rf /var/lib/apt/lists/*

# Remove system Free Vision to avoid conflicts with fv_utf8
RUN rm -rf /usr/lib/fpc/*/units/*/fv

WORKDIR /app
COPY . /app

RUN make clean && make

CMD ["./niki"]
