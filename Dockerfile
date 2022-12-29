FROM ruby:2.1.4

RUN apt-get update && apt-get install -y --force-yes npm

# Ensure that we work in UTF 8
ENV LANG C.UTF-8 # ensure that the encoding is UTF8
ENV LANGUAGE C.UTF-8 # ensure that the encoding is UTF8

# Specify an external volume for the Application source
VOLUME ["/opt/library"]
WORKDIR /opt/library

# Use a persistent volume for the gems installed by the bundler
ENV BUNDLE_PATH /var/bundler
ENV RAILS_ENV development

ADD ./Gemfile /opt/library/Gemfile
#RUN bundle install

EXPOSE 3000

CMD ["tail", "-f", "/dev/null"]
