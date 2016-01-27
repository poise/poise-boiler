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

require 'halite'
require 'kitchen/provisioner/chef_solo'


module PoiseBoiler
  module Kitchen
    class Provisioner < ::Kitchen::Provisioner::ChefSolo
      default_config :gemspec do |provisioner|
        Dir[File.join(provisioner[:kitchen_root], '*.gemspec')].first
      end
      expand_path_for :gemspec

      def self.name
        'PoiseSolo'
      end

      def create_sandbox
        super
        convert_halite_cookbooks
        copy_test_cookbook
        copy_test_cookbooks
      end

      private

      def cookbook_gem
        @cookbook_gem ||= begin
          gemspec = Bundler.load_gemspec(config[:gemspec])
          # Fix the gem path because it defaults to where the gem would be installed.
          gemspec.full_gem_path = File.dirname(config[:gemspec])
          Halite::Gem.new(gemspec)
        end
      end

      def convert_halite_cookbooks
        @real_cookbook_deps = {}
        gems_to_convert = {}
        gems_to_check = [cookbook_gem]
        until gems_to_check.empty?
          check = gems_to_check.pop
          # Already in the list, skip expansion.
          next if gems_to_convert.include?(check.name)
          # Not a cookbook, don't expand.
          next unless check.is_halite_cookbook?
          gems_to_convert[check.name] = check
          # Expand dependencies and check each of those.
          check.cookbook_dependencies.each do |dep|
            dep_cook = dep.cookbook
            if dep_cook
              gems_to_check << dep_cook
            else
              @real_cookbook_deps[dep.name] = dep
            end
          end
        end
        # Convert all the things!
        tmpbooks_dir = File.join(sandbox_path, 'cookbooks')
        FileUtils.mkdir_p(tmpbooks_dir)
        gems_to_convert.each do |name, gem_data|
          Halite.convert(gem_data, File.join(tmpbooks_dir, gem_data.cookbook_name))
        end
      end

      def copy_test_cookbook
        fixture_base = File.join(config[:kitchen_root], 'test', 'cookbook')
        return unless File.exist?(File.join(fixture_base, 'metadata.rb'))
        tmp_base = File.join(sandbox_path, 'cookbooks', "#{cookbook_gem.cookbook_name}_test")
        FileUtils.mkdir_p(tmp_base)
        FileUtils.cp_r(File.join(fixture_base, "."), tmp_base)
      end

      def copy_test_cookbooks
        fixtures_base = File.join(config[:kitchen_root], 'test', 'cookbooks')
        return unless File.exist?(fixtures_base)
        tmp_base = File.join(sandbox_path, 'cookbooks')
        FileUtils.mkdir_p(tmp_base)
        FileUtils.cp_r(File.join(fixtures_base, "."), tmp_base)
      end

    end
  end
end
