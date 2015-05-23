#
# Copyright 2015, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'

describe PoiseBoiler::Helpers::Rake::Travis do
  rakefile "require 'poise_boiler/rakefile'"
  rake_task 'travis'
  file 'example.gemspec', <<-EOH
Gem::Specification.new do |s|
  s.name = 'example'
  s.version = '1.0.0'
end
EOH
  file '.kitchen.yml', <<-EOH
driver:
  name: dummy

provisioner:
  name: dummy

platforms:
- name: default

suites:
- name: default
EOH
  file 'README.md'

  context 'no secure vars' do
    environment TRAVIS_SECURE_ENV_VARS: ''

    its(:stdout) { is_expected.to include 'Running task spec' }
    its(:stdout) { is_expected.to include 'Running task chef:foodcritic' }
    its(:stdout) { is_expected.to_not include 'Running task travis:integration' }
    its(:exitstatus) { is_expected.to eq 0 }
  end # /context no secure vars

  context 'secure vars' do
    environment TRAVIS_SECURE_ENV_VARS: '1', KITCHEN_DOCKER_PASS: 'secret'
    file 'test/docker/docker.pem', <<-EOH
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: AES-256-CBC,AE2AED599B3951C641A08DBEA9584DDC

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
-----END RSA PRIVATE KEY-----
EOH

    its(:stdout) { is_expected.to include 'Running task spec' }
    its(:stdout) { is_expected.to include 'Running task chef:foodcritic' }
    if (ENV['BUNDLE_GEMFILE'] || '').include?('master')
      its(:stdout) { is_expected.to_not include 'Running task travis:integration' }
    else
      its(:stdout) { is_expected.to include 'Running task travis:integration' }
    end
    its(:exitstatus) { is_expected.to eq 0 }
  end # /context secure vars
end
