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
    # Helpers for Test Kitchen and .kitchen.yml configuration.
    #
    # @see PoiseBoiler::Kitchen.kitchen
    # @since 1.7.0
    class Kitchen < Halite::HelperBase
      # Shorthand names for Test Kitchen platforms.
      #
      # @see #expand_platforms
      PLATFORM_ALIASES = {
        'windows' => %w{windows-2012r2},
        'windows32' => %w{windows-2008sp2},
        'ubuntu' => %w{ubuntu-14.04 ubuntu-16.04},
        'rhel' => %w{centos},
        'centos' => %w{centos-6 centos-7},
        'linux' => %w{ubuntu rhel centos},
        'unix' => %w{linux}, #, freebsd},
        'all' => %w{unix windows},
        'any' => %w{ubuntu-16.04}, # For cookbooks that don't actually use platform-specific bits.
      }

      # Default EC2 subnet ID when not overridden in the environment or config.
      DEFAULT_EC2_SUBNET_ID = 'subnet-ca674af7'

      # Default EC2 subnet ID for previous-generation instance types.
      DEFAULT_EC2_LEGACY_INSTANCES_SUBNET_ID = 'subnet-1ffec232'

      # Default EC2 security group when not overridden in the environment or config.
      DEFAULT_EC2_SECURITY_GROUP_ID = 'sg-ed1ad892'

      def initialize(**options)
        # Figure out the directory that contains the kitchen.yml by looking for
        # the first entry in the stack that isn't inside poise-boiler.
        options[:base] ||= if caller.find {|line| !line.start_with?(File.expand_path('../../..', __FILE__)) } =~ /^(.*?):\d+:in/
          File.expand_path('..', $1)
        else
          # ¯\_(ツ)_/¯ hope for the best.
          Dir.pwd
        end
        super(**options)
      end

      # Generate YAML text for inclusion in a config file.
      #
      # @return [String]
      def to_yaml
        kitchen_config.to_yaml.gsub(/---[ \n]/, '')
      end

      # The Chef version to use for Test Kitchen or nil for any version.
      #
      # @return [String, nil]
      def chef_version
        # SPEC_BLOCK_CI is used to force non-locking behavior inside tests.
        @chef_version ||= ENV['CHEF_VERSION'] || if ENV['POISE_MASTER_BUILD']
          # We're going to install the latest nightly via Omnitruck later on.
          nil
        elsif ENV['SPEC_BLOCK_CI'] != 'true'
          # If there isn't a specific override, lock TK to use the same version of Chef as the Gemfile.
          require 'chef/version'
          Chef::VERSION.to_s
        end
      end

      def cookbook_name
        options[:cookbook_name] || cookbook.cookbook_name
      end

      # Make this public for use in {PoiseBoiler::Helpers::Kitchen::Provisioner}.
      public :cookbook

      private

      # Which Test Kitchen driver are we going to use.
      #
      # @return [String]
      def kitchen_driver
        @kitchen_driver ||= if options[:driver]
          # Manual override.
          options[:driver]
        elsif File.exist?(File.expand_path('test/docker/docker.key', base))
          # Look for the decrypted private key. In CI this is generated by `rake travis`.
          'docker'
        elsif ENV['CI']
          # Don't try to use Vagrant on CI ever.
          'dummy'
        else
          'vagrant'
        end
      end

      # Expand the requested platforms using {PLATFORM_ALIASES}.
      #
      # @return [Array<String>]
      def expand_platforms
        # Default platform is linux unless overridden from the helper options.
        platforms = Array(options[:platforms] || (ENV['CI'] ? 'linux' : 'all'))
        last_platforms = []
        # This is probably not the most effcient solution but oh well.
        while platforms != last_platforms
          last_platforms = platforms
          platforms = platforms.map {|p| PLATFORM_ALIASES[p] || p}
          platforms.flatten!
          platforms.uniq!
        end
        platforms
      end

      # Generate a Test Kitchen configuration hash.
      #
      # @return [Hash]
      def kitchen_config
        {
          'driver' => driver_config,
          'transport' => transport_config,
          'provisioner' => provisioner_config,
          'platforms' => expand_platforms.map {|name| platform_config(name) },
          'suites' => [suite_config],
        }
      end

      # Generate a Test Kitchen driver configuration hash.
      #
      # @return [Hash]
      def driver_config
        # Default config for all drivers. {#chef_version} returns nil for "any
        # version" so use true to prevent reinstall attempts.
        config = {'name' => kitchen_driver, 'require_chef_omnibus' => chef_version || true}
        case kitchen_driver
        when 'docker'
          # Docker-specific configuration.
          config.update(
            # Custom Dockerfile.
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
          )
        when 'rackspace'
          # Set a default instance size.
          config['flavor_id'] = options[:rackspace_flavor] || 'general1-1'
        when 'ec2'
          config.update(ec2_driver_config)
        end
        config
      end

      # Generate a Test Kitchen transport configuration hash.
      #
      # @return [Hash]
      def transport_config
        {
          # Use the sftp transport from kitchen-sync.
          'name' => 'sftp',
          # Use the SSH key for this driver.
          'ssh_key' => case kitchen_driver
                       when 'docker'
                         "#{base}/.kitchen/docker_id_rsa"
                       when 'ec2'
                         "#{base}/test/ec2/ssh.key"
                       else
                         nil
                       end,
        }
      end

      # Generate a Test Kitchen provisioner configuration hash.
      #
      # @return [Hash]
      def provisioner_config
        {
          'log_level' => (ENV['DEBUG'] ? 'debug' : (ENV['CHEF_LOG_LEVEL'] || 'auto')),
          # Use the poise_solo provisioner, also part of kitchen-docker.
          'name' => 'poise_solo',
          'attributes' => {
            # Pass through $CI to know if we are on Travis.
            'CI' => ENV['CI'],
            # Pass through debug/poise_debug settings to the test instance.
            'POISE_DEBUG' => !!((ENV['POISE_DEBUG'] && ENV['POISE_DEBUG'] != 'false') ||
                                (ENV['poise_debug'] && ENV['poise_debug'] != 'false') ||
                                (ENV['DEBUG'] && ENV['DEBUG'] != 'false')
                               ),
          }
        }
      end

      # Generate a Test Kitchen platform configuration hash.
      #
      # @return [Hash]
      def platform_config(name)
        {
          'name' => name,
          # On CI enable poise-profiler automatically. Load it here in case the
          # user defines their own suites.
          'run_list' => ((ENV['CI'] || ENV['DEBUG'] || ENV['PROFILE']) ? %w{poise-profiler} : []),
        }.tap {|cfg| cfg.update(windows_platform_config(name)) if name.include?('windows') }
      end

      # Generate extra Test Kitchen platform configuration for Windows hosts.
      def windows_platform_config(name)
        {
          'driver' => ec2_driver_config.merge({
            'instance_type' => 'm3.medium',
            'retryable_tries' => 120,
          }),
          'provisioner' => {
            'product_name' => 'chef',
            'channel' =>  chef_version ? 'stable' : 'current',
            'product_version' => chef_version,
          },
          'transport' => {
            'name' => 'winrm',
            'ssh_key' => "#{base}/test/ec2/ssh.key",
          },
        }.tap do |cfg|
          if name == 'windows-2008sp2'
            cfg['driver']['image_id'] = 'ami-f6a043e0'
            cfg['driver']['instance_type'] = 'm1.medium'
            cfg['driver']['subnet_id'] = ENV['AWS_SUBNET_ID'] || DEFAULT_EC2_LEGACY_INSTANCES_SUBNET_ID
            cfg['provisioner']['architecture'] = 'i386'
          end
        end
      end

      # Generate a Test Kitchen suite configuration hash. This is a single suite
      # that runs the fixture cookbook if present otherwise the main cookbook.
      #
      # @return [Hash]
      def suite_config
        {
          'name' => 'default',
          'run_list' => (File.exist?(File.join(base, 'test', 'cookbook')) || File.exist?(File.join(base, 'test', 'cookbooks'))) ? ["#{cookbook_name}_test"] : [cookbook_name],
        }
      end

      # Generate a Test Kitchen driver configuration hash with basic settings
      # for kitchen-ec2.
      #
      # @return [Hash]
      def ec2_driver_config
        {
          'name' => 'ec2',
          'aws_ssh_key_id' => "#{cookbook_name}-kitchen",
          'security_group_ids' => ENV['AWS_SECURITY_GROUP_ID'] ? [ENV['AWS_SECURITY_GROUP_ID']] : [DEFAULT_EC2_SECURITY_GROUP_ID],
          'subnet_id' => ENV['AWS_SUBNET_ID'] || DEFAULT_EC2_SUBNET_ID,
          # Because kitchen-rackspace also has a thing called flavor_id.
          'flavor_id' => nil,
        }
      end

    end
  end
end
