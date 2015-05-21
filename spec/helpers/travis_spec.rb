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
suites: []
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
    environment TRAVIS_SECURE_ENV_VARS: '1'

    its(:stdout) { is_expected.to include 'Running task spec' }
    its(:stdout) { is_expected.to include 'Running task chef:foodcritic' }
    its(:stdout) { is_expected.to include 'Running task travis:integration' }
    its(:exitstatus) { is_expected.to eq 0 }
  end # /context secure vars
end
