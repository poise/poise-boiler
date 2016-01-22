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
require 'chef/version'

describe 'poise_boiler/kitchen' do
    environment SPEC_BLOCK_CI: true
    file '.kitchen.yml', <<-EOH
---
#<% require 'poise_boiler' %>
<%= PoiseBoiler.kitchen %>

suites:
- name: default
EOH

  context 'with defaults' do
    context 'kitchen list' do
      command 'kitchen list'
      its(:stdout) { is_expected.to match(/default-ubuntu-1404\s+(Vagrant|Dummy)\s+ChefSolo\s+(Busser\s+Sftp\s+)?<Not Created>/) }
    end # /context kitchen list

    context 'kitchen diagnose' do
      command 'kitchen diagnose'
      its(:stdout) { is_expected.to match(%r{- curl -L https://chef.io/chef/install.sh | bash -s --$}) }
      its(:stdout) { is_expected.to match(%r{/opt/chef/embedded/bin/gem\s+install\s+--no-rdoc\s+--no-ri\s+--bindir\s+/tmp/verifier/bin\s+thor\s+busser\s+busser-serverspec}m) }
      its(:stdout) { is_expected.to include('require_chef_omnibus: true') }
    end # /context kitchen diagnose
  end # /context with defaults

  context 'with a platform alias' do
    file '.kitchen.yml', <<-EOH
---
#<% require 'poise_boiler' %>
<%= PoiseBoiler.kitchen(platforms: 'linux') %>

suites:
- name: default
EOH
    command 'kitchen list'
    its(:stdout) { is_expected.to match(/default-ubuntu-1404\s+(Vagrant|Dummy)\s+ChefSolo\s+(Busser\s+Sftp\s+)?<Not Created>/) }
    its(:stdout) { is_expected.to match(/default-ubuntu-1204\s+(Vagrant|Dummy)\s+ChefSolo\s+(Busser\s+Sftp\s+)?<Not Created>/) }
    its(:stdout) { is_expected.to match(/default-centos-6\s+(Vagrant|Dummy)\s+ChefSolo\s+(Busser\s+Sftp\s+)?<Not Created>/) }
    its(:stdout) { is_expected.to match(/default-centos-7\s+(Vagrant|Dummy)\s+ChefSolo\s+(Busser\s+Sftp\s+)?<Not Created>/) }
  end # /context with a platform alias

  context 'with $CHEF_VERSION set' do
    command 'kitchen diagnose'
    environment CHEF_VERSION: 12
    its(:stdout) { is_expected.to match(%r{- curl -L https://chef.io/chef/install.sh | bash -s -- -v 12$}) }
    its(:stdout) { is_expected.to include("require_chef_omnibus: '12'") }
  end # /context with $CHEF_VERSION set

  context 'with $CI set' do
    command 'kitchen diagnose'
    environment CI: true, SPEC_BLOCK_CI: false
    its(:stdout) { is_expected.to match(%r{- curl -L https://chef.io/chef/install.sh | bash -s -- -v #{Chef::VERSION}$}) }
    its(:stdout) { is_expected.to include("require_chef_omnibus: #{Chef::VERSION}") }
  end # /context with $CI set

  context 'with a platform override' do
    file '.kitchen.yml', <<-EOH
---
#<% require 'poise_boiler' %>
<%= PoiseBoiler.kitchen %>

platforms:
- name: gentoo
- name: arch

suites:
- name: default
EOH
    command 'kitchen list'
    its(:stdout) { is_expected.to match(/default-gentoo\s+(Vagrant|Dummy)\s+ChefSolo\s+(Busser\s+Sftp\s+)?<Not Created>/) }
    its(:stdout) { is_expected.to match(/default-arch\s+(Vagrant|Dummy)\s+ChefSolo\s+(Busser\s+Sftp\s+)?<Not Created>/) }
  end # /context with a platform override
end
