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

require 'fileutils'

require 'chef/version'
require 'mixlib/shellout'

require 'poise_boiler/helpers/kitchen/provisioner_helpers'

$use_policyfile_zero = Gem::Requirement.create('< 12.7').satisfied_by?(Gem::Version.create(Chef::VERSION))

if $use_policyfile_zero
  require 'kitchen/provisioner/policyfile_zero'
else
  require 'kitchen/provisioner/chef_zero'
end

module PoiseBoiler
  module Helpers
    class Kitchen
      class PolicyProvisioner < ($use_policyfile_zero ? ::Kitchen::Provisioner::PolicyfileZero : ::Kitchen::Provisioner::ChefZero )
        include ProvisionerHelpers

        # Override the default value from the base class.
        # default_config :policyfile, '.kitchen/poise_policy.rb'
        # expand_path_for :policyfile

        def self.name
          'PoisePolicyfileZero'
        end

        # Run our policy generation first.
        def create_sandbox
          policy_base = File.join(config[:kitchen_root], '.kitchen', 'poise_policy')
          # Copy all my halite-y stuff to a folder. This should probably use a
          # temp dir instead.
          FileUtils.rm_rf(policy_base)
          convert_halite_cookbooks(policy_base) unless poise_helper_instance.options['no_gem']
          copy_test_cookbook(policy_base)
          copy_test_cookbooks(policy_base)
          # Generate a modified policy to use the cookbooks we just made.
          policy_path = generate_poise_policy(policy_base)
          # Compile that policy because the base provider doesn't do that.
          compile_poise_policy(policy_path)
          # Tell the base provider code to use our new policy instead.
          if $use_policyfile_zero
            config[:policyfile] = "#{config[:kitchen_root]}/#{policy_path}"
          else
            config[:policyfile_path] = policy_path
          end
          super
        end

        def cleanup_sandbox
          super if @sandbox_path
        end

        private

        def generate_poise_policy(base)
          info("Preparing modified policy")
          original_policy = IO.read(config[:policyfile])
          new_policy = "default_source :chef_repo, #{base.inspect}\n#{original_policy}"
          policy_path = ".kitchen/poise_policy_#{instance.name}.rb"
          IO.write("#{config[:kitchen_root]}/#{policy_path}", new_policy)
          policy_path
        end

        def compile_poise_policy(policy_path)
          compile_mode = if File.exist?(policy_path.gsub(/\.rb/, '.lock.json'))
            'update'
          else
            'install'
          end
          info("Compiling policy (#{compile_mode})")
          compile_cmd = Mixlib::ShellOut.new(['chef', compile_mode, policy_path])
          compile_cmd.run_command
          compile_cmd.error!
        end

      end
    end
  end
end
