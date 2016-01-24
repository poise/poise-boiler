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

describe PoiseBoiler::Helpers::Rake::Check do
  rakefile "require 'poise_boiler/helpers/rake/check'\nPoiseBoiler::Helpers::Rake::Check.install"
  CHECK_INITIALIZER = 'git init && git config user.email "you@example.com" && git config user.name "Your Name" && git add main.rb Rakefile && git commit -m "first commit" && git tag -a v1.0.0 -m "Release 1.0.0" && git remote add origin http://example.com/ && git branch -f origin/master'

  describe 'check' do
    rake_task 'release:check'
    file 'main.rb'
    before { command(CHECK_INITIALIZER) }

    context 'with no files' do
      its(:stdout) { is_expected.to eq '' }
    end # /context with no files

    context 'with an uncommitted file' do
      file 'other.rb'

      its(:stdout) { is_expected.to eq "1 file with pending changes\nU other.rb\n" }
    end # /context with an uncommitted file

    context 'with a new file' do
      file 'other.rb'
      before { command('git add other.rb') }

      its(:stdout) { is_expected.to eq "1 file with pending changes\nA other.rb\n" }
    end # /context with a new file

    context 'with a modified file' do
      file 'main.rb', 'content'

      its(:stdout) { is_expected.to eq "1 file with pending changes\nM main.rb\n" }
    end # /context with a modified file

    context 'with a deleted file' do
      before { command('rm main.rb') }

      its(:stdout) { is_expected.to eq "1 file with pending changes\nD main.rb\n" }
    end # /context with a deleted file

    context 'with multiple files' do
      file 'main.rb', 'content'
      file 'other.rb'

      its(:stdout) { is_expected.to eq "2 files with pending changes\nM main.rb\nU other.rb\n" }
    end # /context with multiple files

    context 'with a new commit' do
      file 'other.rb'
      before { command('git add other.rb && git commit -m "second commit" && git branch -f origin/master') }

      its(:stdout) { is_expected.to eq "1 commit since v1.0.0\n* second commit\n" }
    end # /context with a new commit

    context 'with an unpushed commit' do
      file 'other.rb'
      before { command('git add other.rb && git commit -m "second commit"') }

      its(:stdout) { is_expected.to eq "1 commit (1 unpushed) since v1.0.0\n* second commit\n" }
    end # /context with an unpushed commit

    context 'with multiple commits' do
      file 'other.rb'
      file 'third.rb'
      before { command('git add other.rb && git commit -m "second commit" && git add third.rb && git commit -m "moar commits" && git branch -f origin/master') }

      its(:stdout) { is_expected.to eq "2 commits since v1.0.0\n* moar commits\n* second commit\n" }
    end # /context with multiple commits

    context 'with quiet mode' do
      file 'other.rb'
      file 'third.rb'
      before { command('git add other.rb && git commit -m "second commit" && git add third.rb') }
      environment QUIET: 1

      its(:stdout) { is_expected.to eq "1 file with pending changes\n1 commit (1 unpushed) since v1.0.0\n" }
    end # /context with quiet mode
  end # /describe check

  describe 'checkall' do
    rake_task 'release:checkall'
    file 'poise/Rakefile'
    file 'poise/main.rb'
    before { command(CHECK_INITIALIZER, cwd: File.join(temp_path, 'poise')) }
    around do |ex|
      begin
        ENV['POISE_ROOT'] = temp_path
        ex.run
      ensure
        ENV['POISE_ROOT'] = nil
      end
    end

    context 'with one changed repo' do
      file 'poise/other.rb'

      its(:stdout) { is_expected.to eq "# poise\n1 file with pending changes\n" }
    end # /context with one changed repo

    context 'with verbose mode' do
      file 'poise/other.rb'
      environment VERBOSE: 1

      its(:stdout) { is_expected.to eq "# poise\n1 file with pending changes\nU other.rb\n" }
    end # /context with verbose mode
  end # /describe checkall
end
