FROM ruby:2.2.3
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  nodejs \
  postgresql-client-9.4
RUN mkdir /myapp
WORKDIR /myapp
EXPOSE 3000
ADD Gemfile /myapp/Gemfile
ADD Gemfile.lock /myapp/Gemfile.lock
RUN bundle install
CMD ["bundle", "exec", "puma", "-p", "3000"]
