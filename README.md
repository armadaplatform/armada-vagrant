# armada-vagrant

`armada-vagrant` is a service that is used to serve [Vagrantfile](http://vagrantup.com) that will run virtual machine
with preinstalled Armada.
Using this service is a recommended way to learn Armada. It is also a convenient base for vagrant images
for your own microservices.

# Using the service.

After the service has been built it contains proper Armada image in the container. To access it run:

    armada run static-file-server -r armada-vagrant -v [absolute path to static dir]

Endpoint for `Vagrantfile` provided by the service is [/ArmadaVagrantfile.rb](static/ArmadaVagrantfile.rb).
It returns Ruby script that provides single function `armada_vagrantfile()`. Running this function from the
`Vagrantfile` script for your armadized service takes care of setting up convenient development environment for it.

Example `Vagrantfile` for service `badguys-finder`:

    require 'open-uri'
    armada_vagrantfile_path = File.join(Dir.tmpdir, 'ArmadaVagrantfile.rb')
    IO.write(armada_vagrantfile_path, open('http://vagrant.armada.sh/ArmadaVagrantfile.rb').read)
    load armada_vagrantfile_path

    armada_vagrantfile(
        :microservice_name => 'badguys-finder',
        :origin_dockyard_address => 'dockyard.initech.com'
    )

Available parameters:

* `:microservice_name`.
    To take advantage of most Armada goodies, your service source code should reside in directory
    `/opt/:microservice_name/` inside the container. If you pass it to `armada_vagrantfile()` function,
    it will map files from your hard drive directly into VirtualBox virtual machine.
    It will also set environment variable `MICROSERVICE_NAME` which in turn will supply this name as default
    to `armada` commands. That way you can just type `armada run`, `armada ssh` etc. without typing service name everytime.

* `:origin_dockyard_address`.
    Address of the dockyard from which your service image will be downloaded.


For more options and list of their advantages, take a look into Armada guides in the section about
microservice's development environment.
