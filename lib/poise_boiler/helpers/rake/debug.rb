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

require 'halite/helper_base'


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
      class Debug < Halite::HelperBase
        # Install the rake tasks.
        #
        # @return [void]
        def install
          # Delayed so that Rake doesn't need to be loaded to run this file.
          extend ::Rake::DSL

          desc 'Run further tasks in verbose mode'
          task 'verbose' do
            ENV['VERBOSE'] = '1'
            ENV['DEBUG'] = nil
            ENV['QUIET'] = nil
          end

          desc 'Run further tasks in debug mode'
          task 'debug' do
            ENV['VERBOSE'] = '1'
            ENV['DEBUG'] = '1'
            ENV['QUIET'] = nil
          end

          desc 'Run further tasks in quiet mode'
          task 'quiet' do
            ENV['VERBOSE'] = nil
            ENV['DEBUG'] = nil
            ENV['QUIET'] = '1'
          end

          # Short alises.
          task 'v' => %w{verbose}
          task 'd' => %w{debug}
          task 'q' => %w{quiet}
        end

      end
    end
  end
end
