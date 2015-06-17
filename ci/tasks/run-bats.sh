#!/usr/bin/env bash

set -e

ensure_not_replace_value() {
  local name=$1
  local value=$(eval echo '$'$name)
  if [ "$value" == 'replace-me' ]; then
    echo "environment variable $name must be set"
    exit 1
  fi
}

ensure_not_replace_value base_os
ensure_not_replace_value network_type_to_test

cpi_release_name=bosh-vsphere-cpi

source /etc/profile.d/chruby.sh
chruby 2.1.2

source bosh-concourse-ci/pipelines/$cpi_release_name/$base_os-$network_type_to_test-exports.sh

#vsphere uses user/pass and the cdrom drive, not a reverse ssh tunnel
eval $(ssh-agent)
chmod go-r $BOSH_SSH_PRIVATE_KEY
ssh-add $BOSH_SSH_PRIVATE_KEY

echo "using bosh CLI version..."
bosh version

bosh -n target $BAT_DIRECTOR

sed -i.bak s/"uuid: replace-me"/"uuid: $(bosh status --uuid)"/ $BAT_DEPLOYMENT_SPEC

cd bats
bundle install
bundle exec rspec spec

#kill the SSH agent we started earlier
ssh-agent -k