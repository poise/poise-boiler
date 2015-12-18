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

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'poise_boiler/version'

Gem::Specification.new do |spec|
  spec.name = 'poise-boiler'
  spec.version = PoiseBoiler::VERSION
  spec.authors = ['Noah Kantrowitz']
  spec.email = %w{noah@coderanger.net}
  spec.description = 'Boilerplate-reduction helpers for Poise/Halite-style gemss.'
  spec.summary = spec.description
  spec.homepage = 'https://github.com/poise/poise-boiler'
  spec.license = 'Apache 2.0'
  spec.metadata['halite_ignore'] = 'true'

  spec.files = `git ls-files`.split($/)
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w{lib}

  # Development gems
  spec.add_dependency 'addressable', '~> 2.3'
  spec.add_dependency 'rake', '~> 10.4'
  # spec.add_dependency 'travis', '~> 1.8'
  spec.add_dependency 'yard', '~> 0.8'
  spec.add_dependency 'yard-classmethods', '~> 1.0'
  spec.add_dependency 'halite', '~> 1.0' # This is a circular dependency
  spec.add_dependency 'mixlib-shellout', '>= 1.4', '< 3.0' # Chef 11 means shellout 1.4 :-(
  spec.add_dependency 'pry' # Travis depends on old-ass pry, see https://github.com/travis-ci/travis.rb/issues/245
  spec.add_dependency 'pry-byebug'

  # Test gems
  spec.add_dependency 'rspec', '~> 3.2'
  spec.add_dependency 'rspec-its', '~> 1.2'
  spec.add_dependency 'chefspec', '~> 4.2'
  spec.add_dependency 'fuubar', '~> 2.0'
  spec.add_dependency 'simplecov', '~> 0.9'
  spec.add_dependency 'foodcritic', '~> 5.0'

  # Integration gems
  spec.add_dependency 'test-kitchen', '~> 1.4'
  spec.add_dependency 'kitchen-vagrant'
  spec.add_dependency 'vagrant-wrapper'
  spec.add_dependency 'kitchen-docker'
  spec.add_dependency 'kitchen-sync', '~> 1.1'
  spec.add_dependency 'berkshelf', '~> 4.0'

  # Travis gems
  spec.add_dependency 'codeclimate-test-reporter', '~> 0.4'
  spec.add_dependency 'codecov', '~> 0.0', '>= 0.0.2'

  # Development dependencies (yo dawg)
  spec.add_development_dependency 'rspec-command', '~> 1.0'
end
