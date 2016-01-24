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
      # Helper methods for bumping gem versions.
      #
      # @api private
      # @since 1.2.0
      module BumpHelpers
        VERSION_CONST = /(^\s*VERSION = ['"])([^'"]+)(['"]\s*$)/

        def latest_tag
          git = Git.open(base)
          if git.tags.empty?
            nil
          else
            tag_name = git.tags.last.name
            if tag_name =~ /^v(.*)$/
              $1
            else
              tag_name
            end
          end
        end

        def bumped_version(type: :patch, release: false)
          current_version = latest_tag
          next_version = if current_version
            parts = current_version.split(/\./).map(&:to_i)
            bump_index = {major: 0, minor: 1, patch: 2}[type]
            parts[bump_index] += 1
            (bump_index+1..2).each {|n| parts[n] = 0 }
            parts.map(&:to_s).join('.')
          else
            '1.0.0'
          end
          # Release mode means plain, otherwise .pre.
          if release
            next_version
          else
            next_version + '.pre'
          end
        end

        def find_version_rb
          candidates = Dir[File.join(base, 'lib', '**', 'version.rb')]
          candidates.min_by {|path| path.size }
        end

        def bump_version!(type: :patch, release: false, &block)
          version_rb_path = find_version_rb
          raise "Unable to find a version.rb in #{base}" unless version_rb_path
          shell.say("Bumping version in #{version_rb_path}") if ENV['DEBUG']
          content = IO.read(version_rb_path)
          raise "Unable to find current version in #{version_rb_path}" unless VERSION_CONST =~ content
          current_version = $2
          version = bumped_version(type: type, release: release)
          shell.say("Bumping gem version from #{current_version} to #{version}")
          new_content = content.gsub(VERSION_CONST, "\\1#{version}\\3")
          IO.write(version_rb_path, new_content)
          begin
            block.call if block
          rescue Exception
            # Restore the original version if anything goes wrong.
            IO.write(version_rb_path, content)
            raise
          end
        end
      end

      # Helper for a Rakefile to install tasks for bumping gem versions.
      #
      # @since 1.2.0
      # @example Installing tasks
      #   require 'poise_boiler/helpers/rake/bump'
      #   PoiseBoiler::Helpers::Rake::Bump.install
      # @example Bumping a patch version
      #   $ rake release:bump
      # @example Bumping a minor version
      #   $ rake release:bump:minor
      class Bump < Halite::HelperBase
        include BumpHelpers

        # Install the rake tasks.
        #
        # @return [void]
        def install
          # Delayed so that Rake doesn't need to be loaded to run this file.
          extend ::Rake::DSL

          task 'release:bump' do
            bump_version!(type: :patch)
          end

          task 'release:bump:minor' do
            bump_version!(type: :minor)
          end

          task 'release:bump:major' do
            bump_version!(type: :major)
          end
        end
      end
    end
  end
end
