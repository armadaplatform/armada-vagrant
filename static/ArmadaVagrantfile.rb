
def armada_vagrantfile(args={})
    microservice_name = args[:microservice_name]
    armada_run_args = args[:armada_run_args]
    origin_dockyard_address = args[:origin_dockyard_address]
    configs_dir = args[:configs_dir]
    secret_configs_repository = args[:secret_configs_repository]

    vagrantfile_api_version = "2"
    Vagrant.require_version ">= 2.0.0"
    Vagrant.configure(vagrantfile_api_version) do |config|

        config.vm.box = "armada"
        config.vm.box_url = ENV.fetch("ARMADA_BOX_URL", "http://vagrant-box.armada.sh/armada.json")

        # Fix for slow (~5s) DNS resolving.
        config.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
            vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
        end

        # Port forwarding.
        config.vm.network "public_network", :adapter => 2, :use_dhcp_assigned_default_route => true

        # Mapping directories.
        config.vm.synced_folder "..", "/projects"

        config.vm.provision "shell", inline: <<SCRIPT
            sudo service armada restart
            sudo chmod 777 /etc/opt
SCRIPT
        if origin_dockyard_address then
            config.vm.provision "shell", inline: <<SCRIPT
                dockyard_address=#{origin_dockyard_address}
                proto="$(echo $dockyard_address | grep :// | sed -e's,^\(.*://\).*,\1,g')"
                if [[ -z $proto ]] ; then
                   url="$dockyard_address"
                else
                   # remove the protocol
                   url=$(echo $dockyard_address | sed -e s,$proto,,g)
                fi

                armada dockyard set origin $url

SCRIPT
        end

        if microservice_name then
            if configs_dir then
                config.vm.provision "shell", inline: <<SCRIPT
                    if [ -h /etc/opt/#{microservice_name}-config ]; then
                        rm -f /etc/opt/#{microservice_name}-config
                    elif [ -e /etc/opt/#{microservice_name}-config ]; then
                        echo "WARNING: /etc/opt/#{microservice_name}-config exists but it is not a symbolic link."
                    fi
                    ln -s /opt/#{microservice_name}/#{configs_dir} /etc/opt/#{microservice_name}-config
SCRIPT
            end

            if secret_configs_repository then
                if not Dir.exists?('config-secret') then
                    `git clone #{secret_configs_repository} config-secret`
                end
                config.vm.provision "shell", inline: <<SCRIPT
                    if [ -h /etc/opt/#{microservice_name}-config-secret ]; then
                        rm -f /etc/opt/#{microservice_name}-config-secret
                    elif [ -e /etc/opt/#{microservice_name}-config-secret ]; then
                        echo "WARNING: /etc/opt/#{microservice_name}-config-secret exists but it is not a symbolic link."
                    fi
                    ln -s /opt/#{microservice_name}/config-secret /etc/opt/#{microservice_name}-config-secret
SCRIPT
            end

            config.vm.synced_folder "./", "/opt/#{microservice_name}"

            config.vm.provision "shell", inline: <<SCRIPT
                sudo -u vagrant echo export MICROSERVICE_NAME='#{microservice_name}' >> /home/vagrant/.bashrc
                sudo -u vagrant echo export VAGRANT_MICROSERVICE_NAME='#{microservice_name}' >> /home/vagrant/.bashrc
                sudo -u vagrant echo cd /opt/#{microservice_name} >> /home/vagrant/.bashrc
                sudo -u vagrant echo armada develop -v /opt/#{microservice_name} #{microservice_name} >> /home/vagrant/.bashrc
                export MICROSERVICE_NAME='#{microservice_name}'
                export VAGRANT_MICROSERVICE_NAME='#{microservice_name}'
                armada run #{armada_run_args} | cat
SCRIPT
        end
    end
end
