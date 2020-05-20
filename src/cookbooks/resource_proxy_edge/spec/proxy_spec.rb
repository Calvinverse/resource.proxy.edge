# frozen_string_literal: true

require 'spec_helper'

describe 'resource_proxy_edge::proxy' do
  context 'configures fabio' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }
    it 'installs the fabio binaries' do
      expect(chef_run).to create_remote_file('fabio_release_binary').with(
        path: '/usr/local/bin/fabio',
        source: 'https://github.com/fabiolb/fabio/releases/download/v1.5.12/fabio-1.5.12-go1.13.1-linux_amd64'
      )
    end

    it 'installs the fabio service' do
      expect(chef_run).to create_systemd_service('fabio').with(
        action: [:create],
        unit_after: %w[network-online.target],
        unit_description: 'Fabio',
        unit_documentation: 'https://github.com/fabiolb/fabio',
        unit_requires: %w[network-online.target],
        service_exec_start: '/usr/local/bin/fabio -cfg /etc/fabio.d/fabio.properties'
      )
    end

    it 'enables the fabio service' do
      expect(chef_run).to enable_service('fabio')
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
      -A ufw-before-input -p icmp --icmp-type time-exceeded -j ACCEPT
      -A ufw-before-input -p icmp --icmp-type parameter-problem -j ACCEPT
      -A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT

      # ok icmp code for FORWARD
      -A ufw-before-forward -p icmp --icmp-type destination-unreachable -j ACCEPT
      -A ufw-before-forward -p icmp --icmp-type time-exceeded -j ACCEPT
      -A ufw-before-forward -p icmp --icmp-type parameter-problem -j ACCEPT
      -A ufw-before-forward -p icmp --icmp-type echo-request -j ACCEPT

      # allow dhcp client to work
      -A ufw-before-input -p udp --sport 67 --dport 68 -j ACCEPT

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

  context 'adds the consul-template files for fabio' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    fabio_properties_template_content = <<~CONF
      # proxy.addr configures listeners.
      #
      proxy.addr = :7080

      # proxy.strategy configures the load balancing strategy.
      #
      proxy.strategy = rnd

      # proxy.matcher configures the path matching algorithm.
      #
      proxy.matcher = prefix

      # proxy.noroutestatus configures the response code when no route was found.
      #
      proxy.noroutestatus = 404

      # proxy.shutdownwait configures the time for a graceful shutdown.
      #
      proxy.shutdownwait = 0s

      # proxy.responseheadertimeout configures the response header timeout.
      #
      proxy.responseheadertimeout = 0s

      # proxy.keepalivetimeout configures the keep-alive timeout.
      #
      proxy.keepalivetimeout = 5s

      # log.access.format configures the format of the access log.
      #
      # If the value is either 'common' or 'combined' then the logs are written in
      # the Common Log Format or the Combined Log Format as defined below:
      #
      # 'common':   $remote_host - - [$time_common] "$request" $response_status $response_body_size
      # 'combined': $remote_host - - [$time_common] "$request" $response_status $response_body_size "$header.Referer" "$header.User-Agent"
      #
      # Otherwise, the value is interpreted as a custom log format which is defined
      # with the following parameters. Providing an empty format when logging is
      # enabled is an error. To disable access logging leave the log.access.target
      # value empty.
      #
      #   $header.<name>           - request http header (name: [a-zA-Z0-9-]+)
      #   $remote_addr             - host:port of remote client
      #   $remote_host             - host of remote client
      #   $remote_port             - port of remote client
      #   $request                 - request <method> <uri> <proto>
      #   $request_args            - request query parameters
      #   $request_host            - request host header (aka server name)
      #   $request_method          - request method
      #   $request_scheme          - request scheme
      #   $request_uri             - request URI
      #   $request_url             - request URL
      #   $request_proto           - request protocol
      #   $response_body_size      - response body size in bytes
      #   $response_status         - response status code
      #   $response_time_ms        - response time in S.sss format
      #   $response_time_us        - response time in S.ssssss format
      #   $response_time_ns        - response time in S.sssssssss format
      #   $time_rfc3339            - log timestamp in YYYY-MM-DDTHH:MM:SSZ format
      #   $time_rfc3339_ms         - log timestamp in YYYY-MM-DDTHH:MM:SS.sssZ format
      #   $time_rfc3339_us         - log timestamp in YYYY-MM-DDTHH:MM:SS.ssssssZ format
      #   $time_rfc3339_ns         - log timestamp in YYYY-MM-DDTHH:MM:SS.sssssssssZ format
      #   $time_unix_ms            - log timestamp in unix epoch ms
      #   $time_unix_us            - log timestamp in unix epoch us
      #   $time_unix_ns            - log timestamp in unix epoch ns
      #   $time_common             - log timestamp in DD/MMM/YYYY:HH:MM:SS -ZZZZ
      #   $upstream_addr           - host:port of upstream server
      #   $upstream_host           - host of upstream server
      #   $upstream_port           - port of upstream server
      #   $upstream_request_scheme - upstream request scheme
      #   $upstream_request_uri    - upstream request URI
      #   $upstream_request_url    - upstream request URL
      #   $upstream_service        - name of the upstream service
      #
      # The default is
      #
      log.access.format = AL - [$time_common] - $remote_host - $upstream_addr - "$request" $response_status

      # log.access.target configures where the access log is written to.
      #
      # Options are 'stdout'. If the value is empty no access log is written.
      #
      # The default is
      #
      log.access.target = stdout

      # log.level configures the log level.
      #
      # Valid levels are TRACE, DEBUG, INFO, WARN, ERROR and FATAL.
      #
      # The default is
      #
      log.level = DEBUG

      # registry.backend configures which backend is used.
      #
      registry.backend = consul

      # registry.timeout configures how long fabio tries to connect to the registry
      # backend during startup.
      #
      registry.timeout = 10s

      # registry.retry configures the interval with which fabio tries to
      # connect to the registry during startup.
      #
      registry.retry = 500ms

      # registry.file.noroutehtmlpath configures the KV path for the HTML of the
      # noroutes page.
      #
      registry.file.noroutehtmlpath = /config/services/proxy.edge/pages/noroutes.html

      # registry.consul.addr configures the address of the consul agent to connect to.
      #
      registry.consul.addr = localhost:8500

      # registry.consul.token configures the acl token for consul.
      #
      # The default is
      #
      # registry.consul.token =

      # registry.consul.kvpath configures the KV path for manual routes.
      #
      registry.consul.kvpath = /config/services/proxy.edge/routes

      # registry.consul.service.status configures the valid service status
      # values for services included in the routing table.
      #
      registry.consul.service.status = passing,warning

      # registry.consul.tagprefix configures the prefix for tags which define routes.
      #
      registry.consul.tagprefix = edgeproxyprefix-

      # registry.consul.register.enabled configures whether fabio registers itself in consul.
      #
      registry.consul.register.enabled = true

      # registry.consul.register.addr configures the address for the service registration.
      #
      registry.consul.register.addr = :9998

      # registry.consul.register.name configures the name for the service registration.
      #
      registry.consul.register.name = proxy

      # registry.consul.register.tags configures the tags for the service registration.
      #
      registry.consul.register.tags = edge, edge-incoming, incoming

      # registry.consul.register.checkInterval configures the interval for the health check.
      #
      registry.consul.register.checkInterval = 10s

      # registry.consul.register.checkTimeout configures the timeout for the health check.
      #
      registry.consul.register.checkTimeout = 3s

      # registry.consul.checksRequired configures how many health checks
      # must pass in order for fabio to consider a service available.
      #
      registry.consul.checksRequired = all

      # metrics.target configures the backend the metrics values are
      # sent to.
      #
      metrics.target = statsd

      # metrics.prefix configures the template for the prefix of all reported metrics.
      #
      # metrics.prefix = fabio.{{clean .Hostname}}

      # metrics.names configures the template for the route metric names.
      # The value is expanded by the text/template package and provides
      # the following variables:
      #
      #  - Service:   the service name
      #  - Host:      the host part of the URL prefix
      #  - Path:      the path part of the URL prefix
      #  - TargetURL: the URL of the target
      #
      # The following additional functions are defined:
      #
      #  - clean:     lowercase value and replace '.' and ':' with '_'
      #
      # metrics.names = {{clean .Service}}.{{clean .Host}}.{{clean .Path}}.{{clean .TargetURL.Host}}

      # metrics.statsd.addr configures the host:port of the StatsD
      # server. This is required when ${metrics.target} is set to "statsd".
      #
      metrics.statsd.addr = localhost:8125

      # ui.access configures the access mode for the UI.
      #
      ui.access = ro

      # ui.addr configures the address the UI is listening on.
      # The listener uses the same syntax as proxy.addr but
      # supports only a single listener. To enable HTTPS
      # configure a certificate source. You should use
      # a different certificate source than the one you
      # use for the external connections, e.g. 'cs=ui'.
      #
      ui.addr = :9998

      # ui.color configures the background color of the UI.
      # Color names are from http://materializecss.com/color.html
      #
      ui.color = [[ keyOrDefault "config/services/proxy.edge/ui/color" "light-blue" ]]

      # ui.title configures an optional title for the UI.
      #
      ui.title = [[ keyOrDefault "config/services/proxy.edge/ui/title" "" ]]
    CONF
    it 'creates fabio template file in the consul-template template directory' do
      expect(chef_run).to create_file('/etc/consul-template.d/templates/fabio.ctmpl')
        .with_content(fabio_properties_template_content)
    end

    consul_template_fabio_properties_content = <<~CONF
      # This block defines the configuration for a template. Unlike other blocks,
      # this block may be specified multiple times to configure multiple templates.
      # It is also possible to configure templates via the CLI directly.
      template {
        # This is the source file on disk to use as the input template. This is often
        # called the "Consul Template template". This option is required if not using
        # the `contents` option.
        source = "/etc/consul-template.d/templates/fabio.ctmpl"

        # This is the destination path on disk where the source template will render.
        # If the parent directories do not exist, Consul Template will attempt to
        # create them, unless create_dest_dirs is false.
        destination = "/etc/fabio.d/fabio.properties"

        # This options tells Consul Template to create the parent directories of the
        # destination path if they do not exist. The default value is true.
        create_dest_dirs = false

        # This is the optional command to run when the template is rendered. The
        # command will only run if the resulting template changes. The command must
        # return within 30s (configurable), and it must have a successful exit code.
        # Consul Template is not a replacement for a process monitor or init system.
        command = "systemctl restart fabio"

        # This is the maximum amount of time to wait for the optional command to
        # return. Default is 30s.
        command_timeout = "15s"

        # Exit with an error when accessing a struct or map field/key that does not
        # exist. The default behavior will print "<no value>" when accessing a field
        # that does not exist. It is highly recommended you set this to "true" when
        # retrieving secrets from Vault.
        error_on_missing_key = false

        # This is the permission to render the file. If this option is left
        # unspecified, Consul Template will attempt to match the permissions of the
        # file that already exists at the destination path. If no file exists at that
        # path, the permissions are 0644.
        perms = 0755

        # This option backs up the previously rendered template at the destination
        # path before writing a new one. It keeps exactly one backup. This option is
        # useful for preventing accidental changes to the data without having a
        # rollback strategy.
        backup = true

        # These are the delimiters to use in the template. The default is "{{" and
        # "}}", but for some templates, it may be easier to use a different delimiter
        # that does not conflict with the output file itself.
        left_delimiter  = "[["
        right_delimiter = "]]"

        # This is the `minimum(:maximum)` to wait before rendering a new template to
        # disk and triggering a command, separated by a colon (`:`). If the optional
        # maximum value is omitted, it is assumed to be 4x the required minimum value.
        # This is a numeric time with a unit suffix ("5s"). There is no default value.
        # The wait value for a template takes precedence over any globally-configured
        # wait.
        wait {
          min = "2s"
          max = "10s"
        }
      }
    CONF
    it 'creates fabio.hcl in the consul-template template directory' do
      expect(chef_run).to create_file('/etc/consul-template.d/conf/fabio.hcl')
        .with_content(consul_template_fabio_properties_content)
    end
  end
end
