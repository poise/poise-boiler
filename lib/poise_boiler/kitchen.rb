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
    extend self
    # Shorthand names for kitchen platforms.
    #
    # @see PoiseBoiler::Kitchen.kitchen
    PLATFORM_ALIASES = {
      'ubuntu' => %w{ubuntu-12.04 ubuntu-14.04},
      'rhel' => %w{centos-6 centos-7},
      'centos' => %w{rhel},
      'linux' => %w{ubuntu rhel},
      'unix' => %w{linux freebsd},
      'all' => %{unix windows},
    }

    # Return a YAML string suitable for inclusion in a .kitchen.yml config. This
    # will include the standard Poise/Halite boilerplate and some default values.
    #
    # @param platforms [String, Array<String>] Name(s) of platforms to use by default.
    # @see PoiseBoiler::Kitchen::PLATFORM_ALIASES
    # @example .kitchen.yml
    #   #<% require 'poise_boiler' %>
    #   <%= PoiseBoiler.kitchen %>
    def kitchen(platforms: 'ubuntu-14.04', root: nil)
      # Figure out the directory that contains the kitchen.yml.
      root ||= if caller.find {|line| !line.start_with?(File.expand_path('../..', __FILE__)) } =~ /^(.*?):\d+:in/
        File.expand_path('..', $1)
      else
        # ¯\_(ツ)_/¯
        Dir.pwd
      end
      # SPEC_BLOCK_CI is used to force non-locking behavior inside tests.
      chef_version = ENV['CHEF_VERSION'] || if ENV['SPEC_BLOCK_CI'] != 'true'
        # If there isn't a specific override, lock TK to use the same version of Chef as the Gemfile.
        require 'chef/version'
        Chef::VERSION
      end
      install_arguments = if ENV['POISE_MASTER_BUILD']
        # Force it to use any version down below.
        chef_version = nil
        # Use today's date as an ignored param to force the layer to rebuild.
        " -n -- #{Date.today}"
      elsif chef_version
        " -v #{chef_version}"
      else
        ''
      end
      docker_enabled = File.exist?(File.expand_path('test/docker/docker.key', root))
      {
        'chef_versions' => %w{12},
        'driver' => {
          'name' => (docker_enabled ? 'docker' : ENV['TRAVIS'] == 'true' ? 'dummy' : 'vagrant'),
          'require_chef_omnibus' => chef_version || true,
          'dockerfile' => File.expand_path('../kitchen/Dockerfile.erb', __FILE__),
          # No password for securiteeeee.
          'password' => nil,
          # Our docker settings.
          'binary' => (ENV['TRAVIS'] == 'true' ? './' : '') + 'docker',
          'socket' => 'tcp://docker.poise.io:443',
          'tls_verify' => 'true',
          'tls_cacert' => 'test/docker/docker.ca',
          'tls_cert' => 'test/docker/docker.pem',
          'tls_key' => 'test/docker/docker.key',
          # Cache some stuff in the Docker image.
          'provision_command' => [
            # Run some installs at provision so they are cached in the image.
            # Install net-tools for netstat which is used by serverspec.
            "test ! -f /etc/debian_version || apt-get install -y net-tools",
            "test ! -f /etc/redhat-release || yum -y install net-tools",
            # Make sure the hostname utilitiy is installed on CentOS 7. The
            # ||true is for EL6 which has no hostname package. Sigh.
            "test ! -f /etc/redhat-release || yum -y install hostname || true",
            # Install Chef (with the correct verison).
            "curl -L https://chef.io/chef/install.sh | bash -s --#{install_arguments}",
            # Install some kitchen-related gems. Normally installed during the verify step but that is idempotent.
            "env GEM_HOME=/tmp/verifier/gems GEM_PATH=/tmp/verifier/gems GEM_CACHE=/tmp/verifier/gems/cache /opt/chef/embedded/bin/gem install --no-rdoc --no-ri thor busser busser-serverspec serverspec bundler",
            # Fix directory permissions.
            "chown -R kitchen /tmp/verifier",
          ],
        },
        'transport' => {
          'name' => 'sftp',
          'ssh_key' => docker_enabled ? File.expand_path('.kitchen/docker_id_rsa', root) : nil,
        },
        'platforms' => expand_kitchen_platforms(platforms).map {|p| platform_definition(p) },
      }.to_yaml.gsub(/---[ \n]/, '')
    end

    private

    # Expand aliases from PLATFORM_ALIASES.
    def expand_kitchen_platforms(platforms)
      platforms = Array(platforms)
      last_platforms = []
      while platforms != last_platforms
        last_platforms = platforms
        platforms = platforms.map {|p| PLATFORM_ALIASES[p] || p}.flatten.uniq
      end
      platforms
    end

    def platform_definition(name)
      {
        'name' => name,
        'run_list' => platform_run_list(name),
        'driver_config' => platform_driver(name),
      }
    end

    # Return the platform-level run list for a given platform.
    #
    # @param platform [String] Platform name.
    # @return [Array<String>]
    def platform_run_list(platform)
      if platform.start_with?('debian') || platform.start_with?('ubuntu')
        %w{apt}
      else
        []
      end
    end

    def platform_driver(platform)
      if platform.start_with?('freebsd')
        {
          'binary' => (ENV['TRAVIS'] == 'true' ? './' : '') + 'docker-1.7.1',
          'image' => 'lexaguskov/freebsd',
          'socket' => ENV['POISE_DOCKER_FREEBSD'] || 'tcp://dockerbsd.poise.io:443',
        }
      else
        {
          'binary' => (ENV['TRAVIS'] == 'true' ? './' : '') + 'docker',
          'socket' => ENV['POISE_DOCKER_LINUX'] || 'tcp://docker.poise.io:443',
        }
      end
    end
  end
end
