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

require 'git'

require 'halite/helper_base'


module PoiseBoiler
  module Helpers
    class Rake
      # Helper for a Rakefile to install tasks for checking the state of projects.
      #
      # @since 1.2.0
      # @example Installing tasks
      #   require 'poise_boiler/helpers/rake/check'
      #   PoiseBoiler::Helpers::Rake::Check.install
      # @example Checking the current project
      #   $ rake release:check
      class Check < Halite::HelperBase
        # Install the rake tasks.
        #
        # @return [void]
        def install
          # Delayed so that Rake doesn't need to be loaded to run this file.
          extend ::Rake::DSL

          desc 'Check for unreleased commits'
          task 'release:check' do
            check_project(base, summary: !!ENV['QUIET'])
          end

          desc 'Check for unreleased commits in all projects'
          task 'release:checkall' do
            base_path = File.expand_path(ENV['POISE_ROOT'] || '~/src')
            Dir.foreach(base_path) do |entry|
              next unless entry =~ /^(poise|application|halite)/
              next if entry =~ /^(application_examples|poise-docker|poise-dash|poise\.io|poise-repomgr)/
              path = File.join(base_path, entry)
              next unless Dir.exist?(File.join(path, '.git'))
              check_project(path, header: "# #{entry}", summary: !ENV['VERBOSE'])
            end
          end

          # Aliases for less typing.
          task 'check' => %w{release:check}
          task 'checkall' => %w{release:checkall}
        end

        private

        # Check a project for changes.
        #
        # @param path [String] Path to the project's git repository.
        # @return [void]
        def check_project(path, header: nil, summary: false)
          git = Git.open(path)
          # Some checks for repos that aren't full projects.
          return unless git.branches['master']
          return unless git.remote('origin').url
          changed = check_changed_files(git)
          commits = check_commits(git)
          shell.say(header, :blue) unless !header || (changed.empty? && commits.empty?)
          display_changed_files(changed, summary: summary) unless changed.empty?
          display_commits(commits, summary: summary) unless commits.empty?
        end

        # Check for changed files, including new/untracked files.
        #
        # @params git [Git::Base] Git repository to operate on.
        # @return [Array]
        def check_changed_files(git)
          git.status.select {|file| file.type || file.untracked }
        end

        # Display changed files.
        #
        # @params changed [Array] Output from {#check_changed_file}
        # @return [void]
        def display_changed_files(changed, summary: false)
          shell.say("#{changed.size} file#{changed.size > 1 ? 's' : ''} with pending changes", :yellow)
          return if summary
          changed.each do |file|
            color = if file.type == 'A' || file.untracked
              :green
            elsif file.type == 'D'
              :red
            end
            shell.say("#{file.type || 'U'} #{file.path}", color)
          end
        end

        # Check for any commits that are not part of a release. Unpushed commits
        # are displayed in red.
        #
        # @params git [Git::Base] Git repository to operate on.
        # @return [Array]
        def check_commits(git)
          # Find either the latest tag (release) or the first commit in the repo.
          last_release = if git.tags.empty?
            git.log.last
          else
            git.tags.last
          end

          # Find all commits since the last release that are not only version bumps.
          commits = git.log.between(last_release.sha, 'master').select do |commit|
            if commit.message !~ /^bump.*for/i
              changed_files = commit.diff_parent.stats[:files].keys
              if changed_files.size != 1 || changed_files.first !~ /lib\/.*\/version\.rb/
                true
              end
            end
          end

          # Find all pushed commits since the last release.
          pushed_commits = git.log.between(last_release.sha, 'origin/master').inject(Set.new) do |memo, commit|
            memo << commit.sha
            memo
          end

          commits.map {|commit| [commit, pushed_commits.include?(commit.sha), last_release] }
        end

        # Display commits.
        #
        # @params changed [Array] Output from {#check_commits}
        # @return [void]
        def display_commits(commits, summary: false)
          unpushed_count = commits.inject(0) {|memo, (_, pushed)| memo + (pushed ? 0 : 1) }
          shell.say("#{commits.size} commit#{commits.size > 1 ? 's' : ''} #{unpushed_count > 0 ? "(#{unpushed_count} unpushed) " : ''}since #{commits.first[2].name}", unpushed_count > 0 ? :red : :yellow)
          return if summary
          commits.each do |commit, pushed|
            color = pushed ? nil : :red
            message = commit.message.strip
            if message.empty?
              shell.say("* #{commit.sha}", color)
            else
              message_lines = commit.message.strip.split(/\n/)
              first_line = message_lines.shift
              shell.say("* #{first_line}", color)
              # Filter down to only the first para and indent to match the '* '.
              message_lines = message_lines.take_while {|line| !line.strip.empty? }.map! {|line| '  '+line }
              shell.say(message_lines.join("\n"), color) unless message_lines.empty?
            end
          end

        end

      end
    end
  end
end
