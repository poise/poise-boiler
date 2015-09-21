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

require 'addressable/uri'
require 'halite/gem'
require 'halite/helper_base'
require 'mixlib/shellout'


module PoiseBoiler
  module Helpers
    class Rake
      # Helper for a Rakefile to add a `badges` command. This command will print
      # out README badges suitable for use on GitHub.
      #
      # @since 1.0.0
      # @example Installing tasks
      #   require 'poise_boiler/helpers/rake/badges'
      #   PoiseBoiler::Helpers::Rake::Badges.install
      # @example Creating badges
      #   $ rake badges >> README.md
      class Badges < Halite::HelperBase
        # Install the `badges` rake task.
        #
        # @return [void]
        def install
          return if options[:no_gem]
          # Delayed so that Rake doesn't need to be loaded to run this file.
          extend ::Rake::DSL

          desc "Generate README badges for #{gemspec.name}"
          task 'badges' do
            shell.say(generate_badges)
          end
        end

        private

        # Generate badges as a string.
        #
        # @return [String]
        def generate_badges
          # Example badges
          # [![Build Status](https://img.shields.io/travis/poise/poise.svg)](https://travis-ci.org/poise/poise)
          # [![Gem Version](https://img.shields.io/gem/v/poise.svg)](https://rubygems.org/gems/poise)
          # [![Cookbook Version](https://img.shields.io/cookbook/v/poise.svg)](https://supermarket.chef.io/cookbooks/poise)
          # [![Code Climate](https://img.shields.io/codeclimate/github/poise/poise.svg)](https://codeclimate.com/github/poise/poise)
          # [![Coverage](https://img.shields.io/codecov/c/github/poise/poise.svg)](https://codecov.io/github/poise/poise)
          # [![Gemnasium](https://img.shields.io/gemnasium/poise/poise.svg)](https://gemnasium.com/poise/poise)
          # [![License](https://img.shields.io/badge/license-Apache_2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
          ''.tap do |badges|
            github = options[:github] || detect_github
            badges << badge('Build Status', "travis/#{github}", "https://travis-ci.org/#{github}") if github
            badges << badge('Gem Version', "gem/v/#{gemspec.name}", "https://rubygems.org/gems/#{gemspec.name}")
            badges << badge('Cookbook Version', "cookbook/v/#{cookbook.cookbook_name}", "https://supermarket.chef.io/cookbooks/#{cookbook.cookbook_name}") if cookbook.is_halite_cookbook?
            badges << badge('Code Climate', "codeclimate/github/#{github}", "https://codeclimate.com/github/#{github}") if github
            badges << badge('Coverage', "codecov/c/github/#{github}", "https://codecov.io/github/#{github}") if github
            badges << badge('Gemnasium', "gemnasium/#{github}", "https://gemnasium.com/#{github}") if github
            badges << badge('License', 'badge/license-Apache_2-blue', 'https://www.apache.org/licenses/LICENSE-2.0')
          end
        end

        # Create a single badge string.
        #
        # @param alt [String] Alt text for the badge.
        # @param img [String] Image URI. If just a relative path is givenm it
        #   will be a Shields.io image.
        # @param href [String] URI to link to.
        # @return [String]
        def badge(alt, img, href)
          # Default scheme and hostname because I can.
          img = "https://img.shields.io/#{img}.svg" unless Addressable::URI.parse(img).host
          "[![#{alt}](#{img})](#{href})\n"
        end

        # Find the GitHub user/org and repository name for this repository.
        # Based on travis.rb https://github.com/travis-ci/travis.rb/blob/23ea1d2f34231a50a475b4ee8d19fa15b1d6b0e3/lib/travis/cli/repo_command.rb#L65
        # Copyright (c) 2014-2015 Travis CI GmbH <support@travis-ci.com>
        #
        # @return [String, nil]
        def detect_github
          git_head = git_shell_out(%w{name-rev --name-only HEAD})
          return nil unless git_head
          git_remote = git_shell_out(%W{config --get branch.#{git_head}.remote})
          git_remote = 'origin' if !git_remote || git_remote.empty? # Default value
          git_info = git_shell_out(%w{ls-remote --get-url}+[git_remote])
          git_regex = %r{/?(.*/.+?)(\.git)?$}
          if md = Addressable::URI.parse(git_info).path.match(git_regex)
            md[1]
          else
            # Unable to auto-detect
            nil
          end
        end

        # Run a git command and return the output.
        #
        # @param cmd [Array<String>] Command arguments to pass to git.
        # @return [String, nil]
        def git_shell_out(cmd)
          cmd = Mixlib::ShellOut.new(['git']+cmd, cwd: base)
          cmd.run_command
          if cmd.error?
            nil
          else
            cmd.stdout.strip
          end
        end
      end
    end
  end
end
