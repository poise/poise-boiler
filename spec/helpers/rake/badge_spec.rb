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

describe PoiseBoiler::Helpers::Rake::Badges do
  describe '#detect_github' do
    let(:instance) { described_class.new(gem_name: '', base: '') }
    subject { instance.send(:detect_github) }

    context 'with normal data' do
      before do
        expect(instance).to receive(:git_shell_out).with(%w{name-rev --name-only HEAD}).and_return('master')
        expect(instance).to receive(:git_shell_out).with(%w{config --get branch.master.remote}).and_return('origin')
        expect(instance).to receive(:git_shell_out).with(%w{ls-remote --get-url origin}).and_return('git@github.com:poise/example.git')
      end
      it { is_expected.to eq 'poise/example' }
    end # /context with normal data

    context 'with no default remote' do
      before do
        expect(instance).to receive(:git_shell_out).with(%w{name-rev --name-only HEAD}).and_return('master')
        expect(instance).to receive(:git_shell_out).with(%w{config --get branch.master.remote}).and_return('')
        expect(instance).to receive(:git_shell_out).with(%w{ls-remote --get-url origin}).and_return('git@github.com:poise/example.git')
      end
      it { is_expected.to eq 'poise/example' }
    end # /context with no default remote

    context 'with an HTTP remote' do
      before do
        expect(instance).to receive(:git_shell_out).with(%w{name-rev --name-only HEAD}).and_return('master')
        expect(instance).to receive(:git_shell_out).with(%w{config --get branch.master.remote}).and_return('')
        expect(instance).to receive(:git_shell_out).with(%w{ls-remote --get-url origin}).and_return('https://github.com/poise/example.git')
      end
      it { is_expected.to eq 'poise/example' }
    end # /context with an HTTP remote
  end # /describe #detect_github

  describe 'integration' do
    rakefile "require 'poise_boiler/rakefile'"
    rake_task 'badges'
    before do
      command(%w{git init})
      command(%w{git remote add origin git@github.com:poise/example.git})
    end

    context 'non-cookbook' do
      file 'example.gemspec', <<-EOH
Gem::Specification.new do |s|
  s.name = 'example'
  s.version = '1.0.0'
end
EOH
      its(:stdout) { is_expected.to eq <<-EOH }
[![Build Status](https://img.shields.io/travis/poise/example.svg)](https://travis-ci.org/poise/example)
[![Gem Version](https://img.shields.io/gem/v/example.svg)](https://rubygems.org/gems/example)
[![Code Climate](https://img.shields.io/codeclimate/github/poise/example.svg)](https://codeclimate.com/github/poise/example)
[![Coverage](https://img.shields.io/codecov/c/github/poise/example.svg)](https://codecov.io/github/poise/example)
[![Gemnasium](https://img.shields.io/gemnasium/poise/example.svg)](https://gemnasium.com/poise/example)
[![License](https://img.shields.io/badge/license-Apache_2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
EOH
      its(:stderr) { is_expected.to eq '' }
      its(:exitstatus) { is_expected.to eq 0 }
    end # /context non-cookbook

    context 'cookbook' do
      file 'example.gemspec', <<-EOH
Gem::Specification.new do |s|
  s.name = 'example'
  s.version = '1.0.0'
  s.add_dependency 'halite'
end
EOH
      its(:stdout) { is_expected.to eq <<-EOH }
[![Build Status](https://img.shields.io/travis/poise/example.svg)](https://travis-ci.org/poise/example)
[![Gem Version](https://img.shields.io/gem/v/example.svg)](https://rubygems.org/gems/example)
[![Cookbook Version](https://img.shields.io/cookbook/v/example.svg)](https://supermarket.chef.io/cookbooks/example)
[![Code Climate](https://img.shields.io/codeclimate/github/poise/example.svg)](https://codeclimate.com/github/poise/example)
[![Coverage](https://img.shields.io/codecov/c/github/poise/example.svg)](https://codecov.io/github/poise/example)
[![Gemnasium](https://img.shields.io/gemnasium/poise/example.svg)](https://gemnasium.com/poise/example)
[![License](https://img.shields.io/badge/license-Apache_2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
EOH
      its(:stderr) { is_expected.to eq '' }
      its(:exitstatus) { is_expected.to eq 0 }
    end # /context cookbook
  end # /describe integration
end
