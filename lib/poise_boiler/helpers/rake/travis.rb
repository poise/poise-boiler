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


module PoiseBoiler
  module Helpers
    class Rake
      # Helper for a Rakefile to install a task for testing on CI.
      #
      # @since 1.0.0
      # @example Installing tasks
      #   require 'poise_boiler/helpers/rake/travis'
      #   PoiseBoiler::Helpers::Rake::Travis.install
      # @example Running CI suite
      #   $ rake travis
      class Travis < Halite::HelperBase
        # Install the rake tasks.
        #
        # @return [void]
        def install
          # Delayed so that Rake doesn't need to be loaded to run this file.
          extend ::Rake::DSL

          file 'test/docker/docker.key' do
            sh 'openssl rsa -in test/docker/docker.pem -passin env:KITCHEN_DOCKER_PASS -out test/docker/docker.key'
          end

          file './docker' do
            sh 'wget https://get.docker.io/builds/Linux/x86_64/docker-latest -O docker'
            File.chmod(0755, './docker')
          end

          desc 'Run Test-Kitchen integration tests.'
          task 'travis:integration' => %w{test/docker/docker.key ./docker} do
            sh './bin/kitchen test -d always'
          end

          desc 'Run CI tests'
          task 'travis' do
            run_subtask('spec')
            run_subtask('chef:foodcritic')
            run_subtask('travis:integration') if integration_tests?
          end
        end

        private

        # Should we run integration tests?
        #
        # @return [Boolean]
        def integration_tests?
          ENV['TRAVIS_SECURE_ENV_VARS'] && !ENV['BUNDLE_GEMFILE'].to_s.include?('master')
        end

        # Convert a Time object to nanoseconds since the epoch.
        #
        # @param t [Time] Time object to convert.
        # @return [Integer]
        def time_nanoseconds(t)
          (t.tv_sec * 1000000000) + t.nsec
        end

        # Wrap a block in Travis-CI timer tags. These are read by the web UI
        # to nicely format timing information.
        #
        # @param block [Proc] Block to time.
        # @return [void]
        def travis_timer(&block)
          begin
            start_time = time_nanoseconds(Time.now)
            timer_id = '%08x' % Random.rand(0xFFFFFFFF)
            shell.say("travis_time:start:#{timer_id}")
            block.call
          ensure
            end_time = time_nanoseconds(Time.now)
            shell.say("travis_time:end:#{timer_id}:start=#{start_time},finish=#{end_time},duration=#{end_time - start_time}")
          end
        end

        # Wrap a block in Travis-CI fold tags. These are read bu the web UI to
        # allow hiding sections of output.
        #
        # @param name [String] Name of the fold block.
        # @param block [Proc] Block to fold.
        # @return [void]
        def travis_fold(name, &block)
          begin
            shell.say("travis_fold:start:#{name}")
            block.call
          ensure
            shell.say("travis_fold:end:#{name}")
          end
        end

        # Decorate a Rake subtask for Travis.
        #
        # @param name [String] Task to run.
        # @return [void]
        def run_subtask(name)
          travis_timer do
            begin
              shell.say("Running task #{name}")
              task(name).invoke
              shell.say("Task #{name} succeeded.", :green)
            rescue StandardError => ex
              shell.say("Task #{name} failed with #{ex}:", :red)
              travis_fold "#{name}.backtrace" do
                shell.say(ex.backtrace.map{|line| '  '+line }.join("\n"), :red)
              end
            end
          end
        end

      end
    end
  end
end
