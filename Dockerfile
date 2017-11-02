FROM ruby:2.3.5

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

WORKDIR /usr/src/app
COPY Gemfile Gemfile.lock ./

RUN gem install bundler && bundle install

EXPOSE 3000

COPY . .

CMD [ "bundle", "exec", "rails", "server", "-p", "3000", "-b", "0.0.0.0" ]

