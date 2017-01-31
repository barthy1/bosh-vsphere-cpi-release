require 'integration/spec_helper'

describe 'cloud_properties related to clusters' do
  before (:all) do
    @datacenter_name = fetch_and_verify_datacenter('BOSH_VSPHERE_CPI_DATACENTER')
    @cluster_name = fetch_and_verify_cluster('BOSH_VSPHERE_CPI_CLUSTER')
    @cluster_name_2 = fetch_and_verify_cluster('BOSH_VSPHERE_CPI_SECOND_CLUSTER')
  end

  let(:network_spec) do
    {
      'static' => {
        'ip' => "169.254.#{rand(1..254)}.#{rand(4..254)}",
        'netmask' => '255.255.254.0',
        'cloud_properties' => { 'name' => @vlan },
        'default' => ['dns', 'gateway'],
        'dns' => ['169.254.1.2'],
        'gateway' => '169.254.1.3'
      }
    }
  end

  context 'when vm_type specifies a cluster not defined in global config' do
    let(:vm_type) do
      {
        'ram' => 512,
        'disk' => 2048,
        'cpu' => 1,
        'datacenters' => [
          {
            'name' => @datacenter_name,
            'clusters' => [
              {
                @cluster_name => {}
              }
            ]
          }
        ]
      }
    end
    let(:options) do
      options = cpi_options(
        'datacenters' => [
          {
            'name' => @datacenter_name,
            'clusters' => [
              {
                @cluster_name_2 => {}
              },
            ]
          }
        ]
      )
    end

    it 'creates vm in cluster defined in `vm_type`' do
      cpi = VSphereCloud::Cloud.new(options)
      begin
        vm_id = cpi.create_vm(
          'agent-007',
          @stemcell_id,
          vm_type,
          network_spec,
          [],
          {}
        )
        expect(vm_id).to_not be_nil

        vm = cpi.vm_provider.find(vm_id)
        expect(vm).to_not be_nil

        expect(vm.cluster).to eq(@cluster_name)
      ensure
        delete_vm(cpi, vm_id)
      end
    end
  end
end
