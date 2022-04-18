FROM ruby:2.6.3
# https://bundler.io/guides/bundler_2_upgrade.html#what-happens-if-my-application-needs-bundler-1-but-i-only-have-bundler-2-installed
RUN gem install bundler -v "~>1.0"
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /myapp
WORKDIR /myapp
ADD Gemfile /myapp/Gemfile
ADD Gemfile.lock /myapp/Gemfile.lock
RUN bundle install
