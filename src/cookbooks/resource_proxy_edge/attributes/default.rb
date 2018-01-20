# frozen_string_literal: true

#
# CONSULTEMPLATE
#

default['consul_template']['config_path'] = '/etc/consul-template.d/conf'
default['consul_template']['template_path'] = '/etc/consul-template.d/templates'

#
# FABIO
#

default['fabio']['install_path'] = '/usr/local/bin/fabio'
default['fabio']['conf_dir'] = '/etc/fabio.d'
default['fabio']['service_name'] = 'fabio'

default['fabio']['service_user'] = 'fabio'
default['fabio']['service_group'] = 'fabio'

default['fabio']['consul_template_file'] = 'fabio.ctmpl'
default['fabio']['config_file'] = 'fabio.properties'

# Installation source
fabio_version = '1.5.6'
default['fabio']['release_url'] = "https://github.com/fabiolb/fabio/releases/download/v#{fabio_version}/fabio-#{fabio_version}-go1.9.2-linux_amd64"
default['fabio']['checksum'] = '2DFE26AAA74B659A0E595654EB8F9247D947CBF652CBEBE03FD8133C2851CB4A'

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
