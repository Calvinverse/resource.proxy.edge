# frozen_string_literal: true

#
# Cookbook Name:: resource_proxy_edge
# Recipe:: provisioning
#
# Copyright 2017, P. van der Velde
#

service 'provision.service' do
  action [:enable]
end

file '/etc/init.d/provision_image.sh' do
  action :create
  content <<~BASH
    #!/bin/bash

    function f_provisionImage {
      cp -a /etc/ufw/before.rules.tocopy /etc/ufw/before.rules
    }
  BASH
  mode '755'
end
