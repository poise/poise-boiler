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

describe 'poise_boiler/spec_helper' do
  command 'rspec'
  # This is mostly to test the harness is working correctly
  context 'simple spec' do
    file 'spec/test_spec.rb', <<-EOH
describe 'a thing' do
  it { expect(1).to eq(1) }
end
EOH
    its(:stdout) { is_expected.to include('1 example, 0 failures') }
  end # /context simple spec

  context 'with poise_boiler/spec_helper' do
    file 'spec/spec_helper.rb', 'require "poise_boiler/spec_helper"'
    file 'spec/test_spec.rb', <<-EOH
require 'spec_helper'
describe 'a thing' do
  it { expect(1).to eq(1) }
end
EOH
    its(:stdout) { is_expected.to include('1 example, 0 failures') }
  end # /context with poise_boiler/spec_helper

  context 'using the Halite helper' do
    file 'spec/spec_helper.rb', 'require "poise_boiler/spec_helper"'
    file 'spec/test_spec.rb', <<-EOH
require 'spec_helper'
describe 'a thing' do
  recipe do
    ruby_block 'test'
  end
  it { is_expected.to run_ruby_block('test') }
end
EOH
    its(:stdout) { is_expected.to include('1 example, 0 failures') }
  end # /context using the Halite helper

  context 'with the Halite helper disabled' do
    file 'spec/spec_helper.rb', <<-EOH
require 'poise_boiler'
PoiseBoiler.include_halite_spec_helper = false
require "poise_boiler/spec_helper"'
EOH
    file 'spec/test_spec.rb', <<-EOH
require 'spec_helper'
describe 'a thing' do
  recipe do
    ruby_block 'test'
  end
  it { is_expected.to run_ruby_block('test') }
end
EOH
    # Should fail because the helper isn't included
    it { expect { subject }.to raise_error(Mixlib::ShellOut::ShellCommandFailed) }
  end # /context with the Halite helper disabled
end
