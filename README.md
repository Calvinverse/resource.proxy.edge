# resource.proxy.edge

This repository contains the source code necessary to build Ubuntu Hyper-V hard-drives containing the
[Fabio](https://github.com/fabiolb/fabio) reverse proxy.

The resulting hard-drive is used to create Hyper-V virtual machines which act as a reverse proxy
which allows the users to access the different services in a given environment
without having to know the individual addresses of these services. The Fabio reverse proxy will
automatically detect the different instances and handle the proxying of the HTTP calls. Each
environment can have one or more instances at known IP addresses so that a DNS name can be
pointed to the machines.

## Image

The image is created by using the [Linux base image](http://tfs:8080/tfs/Vista/DevInfrastructure/_git/Template-Resource.Linux.Ubuntu.Server)
and amending it using a [Chef](https://www.chef.io/chef/) cookbook which installs Fabio.

### Contents

In addition to the default applications installed in the template image the following items are
also installed and configured:

* [Fabio](https://github.com/fabiolb/fabio) - Provides the reverse proxy capabilities

The image is configured to add Fabio as a service to the Consul services list with under the
`proxy` service name.

### Configuration

The configuration for the Fabio instance comes from a
[Consul-Template](https://github.com/hashicorp/consul-template) template file which replaces some
of the template parameters with values from the Consul Key-Value store.

Important parts of the configuration file are

* The title of the Fabio UI will have the Consul environment name.
* The color of the Fabio is set to indicate how important the environment is.

### Provisioning

No additional configuration is applied other than the default one for the base image.

### Logs

No additional configuration is applied other than the default one for the base image.

### Metrics

Metrics are collected by Fabio sending [StatsD](https://www.vaultproject.io/docs/internals/telemetry.html)
metrics to [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/).

## Build, test and release

The build process follows the standard procedure for
[building Calvinverse images](https://www.calvinverse.net/documentation/how-to-build).

## Deploy

* Download the new image to one of your Hyper-V hosts.
* Create a directory for the image and copy the image VHDX file there.
* Create a VM that points to the image VHDX file with the following settings
  * Generation: 2
  * RAM: at least 1024 Mb
  * Hard disk: Use existing. Copy the path to the VHDX file
  * Attach the VM to a suitable network
* Update the VM settings:
  * Enable secure boot. Use the Microsoft UEFI Certificate Authority
  * Attach a DVD image that points to an ISO file containing the settings for the environment. These
    are normally found in the output of the [Calvinverse.Infrastructure](https://github.com/Calvinverse/calvinverse.infrastructure)
    repository. Pick the correct ISO for the task, in this case the `Linux Consul Client` image
  * Disable checkpoints
  * Set the VM to always start
  * Set the VM to shut down on stop
* Start the VM, it should automatically connect to the correct environment once it has provisioned
* Remove the old VM
  * SSH into the host
  * Issue the `consul leave` command
  * Shut the machine down with the `sudo shutdown now` command
  * Once the machine has stopped, delete it

