#!/usr/bin/env bash
# Build command for the Render web service. Render's pre-deploy command
# (the ideal home for migrations) requires a paid compute plan, so
# migrations run here during the free-tier build instead.
set -o errexit

bundle install

bin/rails assets:precompile

bin/rails db:migrate
