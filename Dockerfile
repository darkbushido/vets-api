FROM ruby:2.7-slim

# Allow for setting ENV vars via --build-arg
ARG BUNDLE_ENTERPRISE__CONTRIBSYS__COM \
  RAILS_ENV=development \
  USER_ID=1000
ENV RAILS_ENV=$RAILS_ENV \
  BUNDLE_ENTERPRISE__CONTRIBSYS__COM=$BUNDLE_ENTERPRISE__CONTRIBSYS__COM \
  BUNDLER_VERSION=2.1.4

RUN groupadd --gid $USER_ID nonroot \
  && useradd --uid $USER_ID --gid nonroot --shell /bin/bash --create-home nonroot --home-dir /app

WORKDIR /app

# Download VA Certs
RUN wget -q -r -np -nH -nd -a .cer -P /usr/local/share/ca-certificates http://aia.pki.va.gov/PKI/AIA/VA/ \
  && for f in /usr/local/share/ca-certificates/*.cer; do openssl x509 -inform der -in $f -out $f.crt; done \
  && update-ca-certificates \
  && rm .cer

# Download and install libs and deps
RUN apt-get update \
    && apt-get install -y libpq-dev git imagemagick curl wget pdftk file wget xz-utils cmake gcc build-essential libfontconfig1-dev pkg-config libjpeg-dev gnome-common libglib2.0-dev gtk-doc-tools libyelp-dev yelp-tools gobject-introspection libsecret-1-dev libnautilus-extension-dev libopenjp2-7 libopenjp2-7-dev libboost-all-dev

# Download and compile Poppler
RUN wget http://poppler.freedesktop.org/poppler-21.11.0.tar.xz \
    && unxz poppler-21.11.0.tar.xz \
    && tar xf poppler-21.11.0.tar \
    && cd poppler-21.11.0 \
    && cmake   -DCMAKE_BUILD_TYPE=Release   \
            -DENABLE_XPDF_HEADERS=ON \
    && make install \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Relax ImageMagick PDF security. See https://stackoverflow.com/a/59193253.
RUN sed -i '/rights="none" pattern="PDF"/d' /etc/ImageMagick-6/policy.xml

COPY config/clamd.conf /etc/clamav/clamd.conf

ENV LANG=C.UTF-8 \
   BUNDLE_JOBS=4 \
   BUNDLE_PATH=/usr/local/bundle/cache \
   BUNDLE_RETRY=3

RUN gem install bundler:${BUNDLER_VERSION} --no-document

RUN wget -q https://vets-api-build-artifacts.s3-us-gov-west-1.amazonaws.com/bundle_cache.tar.bz2 -O - \
  | tar -xjvf - -C /usr/local/bundle/
COPY modules ./modules
COPY Gemfile Gemfile.lock ./
RUN bundle install \
  && rm -rf /usr/local/bundle/cache/*.gem \
  && find /usr/local/bundle/gems/ -name "*.c" -delete \
  && find /usr/local/bundle/gems/ -name "*.o" -delete \
  && find /usr/local/bundle/gems/ -name ".git" -type d -prune -execdir rm -rf {} +
COPY --chown=nonroot:nonroot . .

EXPOSE 3000

USER nonroot

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
