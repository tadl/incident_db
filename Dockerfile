ARG RUBY_VERSION=3.4.13
FROM ruby:${RUBY_VERSION}-slim-bookworm AS base

WORKDIR /app
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT=development:test

RUN apt-get update && \
    apt-get install --no-install-recommends -y libpq5 libvips42 && \
    rm -rf /var/lib/apt/lists/*

FROM base AS build

RUN apt-get update && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

COPY .ruby-version Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache

COPY . .
RUN SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile && rm -rf log tmp

FROM base

RUN groupadd --gid 10001 rails && \
    useradd --uid 10001 --gid 10001 --create-home --shell /bin/bash rails

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app
RUN mkdir -p log tmp/pids tmp/cache storage && \
    chown -R rails:rails log tmp storage

USER rails:rails
ENV PORT=5000
EXPOSE 5000
CMD ["bundle", "exec", "puma"]
