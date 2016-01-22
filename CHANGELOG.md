# Changelog

## v1.5.0

* Can't actually force TK 1.5 because of https://github.com/test-kitchen/test-kitchen/issues/922.

## v1.4.0

* Actually support Test Kitchen 1.5 correctly. Don't use 1.3.0.

## v1.3.0

* Upgrade to Test Kitchen 1.5 and Foodcritic 6.0.

## v1.2.0

* A full suite of release automation commands.
* Re-add the `travis` gem as a dependency now that it has removed the ancient
  `pry` it depended on.
* Improved handling for setting test verbosity in a unified way.

## v1.1.11

* Make sure `ss` is available on EL7 for `port` resources in Serverspec.

## v1.1.10

* Better fix for faraday gzip issues.

## v1.1.9

* Lock `ridley` dependency pending upstream fixes in a few days.

## v1.1.8

* Don't install documentation for busser gems.
* Install net-tools for common platforms for serverspec.
* Improve `no_gem` mode for spec_helper.

## v1.1.7

* Bump foodcritic dependency for 5.0.
* Ensure `ohai['hostname']` and friends work on CentOS 7.

## v1.1.6

* Revert the 1.1.5 change.
* Update download URL for Docker.

## v1.1.5

* Workaround for broken Test Kitchen. To be reverted after the next TK release.

## v1.1.4

* Master integration tests use the correct Chef version.
* Don't filter the `:focus` tag in CI. This prevents bad data in my coverage
  graphs when I accidentally commit a focused test.
* Only try to run the integration tests if `.kitchen.yml` exists.

## v1.1.3

* Use the new Test Kitchen 1.4 transport from kitchen-sync.
* Run integration tests for master builds using Chef nightlies.

## v1.1.2

* Unbreak Rackspace integration testing support.

## v1.1.1

* Don't mask errors from failed subtasks of `rake travis`.
* Use the `chef:kitchen` task for running Test Kitchen on Travis.

## v1.1.0

* Support for kitchen-rackspace'd cookbooks.

## v1.0.0

* Initial release!
