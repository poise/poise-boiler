#
# Copyright 2016, Noah Kantrowitz
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
require 'mixlib/shellout'


module PoiseBoiler
  module Helpers
    class Rake
      # Helper for a Rakefile to install tasks for updating copyright years.
      #
      # @since 1.6.0
      # @example Installing tasks
      #   require 'poise_boiler/helpers/rake/year'
      #   PoiseBoiler::Helpers::Rake::Year.install
      # @example Updating all copyright years
      #   $ rake year
      # @example Updating copyright years on a non-boiler project.
      #   $ git ls-files | xargs perl -pi -e "s/Copyright (?:\(c\) )?((?\!$(date +%Y))\\d{4})(-\\d{4})?,/Copyright \\1-$(date +%Y),/gi"
      class Year < Halite::HelperBase
        # Install the rake tasks.
        #
        # @return [void]
        def install
          # Delayed so that Rake doesn't need to be loaded to run this file.
          extend ::Rake::DSL

          task 'year' do
            current_year = Time.now.year.to_s
            git_files.each do |path|
              full_path = File.expand_path(path, base)
              update_file(full_path, current_year)
            end
          end
        end

        private

        def git_files
          cmd = Mixlib::ShellOut.new(%w{git ls-files}, cwd: base)
          cmd.run_command
          cmd.error!
          cmd.stdout.split(/\n/)
        end

        def update_file(path, year)
          st = File.stat(path)
          # Skip weird files, things over 1MB.
          return unless st.file? && st.size < 1024 * 1024
          fd = File.new(path, mode: 'r+b')
          content = fd.read
          # Skip any file with null bytes.
          return if content.include?("\00")
          new_content = content.gsub(/Copyright (\d\d\d\d)(-\d\d\d\d)?,/) do |match|
            if $1 == year
              match
            else
              "Copyright #{$1}-#{year},"
            end
          end
          # No change, bailing.
          return if content == new_content
          fd.seek(0, 0)
          fd.write(new_content)
        end

      end
    end
  end
end
