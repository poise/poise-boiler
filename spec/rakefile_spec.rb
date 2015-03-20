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

describe 'poise_boiler/rake' do
  file 'Rakefile', 'require "poise_boiler/rakefile"'
  file 'test.gemspec', <<-EOH
Gem::Specification.new do |spec|
  spec.name = 'test'
  spec.version = '1.0'
end
EOH

  describe 'list of tasks' do
    command 'rake -T'
    its(:stdout) { is_expected.to include('rake build') }
    its(:stdout) { is_expected.to include('rake chef:build') }
    its(:stdout) { is_expected.to include('rake chef:foodcritic') }
    its(:stdout) { is_expected.to include('rake chef:release') }
    its(:stdout) { is_expected.to include('rake install') }
    its(:stdout) { is_expected.to include('rake release') }
    its(:stdout) { is_expected.to include('rake spec') }
  end # /describe list of tasks

  describe 'specs in spec/' do
    command 'rake spec'
    file 'spec/thing_spec.rb', <<-EOH
describe 'a thing' do
  it { expect(1).to eq(1) }
end
EOH
    its(:stdout) { is_expected.to include('1 example, 0 failures') }
  end # /describe specs in spec/

  describe 'specs in test/spec/' do
    command 'rake spec'
    file 'test/spec/thing_spec.rb', <<-EOH
describe 'a thing' do
  it { expect(1).to eq(1) }
end
EOH
    its(:stdout) { is_expected.to include('1 example, 0 failures') }
  end # /describe specs in test/spec/

  describe 'specs in both spec/ and test/spec/' do
    command 'rake spec'
    file 'spec/thing_spec.rb', <<-EOH
describe 'a thing' do
  it { expect(1).to eq(1) }
end
EOH
    file 'test/spec/another_thing_spec.rb', <<-EOH
describe 'another thing' do
  it { expect(1).to eq(1) }
end
EOH
    its(:stdout) { is_expected.to include('2 examples, 0 failures') }
  end # /describe specs in both spec/ and test/spec/
end
