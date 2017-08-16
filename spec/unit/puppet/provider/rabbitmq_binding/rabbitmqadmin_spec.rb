require 'puppet'
require 'mocha/api'
RSpec.configure do |config|
  config.mock_with :mocha
end
provider_class = Puppet::Type.type(:rabbitmq_binding).provider(:rabbitmqadmin)
describe provider_class do

  subject do
    provider = provider_class
    provider.initvars
    provider
  end

  describe "self.instances" do
    it 'should return instances' do
      provider_class.expects(:rabbitmqctl).with('list_vhosts', '-q').returns <<-EOT
/
EOT
      provider_class.expects(:rabbitmqctl).with('list_bindings', '-q', '-p', '/', 'source_name', 'destination_name', 'destination_kind', 'routing_key', 'arguments').returns <<-EOT
exchange\tdst_queue\tqueue\t*\t[]
EOT
      instances = provider_class.instances
      instances.size.should == 1
      instances.map do |prov|
        {
          :source      => prov.get(:source),
          :dest        => prov.get(:dest),
          :vhost       => prov.get(:vhost),
          :routing_key => prov.get(:routing_key)
        }
      end.should == [
        {
          :source      => 'exchange',
          :dest        => 'dst_queue',
          :vhost       => '/',
          :routing_key => '*'
        }
      ]
    end

    it 'should return multiple instances' do
      provider_class.expects(:rabbitmqctl).with('list_vhosts', '-q').returns <<-EOT
/
EOT
      provider_class.expects(:rabbitmqctl).with('list_bindings', '-q', '-p', '/', 'source_name', 'destination_name', 'destination_kind', 'routing_key', 'arguments').returns <<-EOT
exchange\tdst_queue\tqueue\trouting_one\t[]
exchange\tdst_queue\tqueue\trouting_two\t[]
EOT
      instances = provider_class.instances
      instances.size.should == 2
      instances.map do |prov|
        {
          :source      => prov.get(:source),
          :dest        => prov.get(:dest),
          :vhost       => prov.get(:vhost),
          :routing_key => prov.get(:routing_key)
        }
      end.should == [
        {
          :source      => 'exchange',
          :dest        => 'dst_queue',
          :vhost       => '/',
          :routing_key => 'routing_one'
        },
        {
          :source      => 'exchange',
          :dest        => 'dst_queue',
          :vhost       => '/',
          :routing_key => 'routing_two'
        }
      ]
    end
  end

  describe "self.prefetch" do
    it "fetches" do
      provider_class.expects(:rabbitmqctl).with('list_vhosts', '-q').returns <<-EOT
/
EOT
      provider_class.expects(:rabbitmqctl).with('list_bindings', '-q', '-p', '/', 'source_name', 'destination_name', 'destination_kind', 'routing_key', 'arguments').returns <<-EOT
exchange\tdst_queue\tqueue\t*\t[]
EOT

      provider_class.prefetch({})
    end

    context 'with a matching resource' do
      # Test resource to match against
      let(:binding) do
        {
          :name             => 'binding1',
          :source           => 'exchange1',
          :dest             => 'destqueue',
          :destination_type => :queue,
          :routing_key      => 'blablubd',
          :arguments        => {}
        }
      end

      let(:resource) do
        Puppet::Type::Rabbitmq_binding.new(
          # {
            :name             => 'binding1',
            :source           => 'exchange1',
            :dest             => 'destqueue',
            :destination_type => :queue,
            :routing_key      => 'blablubd',
            :arguments        => {}
          # }
        )
      end
      let(:resources) do
        {
          'binding1' => resource
        }
      end

      it "matches" do
    Puppet::Util::Log.level = :debug
    Puppet::Util::Log.newdestination(:console)

        subject.expects(:rabbitmqctl).with('list_vhosts', '-q').returns <<-EOT
/
EOT
        subject.expects(:rabbitmqctl).with('list_bindings', '-q', '-p', '/', 'source_name', 'destination_name', 'destination_kind', 'routing_key', 'arguments').returns <<-EOT
exchange\tdst_queue\tqueue\t*\t[]
EOT

        subject.prefetch(resources)
        subject.expects(:new).with(binding).never
      end
    end
  end
  
  describe 'when creating a resource' do
    before :each do
      @resource = Puppet::Type::Rabbitmq_binding.new(
        {
          :name             => 'source@target@/',
          :destination_type => :queue,
          :routing_key      => 'blablub',
          :arguments        => {}
        }
      )
      @provider = provider_class.new(@resource)
    end

    it 'should call rabbitmqadmin to create' do
      @provider.expects(:rabbitmqadmin).with('declare', 'binding', '--vhost=/', '--user=guest', '--password=guest', '-c', '/etc/rabbitmq/rabbitmqadmin.conf', 'source=source', 'destination=target', 'arguments={}', 'routing_key=blablub', 'destination_type=queue')
      @provider.create
    end
  end

  describe 'when destroying a resource' do
    before :each do
      @resource = Puppet::Type::Rabbitmq_binding.new(
        {
          :name             => 'source@target@/',
          :destination_type => :queue,
          :routing_key      => 'blablub',
          :arguments        => {}
        }
      )
      @provider = provider_class.new(@resource)
    end

    it 'should call rabbitmqadmin to destroy' do
      @provider.expects(:rabbitmqadmin).with('delete', 'binding', '--vhost=/', '--user=guest', '--password=guest', '-c', '/etc/rabbitmq/rabbitmqadmin.conf', 'source=source', 'destination_type=queue', 'destination=target', 'properties_key=blablub')
      @provider.destroy
    end
  end

  context 'specifying credentials' do
    before :each do
      @resource = Puppet::Type::Rabbitmq_binding.new(
        {
          :name             => 'source@test2@/',
          :destination_type => :queue,
          :routing_key      => 'blablubd',
          :arguments        => {},
          :user             => 'colin',
          :password         => 'secret'
        }
      )
      @provider = provider_class.new(@resource)
    end

    it 'should call rabbitmqadmin to create' do
      @provider.expects(:rabbitmqadmin).with('declare', 'binding', '--vhost=/', '--user=colin', '--password=secret', '-c', '/etc/rabbitmq/rabbitmqadmin.conf', 'source=source', 'destination=test2', 'arguments={}', 'routing_key=blablubd', 'destination_type=queue')
      @provider.create
    end
  end

  context 'new queue_bindings' do
    before :each do
      @resource = Puppet::Type::Rabbitmq_binding.new(
        {
          :name             => 'binding1',
          :source           => 'exchange1',
          :dest             => 'destqueue',
          :destination_type => :queue,
          :routing_key      => 'blablubd',
          :arguments        => {}
        }
      )
      @provider = provider_class.new(@resource)
    end

    it 'should call rabbitmqadmin to create' do
      @provider.expects(:rabbitmqadmin).with('declare', 'binding', '--vhost=/', '--user=guest', '--password=guest', '-c', '/etc/rabbitmq/rabbitmqadmin.conf', 'source=exchange1', 'destination=destqueue', 'arguments={}', 'routing_key=blablubd', 'destination_type=queue')
      @provider.create
    end
  end

end
