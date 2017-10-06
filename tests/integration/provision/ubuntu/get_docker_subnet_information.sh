#!/bin/bash

# Return the gateway IP address. This should match the subnet
# The first argument ($1) is the IP addres of the host
function f_getContainerGateway {
    echo '192.168.6.1'
}

# Return the subnet as a string. This is used to create a docker network with the given
# subnet.
# The first argument ($1) is the IP addres of the host
function f_getContainerSubnet {
    echo '192.168.6.128/25'
}

# Return the private address space that the host interface is on.
# The first argument ($1) is the IP addres of the host
function f_getPrivateAddressSpace {
    echo '192.168.6.0/24'
}

# Return the VLAN tag as a string.
function f_getVlanTag {
    echo ''
}
