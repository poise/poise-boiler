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

require 'kitchen/provisioner/chef_solo'

require 'poise_boiler/helpers/kitchen/core_ext'
require 'poise_boiler/helpers/kitchen/provisioner_helpers'


module PoiseBoiler
  module Helpers
    class Kitchen
      class Provisioner < ::Kitchen::Provisioner::ChefSolo
        include ProvisionerHelpers

        default_config :gemspec do |provisioner|
          Dir[File.join(provisioner[:kitchen_root], '*.gemspec')].first
        end
        expand_path_for :gemspec

        def self.name
          'PoiseSolo'
        end

        def create_sandbox
          super
          convert_halite_cookbooks(sandbox_path) unless poise_helper_instance.options['no_gem']
          copy_test_cookbook(sandbox_path)
          copy_test_cookbooks(sandbox_path)
        end

      end
    end
  end
end
