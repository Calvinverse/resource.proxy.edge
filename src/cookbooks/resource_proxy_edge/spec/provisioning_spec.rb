# frozen_string_literal: true

require 'spec_helper'

describe 'resource_proxy_edge::provisioning' do
  context 'configures provisioning' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'enables the provisioning service' do
      expect(chef_run).to enable_service('provision.service')
    end

    it 'creates provision_image.sh in the /etc/provision.d directory' do
      expect(chef_run).to create_file('/etc/provision.d/provision_image.sh')
    end
  end
end
