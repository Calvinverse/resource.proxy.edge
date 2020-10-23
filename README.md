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

There are two different images that can be created. One for use on a Hyper-V server and one for use
in Azure. Which image is created depends on the build command line used.

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

### Hyper-V

For building Hyper-V images use the following command line

    msbuild entrypoint.msbuild /t:build /P:ShouldCreateHypervImage=true /P:RepositoryArchive=PATH_TO_ARTIFACTLOCATION

where `PATH_TO_ARTIFACTLOCATION` is the full path to the directory where the base image artifact
file is stored.

In order to run the smoke tests on the generated image run the following command line

    msbuild entrypoint.msbuild /t:test /P:ShouldCreateHypervImage=true


### Azure

For building Azure images use the following command line

    msbuild entrypoint.msbuild /t:build
        /P:ShouldCreateAzureImage=true
        /P:AzureLocation=LOCATION
        /P:AzureClientId=CLIENT_ID
        /P:AzureClientCertPath=CLIENT_CERT_PATH
        /P:AzureSubscriptionId=SUBSCRIPTION_ID
        /P:AzureImageResourceGroup=IMAGE_RESOURCE_GROUP

where:

* `LOCATION` - The azure data center in which the image should be created. Note that this needs to be the same
  region as the location of the base image. If you want to create the image in a different location then you need to
  copy the base image to that region first.
* `CLIENT_ID` - The client ID of the user that [Packer](https://packer.io) will use to
  [authenticate with Azure](https://www.packer.io/docs/builders/azure#azure-active-directory-service-principal).
* `CLIENT_CERT_PATH` - The client certificate which Packer will use to authenticate with Azure
* `SUBSCRIPTION_ID` - The subscription ID in which the image should be created.
* `IMAGE_RESOURCE_GROUP` - The resource group from which the base image will be pulled and in which the new image
  will be placed once the build completes.

For running the smoke tests on the Azure image

    msbuild entrypoint.msbuild /t:test
        /P:ShouldCreateAzureImage=true
        /P:AzureLocation=LOCATION
        /P:AzureClientId=CLIENT_ID
        /P:AzureClientCertPath=CLIENT_CERT_PATH
        /P:AzureSubscriptionId=SUBSCRIPTION_ID
        /P:AzureImageResourceGroup=IMAGE_RESOURCE_GROUP
        /P:AzureTestImageResourceGroup=TEST_RESOURCE_GROUP

where all the arguments are similar to the build arguments and `TEST_RESOURCE_GROUP` points to an Azure resource
group in which the test images are placed. Note that this resource group needs to be cleaned out after successful
tests have been run because Packer will in that case create a new image.

## Deploy

### Hyper-V

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

### Azure

The easiest way to deploy the Azure images into a cluster on Azure is to use the terraform scripts
provided by the [Azure ingress](https://github.com/Calvinverse/infrastructure.azure.core.ingress)
repository. Those scripts will create a Consul cluster of the suitable size and add a single instance
of a node with the Consul UI enabled.
