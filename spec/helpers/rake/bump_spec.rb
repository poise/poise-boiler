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

describe PoiseBoiler::Helpers::Rake::Bump do
  rakefile "require 'poise_boiler/helpers/rake/bump'\nPoiseBoiler::Helpers::Rake::Bump.install"
  before { command('git init && git config user.email "you@example.com" && git config user.name "Your Name" && git add Rakefile && git commit -m "first commit" && git tag -a v2.3.4 -m "Release 2.3.4"') }
  file 'lib/mygem/version.rb', <<-EOH
module MyGem
  VERSION = '1.0.0.pre'
end
EOH
  def file_content
    IO.read(File.join(temp_path, 'lib/mygem/version.rb'))
  end

  describe 'release:bump' do
    rake_task 'release:bump'

    it { is_expected.to eq "Bumping gem version from 1.0.0.pre to 2.3.5.pre\n" }
    it { subject; expect(file_content).to eq <<-EOH }
module MyGem
  VERSION = '2.3.5.pre'
end
EOH
  end # /describe release:bump

  describe 'release:bump:minor' do
    rake_task 'release:bump:minor'

    it { is_expected.to eq "Bumping gem version from 1.0.0.pre to 2.4.0.pre\n" }
    it { subject; expect(file_content).to eq <<-EOH }
module MyGem
  VERSION = '2.4.0.pre'
end
EOH
  end # /describe release:bump:minor

  describe 'release:bump:major' do
    rake_task 'release:bump:major'

    it { is_expected.to eq "Bumping gem version from 1.0.0.pre to 3.0.0.pre\n" }
    it { subject; expect(file_content).to eq <<-EOH }
module MyGem
  VERSION = '3.0.0.pre'
end
EOH
  end # /describe release:bump:major

  describe '#bumped_version' do
    let(:instance) { described_class.new(gem_name: 'test') }
    let(:bump_type) { :patch }
    let(:bump_release) { false }
    let(:bump_current) { nil }
    subject { instance.send(:bumped_version, type: bump_type, release: bump_release) }
    before do
      allow(instance).to receive(:latest_tag).and_return(bump_current)
    end

    context 'with no existing version' do
      it { is_expected.to eq '1.0.0.pre' }
    end # /context with no existing version

    context 'with release mode' do
      let(:bump_release) { true }
      it { is_expected.to eq '1.0.0' }
    end # /context with release mode

    context 'with 1.2.3 and patch' do
      let(:bump_current) { '1.2.3' }
      it { is_expected.to eq '1.2.4.pre' }
    end # /context with 1.2.3 and patch

    context 'with 1.2.3 and minor' do
      let(:bump_type) { :minor }
      let(:bump_current) { '1.2.3' }
      it { is_expected.to eq '1.3.0.pre' }
    end # /context with 1.2.3 and minor

    context 'with 1.2.3 and major' do
      let(:bump_type) { :major }
      let(:bump_current) { '1.2.3' }
      it { is_expected.to eq '2.0.0.pre' }
    end # /context with 1.2.3 and major
  end # /describe #bumped_version
end
