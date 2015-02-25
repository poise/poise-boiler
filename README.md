# Poise-Boiler

[![Build Status](https://img.shields.io/travis/poise/poise-boiler.svg)](https://travis-ci.org/poise/poise-boiler)
[![Gem Version](https://img.shields.io/gem/v/poise-boiler.svg)](https://rubygems.org/gems/poise-boiler)
[![Code Climate](https://img.shields.io/codeclimate/github/poise/poise-boiler.svg)](https://codeclimate.com/github/poise/poise-boiler)
[![Gemnasium](https://img.shields.io/gemnasium/poise/poise-boiler.svg)](https://gemnasium.com/poise/poise-boiler)
[![License](https://img.shields.io/badge/license-Apache_2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

Poise-boiler is a set of helpers to reduce boilerplate in Poise/Halite style
gems.

## Dependencies

`poise-boiler` depends on a base set of useful gems for building Halite cookbooks.
Make sure you only add it as a development dependency:

```ruby
spec.add_development_dependency('poise-boiler', '~> 1.0')
```

## `spec_helper`

The `spec_helper` sets up `chefspec`, `rspec-its`, and `simplecov`. Coverage
reporting is also configured for CodeClimate and CodeCov if the relevant
environment variables are set. The Halite spec helper is also enabled by
default:

```ruby
require 'poise_boiler/spec_helper'
```

You can disable the Halite spec helper if needed:

```ruby
require 'poise_boiler'
PoiseBoiler.include_halite_spec_helper = false
require 'poise_boiler/spec_helper'
```

## `Rakefile`

The `Rakefile` helper sets up the standard gem tasks, the Halite helper tasks,
and a `spec` task to run unit tests.

```ruby
require 'poise_boiler/rakefile'
```

## License

Copyright 2015, Noah Kantrowitz

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
