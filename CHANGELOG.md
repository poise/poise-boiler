# Changelog

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
