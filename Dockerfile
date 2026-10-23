FROM ruby:3.3.12-slim-trixie@sha256:4fe029f46a87c5e4a72d3b2ae18345852d6141344013308887eef1ebc1e18d32 AS base

ENV BUNDLE_DEPLOYMENT=true \
    BUNDLE_PATH=/usr/local/bundle \
    JEKYLL_BUILD_REVISION=local \
    PAGES_REPO_NWO=yuu-eguci/lorem-markdown-pages
WORKDIR /srv/site

FROM base AS gems

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock ./
RUN bundle install && rm -rf /usr/local/bundle/cache

FROM base

RUN apt-get update \
    && apt-get install -y --no-install-recommends chromium-headless-shell \
    && rm -rf /var/lib/apt/lists/*
COPY --from=gems /usr/local/bundle /usr/local/bundle
RUN useradd --create-home --uid 1000 site
USER site

EXPOSE 4000
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--destination", "/tmp/site", "--force_polling"]
