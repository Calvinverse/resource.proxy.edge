# frozen_string_literal: true

#
# Cookbook Name:: resource_proxy_edge
# Recipe:: default
#
# Copyright 2017, P. van der Velde
#

# Always make sure that apt is up to date
apt_update 'update' do
  action :update
end

#
# Include the local recipes
#

include_recipe 'resource_proxy_edge::firewall'

include_recipe 'resource_proxy_edge::consul'
include_recipe 'resource_proxy_edge::meta'
include_recipe 'resource_proxy_edge::network'
include_recipe 'resource_proxy_edge::provisioning'
include_recipe 'resource_proxy_edge::proxy'
