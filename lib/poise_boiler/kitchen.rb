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

require 'kitchen'
require 'kitchen-sync'

module PoiseBoiler
  # Helpers for Test-Kitchen and .kitchen.yml configuration.
  #
  # @since 1.0.0
  module Kitchen
    # Shorthand names for kitchen platforms.
    #
    # @see PoiseBoiler::Kitchen.kitchen
    PLATFORM_ALIASES = {
      'ubuntu' => %w{ubuntu-12.04 ubuntu-14.04},
      'rhel' => %w{centos-6.5 centos-7},
      'centos' => %w{rhel},
      'linux' => %w{ubuntu rhel},
    }

    # Return a YAML string suitable for inclusion in a .kitchen.yml config. This
    # will include the standard Poise/Halite boilerplate and some default values.
    #
    # @param platforms [String, Array<String>] Name(s) of platforms to use by default. See PLATFORM_ALIASES for aliases.
    # @see PoiseBoiler::Kitchen::PLATFORM_ALIASES
    # @example .kitchen.yml
    #   #<% require 'poise_boiler' %>
    #   <%= PoiseBoiler.kitchen %>
    def self.kitchen(platforms:)
      chef_version = ENV['CHEF_VERSION'] || if ENV['CI']
        # If we are in CI and there isn't a specific override, lock TK to use the same version of Chef as the Gemfile.
        require 'chef/version'
        Chef::VERSION
      end
      {
        'driver' => {
          'name' => 'vagrant',
          'require_chef_omnibus' => chef_version || 'latest',
          'provision_command' => [
            # Run some installs at provision so they are cached in the image.
            # Install Chef (with the correct verison).
            "curl -L https://chef.io/chef/install.sh | bash -s --" + (chef_version ? " -v #{chef_version}" : '' ),
            # Install some kitchen-related gems. Normally installed during the verify step but thats idempotent.
            "env GEM_HOME=/tmp/busser/gems GEM_PATH=/tmp/busser/gems GEM_CACHE=/tmp/busser/gems/cache /opt/chef/embedded/bin/gem install thor busser busser-serverspec serverspec",
          ],
        },
        'platforms' => expand_kitchen_platforms(platforms).map {|p| {'name' => p} },
        'chef_versions' => %w{11.16 11.18 11 12},
      }.to_yaml.gsub(/---[ \n]/, '')
    end

    private

    # Expand aliases from PLATFORM_ALIASES.
    def self.expand_kitchen_platforms(platforms)
      platforms = Array(platforms)
      last_platforms = []
      while platforms != last_platforms
        last_platforms = platforms
        platforms = platforms.map {|p| PLATFORM_ALIASES[p] || p}.flatten
      end
      platforms
    end
  end
end
