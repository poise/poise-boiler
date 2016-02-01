#
# Copyright 2015-2016, Noah Kantrowitz
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
    file 'poise-boiler-test1.gemspec', <<-EOH
Gem::Specification.new do |spec|
  spec.name = 'poise-boiler-test1'
  spec.version = '1.0.0'
  spec.authors = ['Noah Kantrowitz']
  spec.email = %w{noah@coderanger.net}
  spec.description = %q||
  spec.summary = %q||
  spec.homepage = 'http://example.com/'
  spec.license = 'Apache 2.0'

  spec.files = []
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = []

  spec.add_dependency 'halite'
end
EOH
    file '.kitchen.yml', <<-EOH
---
#<% require 'poise_boiler' %>
<%= PoiseBoiler.kitchen %>
EOH

  context 'with defaults' do
    context 'kitchen list' do
      command 'kitchen list'
      its(:stdout) do
        is_expected.to match(/default-ubuntu-1404\s+(Vagrant|Dummy)\s+PoiseSolo\s+(Busser\s+Sftp\s+)?<Not Created>/)
        is_expected.to match(/default-ubuntu-1204\s+(Vagrant|Dummy)\s+PoiseSolo\s+(Busser\s+Sftp\s+)?<Not Created>/)
        is_expected.to match(/default-centos-6\s+(Vagrant|Dummy)\s+PoiseSolo\s+(Busser\s+Sftp\s+)?<Not Created>/)
        is_expected.to match(/default-centos-7\s+(Vagrant|Dummy)\s+PoiseSolo\s+(Busser\s+Sftp\s+)?<Not Created>/)
      end
    end # /context kitchen list

    context 'kitchen diagnose' do
      command 'kitchen diagnose'
      its(:stdout) do
        is_expected.to include('require_chef_omnibus: true')
      end
    end # /context kitchen diagnose
  end # /context with defaults

  context 'with a platform alias' do
    file '.kitchen.yml', <<-EOH
---
#<% require 'poise_boiler' %>
<%= PoiseBoiler.kitchen(platforms: 'centos') %>
EOH
    command 'kitchen list'
    its(:stdout) do
      is_expected.to_not match(/default-ubuntu-1404/)
      is_expected.to_not match(/default-ubuntu-1204/)
      is_expected.to match(/default-centos-6\s+(Vagrant|Dummy)\s+PoiseSolo\s+(Busser\s+Sftp\s+)?<Not Created>/)
      is_expected.to match(/default-centos-7\s+(Vagrant|Dummy)\s+PoiseSolo\s+(Busser\s+Sftp\s+)?<Not Created>/)
    end
  end # /context with a platform alias

  context 'with $CHEF_VERSION set' do
    command 'kitchen diagnose'
    environment CHEF_VERSION: 12
    its(:stdout) do
      is_expected.to include("require_chef_omnibus: '12'")
    end
  end # /context with $CHEF_VERSION set

  context 'with $CI set' do
    command 'kitchen diagnose'
    environment CI: true, SPEC_BLOCK_CI: false
    its(:stdout) do
      is_expected.to include("require_chef_omnibus: #{Chef::VERSION}")
    end
  end # /context with $CI set

  context 'with a platform override' do
    file '.kitchen.yml', <<-EOH
---
#<% require 'poise_boiler' %>
<%= PoiseBoiler.kitchen %>

platforms:
- name: gentoo
- name: arch
EOH
    command 'kitchen list'
    its(:stdout) do
      is_expected.to match(/default-gentoo\s+(Vagrant|Dummy)\s+PoiseSolo\s+(Busser\s+Sftp\s+)?<Not Created>/)
      is_expected.to match(/default-arch\s+(Vagrant|Dummy)\s+PoiseSolo\s+(Busser\s+Sftp\s+)?<Not Created>/)
    end
  end # /context with a platform override
end
