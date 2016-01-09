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

require 'halite/helper_base'

require_relative 'bump'

module PoiseBoiler
  module Helpers
    class Rake
      # Helper for a Rakefile to install tasks for managing verbose/debug output.
      #
      # @since 1.2.0
      # @example Installing tasks
      #   require 'poise_boiler/helpers/rake/debug'
      #   PoiseBoiler::Helpers::Rake::Debug.install
      # @example Runng a task in verbose mode
      #   $ rake verbose release
      # @example Runng a task in debug mode
      #   $ rake debug release
      class Release < Halite::HelperBase
        include BumpHelpers

        # Install the rake tasks.
        #
        # @return [void]
        def install
          # Delayed so that Rake doesn't need to be loaded to run this file.
          extend ::Rake::DSL

          # Rename the original release task.
          release_task = ::Rake.application.lookup('release')
          if release_task
            release_actions = release_task.actions.dup
            task 'release:original' => release_task.prerequisites.dup do
              release_actions.map(&:call)
            end
            release_task.clear
          end

          # No-op Bundler's release:source_control_push task.
          source_control_push_task = ::Rake.application.lookup('release:source_control_push')
          source_control_push_task.clear if source_control_push_task

          # Tag the release.
          task 'release:tag' do
            tag_release!(commit: false)
          end

          # Make the new release tasks.
          desc "Bump, tag, and release #{gem_name}"
          task 'release' do
            release_gem!(:patch)
          end

          desc "Bump minor, tag, and release #{gem_name}"
          task 'release:minor' do
            release_gem!(:minor)
          end

          desc "Bump major, tag, and release #{gem_name}"
          task 'release:major' do
            release_gem!(:major)
          end
        end

        private

        def use_signed_tags?
          !!sh('git config user.signingkey >/dev/null', verbose: false) {|ok, status| ok }
        end

        def find_current_version
          version_rb = find_version_rb
          if version_rb
            (IO.read(version_rb) =~ Bump::VERSION_CONST) && $2
          else
            nil
          end
        end

        def git_commit!(message)
          sh(*['git', 'add', find_version_rb])
          commit_cmd = ['git', 'commit', '-m', message]
          sh(*commit_cmd)
        end

        def tag_release!(commit: true, &block)
          # I can't use the gemspec because we might have changed the version.
          current_version = find_current_version
          unless current_version
            raise "Unable to find current version of #{gem_name}"
          end
          if Gem::Version.create(current_version).prerelease?
            raise "#{gem_name} has a prerelease version: #{current_version}"
          end
          unless File.exist?('CHANGELOG.md') && IO.read('CHANGELOG.md').include?("## v#{current_version}\n")
            raise "No changelog entry found for #{current_version}"
          end
          answer = shell.ask("Are you certain you want to release #{gem_name} v#{current_version}?", limited_to: %w{y n})
          if answer == 'n'
            raise 'Aborting release'
          end
          git_commit!('Bump version for release.') if commit
          tag_cmd = %w{git tag -a}
          tag_cmd << '-s' if use_signed_tags?
          tag_cmd.concat(['-m', "Release #{current_version}", "v#{current_version}"])
          sh(*tag_cmd)
          begin
            block.call if block
          rescue Exception
            sh(*['git', 'tag', '-d', "v#{current_version}"])
            raise
          end
        end

        def release_gem!(bump_type)
          bump_version!(type: bump_type, release: true) do
            tag_release! do
              # Run this as a subproc so it reloads the gemspec. Probably not
              # as reliable as invoke, but safer.
              sh(*['rake', 'release:original'], verbose: false)
            end
          end
          bump_version!(type: :patch)
          git_commit!('Bump version for dev.')
          sh(*['git', 'push'])
          sh(*['git', 'push', '--tags'])
        end

      end
    end
  end
end
