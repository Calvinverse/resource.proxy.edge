# frozen_string_literal: true

require 'spec_helper'

describe 'resource_proxy_edge::proxy' do
  context 'configures fabio' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }
    it 'installs the fabio binaries' do
      expect(chef_run).to create_remote_file('fabio_release_binary').with(
        path: '/usr/local/bin/fabio',
        source: 'https://github.com/fabiolb/fabio/releases/download/v1.5.3/fabio-1.5.3-go1.9.2-linux_amd64'
      )
    end

    it 'installs the fabio service' do
      expect(chef_run).to create_systemd_service('fabio').with(
        action: [:create],
        after: %w[network-online.target],
        description: 'Fabio',
        documentation: 'https://github.com/fabiolb/fabio',
        requires: %w[network-online.target]
      )
    end

    it 'disables the fabio service' do
      expect(chef_run).to disable_service('fabio')
    end
  end

  context 'configures the firewall for fabio' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    ufw_before_rules_content = <<~UFWRULES
      #
      # rules.before
      #
      # Rules that should be run before the ufw command line added rules. Custom
      # rules should be added to one of these chains:
      #   ufw-before-input
      #   ufw-before-output
      #   ufw-before-forward
      #

      # Redirect port 80 and port 443 so that fabio can get to it
      *nat
      :PREROUTING ACCEPT [0:0]
      -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 7080
      -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 7443
      COMMIT

      # Don't delete these required lines, otherwise there will be errors
      *filter
      :ufw-before-input - [0:0]
      :ufw-before-output - [0:0]
      :ufw-before-forward - [0:0]
      :ufw-not-local - [0:0]
      # End required lines


      # allow all on loopback
      -A ufw-before-input -i lo -j ACCEPT
      -A ufw-before-output -o lo -j ACCEPT

      # quickly process packets for which we already have a connection
      -A ufw-before-input -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
      -A ufw-before-output -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
      -A ufw-before-forward -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

      # drop INVALID packets (logs these in loglevel medium and higher)
      -A ufw-before-input -m conntrack --ctstate INVALID -j ufw-logging-deny
      -A ufw-before-input -m conntrack --ctstate INVALID -j DROP

      # ok icmp codes for INPUT
      -A ufw-before-input -p icmp --icmp-type destination-unreachable -j ACCEPT
      -A ufw-before-input -p icmp --icmp-type source-quench -j ACCEPT
      -A ufw-before-input -p icmp --icmp-type time-exceeded -j ACCEPT
      -A ufw-before-input -p icmp --icmp-type parameter-problem -j ACCEPT
      -A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT

      # ok icmp code for FORWARD
      -A ufw-before-forward -p icmp --icmp-type destination-unreachable -j ACCEPT
      -A ufw-before-forward -p icmp --icmp-type source-quench -j ACCEPT
      -A ufw-before-forward -p icmp --icmp-type time-exceeded -j ACCEPT
      -A ufw-before-forward -p icmp --icmp-type parameter-problem -j ACCEPT
      -A ufw-before-forward -p icmp --icmp-type echo-request -j ACCEPT

      # allow dhcp client to work
      -A ufw-before-input -p udp --sport 67 --dport 68 -j ACCEPT

      #
      # ufw-not-local
      #
      -A ufw-before-input -j ufw-not-local

      # if LOCAL, RETURN
      -A ufw-not-local -m addrtype --dst-type LOCAL -j RETURN

      # if MULTICAST, RETURN
      -A ufw-not-local -m addrtype --dst-type MULTICAST -j RETURN

      # if BROADCAST, RETURN
      -A ufw-not-local -m addrtype --dst-type BROADCAST -j RETURN

      # all other non-local packets are dropped
      -A ufw-not-local -m limit --limit 3/min --limit-burst 10 -j ufw-logging-deny
      -A ufw-not-local -j DROP

      # allow MULTICAST mDNS for service discovery (be sure the MULTICAST line above
      # is uncommented)
      -A ufw-before-input -p udp -d 224.0.0.251 --dport 5353 -j ACCEPT

      # allow MULTICAST UPnP for service discovery (be sure the MULTICAST line above
      # is uncommented)
      -A ufw-before-input -p udp -d 239.255.255.250 --dport 1900 -j ACCEPT

      # don't delete the 'COMMIT' line or these rules won't be processed
      COMMIT
    UFWRULES
    it 'updates the UFW before configuration file' do
      expect(chef_run).to create_file('/etc/ufw/before.rules.tocopy')
        .with_content(ufw_before_rules_content)
    end
  end

  context 'configures the firewall for fabio' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'opens the HTTP port' do
      expect(chef_run).to create_firewall_rule('http').with(
        command: :allow,
        dest_port: 80,
        direction: :in
      )
    end

    it 'opens the HTTPS port' do
      expect(chef_run).to create_firewall_rule('https').with(
        command: :allow,
        dest_port: 443,
        direction: :in
      )
    end

    it 'opens the Fabio HTTP port' do
      expect(chef_run).to create_firewall_rule('proxy-http').with(
        command: :allow,
        dest_port: 7080,
        direction: :in
      )
    end

    it 'opens the Fabio HTTPS port' do
      expect(chef_run).to create_firewall_rule('proxy-https').with(
        command: :allow,
        dest_port: 7443,
        direction: :in
      )
    end

    it 'opens the Fabio UI port' do
      expect(chef_run).to create_firewall_rule('proxy-ui-http').with(
        command: :allow,
        dest_port: 9998,
        direction: :in
      )
    end
  end
end
