FROM rustlang/rust:nightly

RUN apt-get update -y && \
    apt-get install -y libclang-dev llvm-dev

RUN mkdir chatter

WORKDIR /chatter

# copy over your manifests
COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml

RUN mkdir src && echo "fn main() {}" > src/main.rs && echo "\n" > src/lib.rs

# this build step will cache your dependencies
RUN cargo build --release
RUN rm src/*.rs

# copy your source tree
COPY ./ ./

# build for release
RUN cargo build --release

CMD ["./target/release/chatter"]