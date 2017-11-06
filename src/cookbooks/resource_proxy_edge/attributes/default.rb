# frozen_string_literal: true

#
# CONSUL
#

default['consul']['version'] = '0.9.2'
default['consul']['config']['domain'] = 'consulverse'

# This is not a consul server node
default['consul']['config']['server'] = false

# For the time being don't verify incoming and outgoing TLS signatures
default['consul']['config']['verify_incoming'] = false
default['consul']['config']['verify_outgoing'] = false

# Bind the client address to the local host. The advertise and bind addresses
# will be set in a separate configuration file
default['consul']['config']['client_addr'] = '127.0.0.1'

# Do not allow consul to use the host information for the node id
default['consul']['config']['disable_host_node_id'] = true

# Disable remote exec
default['consul']['config']['disable_remote_exec'] = true

# Disable the update check
default['consul']['config']['disable_update_check'] = true

# Set the DNS configuration
default['consul']['config']['dns_config'] = {
  allow_stale: true,
  max_stale: '87600h',
  node_ttl: '10s',
  service_ttl: {
    '*': '10s'
  }
}

# Always leave the cluster if we are terminated
default['consul']['config']['leave_on_terminate'] = true

# Send all logs to syslog
default['consul']['config']['log_level'] = 'INFO'
default['consul']['config']['enable_syslog'] = true

default['consul']['config']['owner'] = 'root'

#
# FABIO
#

default['fabio']['install_path'] = '/usr/local/bin/fabio'
default['fabio']['conf_dir'] = '/etc/fabio.d'
default['fabio']['service_name'] = 'fabio'

default['fabio']['service_user'] = 'fabio'
default['fabio']['service_group'] = 'fabio'

# Installation source
fabio_version = '1.5.3'
default['fabio']['release_url'] = "https://github.com/fabiolb/fabio/releases/download/v#{fabio_version}/fabio-#{fabio_version}-go1.9.2-linux_amd64"
default['fabio']['checksum'] = 'AD352A3E770215219C57257C5DCBB14AEE83AA50DB32BA34431372B570AA58E5'

#
# FIREWALL
#

# Allow communication on the loopback address (127.0.0.1 and ::1)
default['firewall']['allow_loopback'] = true

# Do not allow MOSH connections
default['firewall']['allow_mosh'] = false

# Do not allow WinRM (which wouldn't work on Linux anyway, but close the ports just to be sure)
default['firewall']['allow_winrm'] = false

# No communication via IPv6 at all
default['firewall']['ipv6_enabled'] = false

#
# PROVISIONING
#

#
# UNBOUND
#

default['unbound']['service_user'] = 'unbound'
default['unbound']['service_group'] = 'unbound'

default['paths']['unbound_config'] = '/etc/unbound.d'

default['file_name']['unbound_config_file'] = 'unbound.conf'
