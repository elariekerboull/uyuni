# Copyright (c) 2022 SUSE LLC
# Licensed under the terms of the MIT license.
#
# The scenarios in this feature are skipped:
# * if there is no proxy ($proxy is nil)
# * if there is no salt minion ($sle_minion is nil)
# * if there is no scope @scope_containerized_proxy

@scope_containerized_proxy
@proxy
@sle_minion
Feature: Register and test a Containerized Proxy
  In order to test Containerized Proxy
  As the system administrator
  I want to register the proxy to the server

  Scenario: Log in as admin user
    Given I am authorized for the "Admin" section

  Scenario: Pre-requisite: Unregister Salt minion in the traditional proxy
    Given I am on the Systems overview page of this "sle_minion"
    When I follow "Delete System"
    Then I should see a "Confirm System Profile Deletion" text
    When I click on "Delete Profile"
    And I wait until I see "has been deleted" text
    Then "sle_minion" should not be registered

# NOTE: Let's see how it behaves if we don't delete this system, it will override it?
#  Scenario: Pre-requisite: Unregister traditional proxy
#    Given I am on the Systems overview page of this "proxy"
#    When I follow "Delete System"
#    Then I should see a "Confirm System Profile Deletion" text
#    When I click on "Delete Profile"
#    And I wait until I see "has been deleted" text
#    Then "proxy" should not be registered

  Scenario: Pre-requisite: Stop traditional proxy service
    When I stop salt-minion on "proxy"
    And I run "spacewalk-proxy stop" on "proxy"

  Scenario: Pre-requisite: Proxy VM use an alternative SSH Port
    When I set "8022" as SSH port on the proxy host

  Scenario: Generate Containerized proxy configuration
    When I generate the configuration "/tmp/proxy_container_config.zip" of containerized proxy on the server
    And I copy "/tmp/proxy_container_config.zip" file from "server" to "proxy"
    And I run "unzip /tmp/proxy_container_config.zip -d /root/proxy-config" on "proxy"

  Scenario: Start Containerized proxy services
    When I start "pod-proxy-pod" service on "proxy"

  Scenario: Bootstrap a Salt minion in the Containerized proxy
    When I follow the left menu "Systems > Bootstrapping"
    Then I should see a "Bootstrap Minions" text
    When I enter the hostname of "sle_minion" as "hostname"
    And I enter "22" as "port"
    And I enter "root" as "user"
    And I enter "linux" as "password"
    And I select the hostname of "proxy" from "proxies"
    And I click on "Bootstrap"
    And I wait until I see "Successfully bootstrapped host!" text

  Scenario: Check the new bootstrapped minion in System Overview page
    When I follow the left menu "Salt > Keys"
    And I wait until I do not see "Loading..." text
    Then I should see a "accepted" text
    When I follow the left menu "Systems > Overview"
    And I wait until I see the name of "sle_minion", refreshing the page
    And I wait until onboarding is completed for "sle_minion"
    Then the Salt master can reach "sle_minion"

  Scenario: Check connection from minion to containerized proxy
    Given I am on the Systems overview page of this "sle_minion"
    When I follow "Details" in the content area
    And I follow "Connection" in the content area
    Then I should see "proxy" short hostname

  Scenario: Check registration on containerized proxy of minion
    Given I am on the Systems overview page of this "proxy"
    When I follow "Details" in the content area
    And I follow "Proxy" in the content area
    Then I should see "sle_minion" hostname

  Scenario: Salt minion grains are displayed correctly on the details page
    Given I am on the Systems overview page of this "sle_minion"
    Then the hostname for "sle_minion" should be correct
    And the kernel for "sle_minion" should be correct
    And the OS version for "sle_minion" should be correct
    And the IPv4 address for "sle_minion" should be correct
    And the IPv6 address for "sle_minion" should be correct
    And the system ID for "sle_minion" should be correct
    And the system name for "sle_minion" should be correct
    And the uptime for "sle_minion" should be correct
    And I should see several text fields for "sle_minion"

  Scenario: Install a patch on the Salt minion
    When I follow "Software" in the content area
    And I follow "Patches" in the content area
    And I select "Non-Critical" from "type"
    And I click on "Show"
    When I check the first patch in the list
    And I click on "Apply Patches"
    And I click on "Confirm"
    Then I should see a "1 patch update has been scheduled for" text
    When I force picking pending events on "sle_minion" if necessary
    And I wait until event "Patch Update:" is completed
    And I regenerate the boot RAM disk on "sle_minion" if necessary

  Scenario: Remove package from Salt minion
    When I follow "Software" in the content area
    And I follow "Install"
    And I enter the package for "sle_minion" as the filtered package name
    And I click on the filter button
    And I check the package for "sle_minion" in the list
    And I click on "Install Selected Packages"
    And I click on "Confirm"
    Then I should see a "1 package install has been scheduled for" text
    When I force picking pending events on "sle_minion" if necessary
    And I wait until event "Package Install/Upgrade scheduled by admin" is completed

  Scenario: Remove package from Salt minion
    When I follow "Software" in the content area
    And I follow "List / Remove"
    And I enter the package for "sle_minion" as the filtered package name
    And I click on the filter button
    And I check the package for "sle_minion" in the list
    And I click on "Remove Packages"
    And I click on "Confirm"
    Then I should see a "1 package removal has been scheduled" text
    When I force picking pending events on "sle_minion" if necessary
    And I wait until event "Package Removal scheduled by admin" is completed

  Scenario: Run a remote command on Salt minion
    When I follow the left menu "Salt > Remote Commands"
    Then I should see a "Remote Commands" text in the content area
    When I enter command "echo 'My remote command output'"
    And I enter the hostname of "sle_minion" as "target"
    And I click on preview
    Then I should see a "Target systems (1)" text
    When I wait until I do not see "pending" text
    And I click on run
    And I wait until I see "show response" text
    And I expand the results for "sle_minion"
    Then I should see "My remote command output" in the command output for "sle_minion"

  Scenario: Check that Software package refresh works on a Salt minion
    Given I am on the Systems overview page of this "sle_minion"
    When I follow "Software" in the content area
    And I click on "Update Package List"
    And I force picking pending events on "sle_minion" if necessary
    And I wait until event "Package List Refresh scheduled by admin" is completed

  Scenario: Check that Hardware Refresh button works on a Salt minion
    When I follow "Details" in the content area
    And I follow "Hardware"
    And I click on "Schedule Hardware Refresh"
    Then I should see a "You have successfully scheduled a hardware profile refresh" text
    When I force picking pending events on "sle_minion" if necessary
    And I wait until event "Hardware List Refresh scheduled by admin" is completed

  Scenario: Subscribe a Salt minion to the configuration channel
    When I follow "Configuration" in the content area
    And I follow "Manage Configuration Channels" in the content area
    And I follow first "Subscribe to Channels" in the content area
    And I check "Mixed Channel" in the list
    And I click on "Continue"
    And I click on "Update Channel Rankings"
    Then I should see a "Channel Subscriptions successfully changed for" text

  Scenario: Deploy the configuration file to Salt minion
    And I follow the left menu "Configuration > Channels"
    And I follow "Mixed Channel"
    And I follow "Deploy all configuration files to selected subscribed systems"
    And I enter the hostname of "sle_minion" as the filtered system name
    And I click on the filter button
    And I check the "sle_minion" client
    And I click on "Confirm & Deploy to Selected Systems"
    Then I should see a "/etc/s-mgr/config" link
    When I click on "Deploy Files to Selected Systems"
    Then I should see a "being scheduled" text
    And I should see a "0 revision-deploys overridden." text
    When I force picking pending events on "sle_minion" if necessary
    And I wait until file "/etc/s-mgr/config" exists on "sle_minion"
    Then file "/etc/s-mgr/config" should contain "COLOR=white" on "sle_minion"

  Scenario: Reboot the Salt minion and wait until reboot is completed
    Given I am on the Systems overview page of this "sle_minion"
    When I follow first "Schedule System Reboot"
    Then I should see a "System Reboot Confirmation" text
    And I should see a "Reboot system" button
    When I click on "Reboot system"
    Then I should see a "Reboot scheduled for system" text
    When I force picking pending events on "sle_minion" if necessary
    And I wait at most 600 seconds until event "System reboot scheduled by admin" is completed
    Then I should see a "This action's status is: Completed" text

  Scenario: Install spacecmd from the client tools on the Salt minion
    When I follow "Software" in the content area
    And I follow "Install"
    And I enter "spacecmd" as the filtered package name
    And I click on the filter button
    And I check "spacecmd" in the list
    And I click on "Install Selected Packages"
    And I click on "Confirm"
    Then I should see a "1 package install has been scheduled for" text
    When I force picking pending events on "sle_minion" if necessary
    And I wait until event "Package Install/Upgrade scheduled by admin" is completed

  Scenario: Cleanup: Unregister a Salt minion in the Containerized proxy
    Given I am on the Systems overview page of this "sle_minion"
    When I follow "Delete System"
    Then I should see a "Confirm System Profile Deletion" text
    When I click on "Delete Profile"
    And I wait until I see "has been deleted" text
    Then "sle_minion" should not be registered

  Scenario: Cleanup: Unregister Containerized proxy
    Given I am on the Systems overview page of this "proxy"
    When I follow "Delete System"
    Then I should see a "Confirm System Profile Deletion" text
    When I click on "Delete Profile"
    And I wait until I see "has been deleted" text
    Then "proxy" should not be registered

  Scenario: Cleanup: Stop Containerized proxy services
    When I stop "pod-proxy-pod" service on "proxy"

  Scenario: Cleanup: Remove Containerized proxy configuration
    When I ensure folder "/root/proxy-config" doesn't exist on "proxy"
    And I remove "/tmp/proxy_container_config.zip" from "proxy"
    And I remove "/tmp/proxy_container_config.zip" from "server"

  Scenario: Cleanup: Proxy VM use default SSH Port
    When I set "22" as SSH port on the proxy host

  Scenario: Cleanup: Start traditional proxy service
    When I start salt-minion on "proxy"
    And I run "spacewalk-proxy start" on "proxy"

  @skip_if_salt_bundle
  Scenario: Cleanup: Create the bootstrap script for the traditional proxy and use it
    When I execute mgr-bootstrap "--script=bootstrap-proxy.sh --no-up2date"
    Then I should get "* bootstrap script (written):"
    And I should get "    '/srv/www/htdocs/pub/bootstrap/bootstrap-proxy.sh'"
    When I fetch "pub/bootstrap/bootstrap-proxy.sh" to "proxy"
    And I run "sh ./bootstrap-proxy.sh" on "proxy"

  @salt_bundle
  Scenario: Cleanup: Create the bootstrap script for the traditional proxy and use it
    When I execute mgr-bootstrap "--script=bootstrap-proxy.sh --no-up2date --force-bundle"
    Then I should get "* bootstrap script (written):"
    And I should get "    '/srv/www/htdocs/pub/bootstrap/bootstrap-proxy.sh'"
    When I fetch "pub/bootstrap/bootstrap-proxy.sh" to "proxy"
    And I run "sh ./bootstrap-proxy.sh" on "proxy"

  Scenario: Cleanup: Configure the traditional proxy
    When I follow the left menu "Salt > Keys"
    And I wait until I see "pending" text, refreshing the page
    And I accept "proxy" key
    When I wait until onboarding is completed for "proxy"
    When I copy server's keys to the proxy
    And I configure the proxy
    Then I should see "proxy" via spacecmd
    And service "salt-broker" is active on "proxy"
    When I enable repositories before installing branch server
    And I install package "expect" on this "proxy"
    And I disable repositories after installing branch server
    When I run "rm /srv/www/htdocs/pub/bootstrap/bootstrap-proxy.sh" on "server"
    And I run "rm /root/bootstrap-proxy.sh" on "proxy"

# TODO: Expect an issue here, as the traditional proxy might not have any system registered at that point in time.
#       But we need to unregister it as precondition, otherwise the containerized proxy can't use the same FQDN to
#       be registered.
#       Unless... the new containerized proxy automatically obtain all the systems registered by the previous
#       proxy set in the same FQDN.
