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


module PoiseBoiler
  module Helpers
    class Kitchen
      # Helper methods for the two TK provisioners.
      module ProvisionerHelpers
        private

        def poise_helper_instance
          PoiseBoiler::Kitchen.instance || begin
            raise 'Global poise-boiler kitchen instance not set'
          end
        end

        def convert_halite_cookbooks(dest)
          @real_cookbook_deps = {}
          gems_to_convert = {'poise-profiler' => Halite::Gem.new('poise-profiler')}
          gems_to_check = [poise_helper_instance.cookbook]
          # Only look at dev dependcies of the top-level spec, which happens to
          # be the first since this is a breadth-first analysis. Kind of hacky
          # but less hacky than refactoring this whole loop.
          first = true
          until gems_to_check.empty?
            check = gems_to_check.pop
            # Already in the list, skip expansion.
            next if gems_to_convert.include?(check.name)
            # Not a cookbook, don't expand.
            next unless check.is_halite_cookbook?
            gems_to_convert[check.name] = check
            # Expand dependencies and check each of those.
            check.cookbook_dependencies(development: first).each do |dep|
              dep_cook = dep.cookbook
              if dep_cook
                gems_to_check << dep_cook
              else
                @real_cookbook_deps[dep.name] = dep
              end
            end
            first = false
          end
          # Convert all the things!
          tmpbooks_dir = File.join(dest, 'cookbooks')
          FileUtils.mkdir_p(tmpbooks_dir)
          gems_to_convert.each do |name, gem_data|
            Halite.convert(gem_data, File.join(tmpbooks_dir, gem_data.cookbook_name))
          end
        end

        def copy_test_cookbook(dest)
          fixture_base = File.join(config[:kitchen_root], 'test', 'cookbook')
          return unless File.exist?(File.join(fixture_base, 'metadata.rb'))
          tmp_base = File.join(dest, 'cookbooks', "#{poise_helper_instance.cookbook_name}_test")
          FileUtils.mkdir_p(tmp_base)
          FileUtils.cp_r(File.join(fixture_base, "."), tmp_base)
        end

        def copy_test_cookbooks(dest)
          fixtures_base = File.join(config[:kitchen_root], 'test', 'cookbooks')
          return unless File.exist?(fixtures_base)
          tmp_base = File.join(dest, 'cookbooks')
          FileUtils.mkdir_p(tmp_base)
          FileUtils.cp_r(File.join(fixtures_base, "."), tmp_base)
        end

      end
    end
  end
end
