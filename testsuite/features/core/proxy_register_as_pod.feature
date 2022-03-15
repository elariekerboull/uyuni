# Copyright (c) 2022 SUSE LLC
# Licensed under the terms of the MIT license.
#
# The scenarios in this feature are skipped if:
# * if there is no proxy ($proxy is nil)
# * if there is no scope @scope_containerized_proxy
#
# Alternative: Bootstrap the proxy as a Pod

@scope_containerized_proxy
@proxy
Feature: Setup Uyuni containerized proxy
  In order to use a containerized proxy with the Uyuni server
  As the system administrator
  I want to register the containerized proxy to the server

  Scenario: Log in as admin user
    Given I am authorized for the "Admin" section

  Scenario: Proxy VM use an alternative SSH Port
    When I set "8022" as SSH port on the proxy host

  Scenario: Generate Containerized proxy configuration
    When I generate the configuration "/tmp/proxy_container_config.zip" of containerized proxy on the server
    And I copy "/tmp/proxy_container_config.zip" file from "server" to "proxy"
    And I run "unzip /tmp/proxy_container_config.zip -d /root/proxy-config" on "proxy"

  Scenario: Start Containerized proxy services
    When I start "pod-proxy-pod" service on "proxy"
