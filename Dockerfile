FROM ruby:2.1.4
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /library_mk5
WORKDIR /library_mk5
COPY Gemfile /library_mk5/Gemfile
COPY Gemfile.lock /library_mk5/Gemfile.lock
ENV RAILS_ENV docker
RUN bundle install
COPY . /library_mk5
