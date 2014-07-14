require 'functional_spec_helper'

describe 'Synchronization' do
  let(:timeout) { 10 }
  let(:app) { Rpush::Gcm::App.new }

  def wait_for_num_dispatchers(num)
    Timeout.timeout(timeout) do
      until Rpush::Daemon::AppRunner.num_dispatchers_for_app(app) == num
        sleep 0.1
      end
    end
  end

  before do
    app.name = 'test'
    app.auth_key = 'abc123'
    app.connections = 2
    app.save!

    Rpush.embed
    wait_for_num_dispatchers(app.connections)
  end

  after { Timeout.timeout(timeout) { Rpush.shutdown } }

  it 'increments the number of dispatchers' do
    app.connections += 1
    app.save!
    Rpush.sync
    wait_for_num_dispatchers(app.connections)
  end

  it 'decrements the number of dispatchers' do
    app.connections -= 1
    app.save!
    Rpush.sync
    wait_for_num_dispatchers(app.connections)
  end

  it 'stops a deleted app' do
    app.destroy
    Rpush.sync
    Rpush::Daemon::AppRunner.app_running?(app).should be_false
  end
end
