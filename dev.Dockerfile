FROM alejandrochen97/compilers:3.1.0
WORKDIR /futureJudge

ENV RAILS_ENV=development
ENV USE_DOCS_AS_HOMEPAGE=true
ENV JUDGE0_VERSION="2.0.3"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libpq-dev \
    sudo && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile* ./
COPY Rakefile ./
RUN bundle install

# Entrypoint prepares the database.
ENTRYPOINT ["/futureJudge/bin/docker-entrypoint"]

CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
