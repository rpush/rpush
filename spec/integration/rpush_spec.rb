describe "Rpush" do

    before :all do
        `vagrant up`
        # TODO: Upload current directory.
        # TODO: Use Net::SSH
        `vagrant ssh 'cd rpush; git fetch origin; git reset --hard origin/master; sh tools/run_docker.sh'`
    end

    it 'can be installed and successfully delivers a notification' do
        # Can now SSH to the Docker instance with; ssh -i docker_key root@localhost -p 2100
    end
end
