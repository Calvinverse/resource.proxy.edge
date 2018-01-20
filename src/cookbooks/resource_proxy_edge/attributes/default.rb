# frozen_string_literal: true

#
#


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
