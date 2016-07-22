require 'spec_helper'

describe 'users' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "users class without any parameters" do
          it { is_expected.to compile.with_all_deps }

          it { is_expected.to contain_class('users::params') }
          it { is_expected.to contain_class('users::install').that_comes_before('users::config') }
          it { is_expected.to contain_class('users::config') }
          it { is_expected.to contain_class('users::service').that_subscribes_to('users::config') }

          it { is_expected.to contain_service('users') }
          it { is_expected.to contain_package('users').with_ensure('present') }
        end
      end
    end
  end

  context 'unsupported operating system' do
    describe 'users class without any parameters on Solaris/Nexenta' do
      let(:facts) do
        {
          :osfamily        => 'Solaris',
          :operatingsystem => 'Nexenta',
        }
      end

      it { expect { is_expected.to contain_package('users') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end
end
