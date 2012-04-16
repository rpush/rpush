require "spec_helper"

describe Rapns::Daemon::Connection, "when setting up the SSL context" do
  before do
    @ssl_context = mock("SSLContext", :key= => nil, :cert= => nil)
    OpenSSL::SSL::SSLContext.should_receive(:new).and_return(@ssl_context)
    @rsa_key = mock("RSA public key")
    OpenSSL::PKey::RSA.stub(:new).and_return(@rsa_key)
    @certificate = mock("Certificate", :certificate => "certificate contents")
    Rapns::Daemon.stub(:certificate).and_return(@certificate)
    @x509_certificate = mock("X509 Certificate")
    OpenSSL::X509::Certificate.stub(:new).and_return(@x509_certificate)
    @connection = Rapns::Daemon::Connection.new('Connection 0', 'gateway.push.apple.com', 2195)
    @connection.stub(:connect_socket)
    @connection.stub(:setup_at_exit_hook)
    configuration = mock("Configuration", :certificate_password => "abc123")
    Rapns::Daemon.stub(:configuration).and_return(configuration)
  end

  it "should set the key on the context" do
    OpenSSL::PKey::RSA.should_receive(:new).with("certificate contents", "abc123").and_return(@rsa_key)
    @ssl_context.should_receive(:key=).with(@rsa_key)
    @connection.connect
  end

  it "should set the cert on the context" do
    OpenSSL::X509::Certificate.should_receive(:new).with("certificate contents").and_return(@x509_certificate)
    @ssl_context.should_receive(:cert=).with(@x509_certificate)
    @connection.connect
  end
end

describe Rapns::Daemon::Connection, "when connecting the socket" do
  before do
    @connection = Rapns::Daemon::Connection.new('Connection 0', 'gateway.push.apple.com', 2195)
    @connection.stub(:setup_at_exit_hook)
    @ssl_context = mock("SSLContext")
    @connection.stub(:setup_ssl_context).and_return(@ssl_context)
    @tcp_socket = mock("TCPSocket", :close => nil, :setsockopt => nil)
    TCPSocket.stub(:new).and_return(@tcp_socket)
    @ssl_socket = mock("SSLSocket", :sync= => nil, :connect => nil, :close => nil)
    OpenSSL::SSL::SSLSocket.stub(:new).and_return(@ssl_socket)
    @logger = mock("Logger", :info => nil)
    Rapns::Daemon.stub(:logger).and_return(@logger)
  end

  it "should create a TCP socket using the configured host and port" do
    TCPSocket.should_receive(:new).with('gateway.push.apple.com', 2195).and_return(@tcp_socket)
    @connection.connect
  end

  it "should create a new SSL socket using the TCP socket and SSL context" do
    OpenSSL::SSL::SSLSocket.should_receive(:new).with(@tcp_socket, @ssl_context).and_return(@ssl_socket)
    @connection.connect
  end

  it "should set the sync option on the SSL socket" do
    @ssl_socket.should_receive(:sync=).with(true)
    @connection.connect
  end

  it "should connect the SSL socket" do
    @ssl_socket.should_receive(:connect)
    @connection.connect
  end

  it "should set the socket option TCP_NODELAY" do
    @tcp_socket.should_receive(:setsockopt).with(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
    @connection.connect
  end

  it "should set the socket option SO_KEEPALIVE" do
    @tcp_socket.should_receive(:setsockopt).with(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
    @connection.connect
  end
end

describe Rapns::Daemon::Connection, "when shuting down the connection" do
  before do
    @connection = Rapns::Daemon::Connection.new('Connection 0', 'gateway.push.apple.com', 2195)
    @connection.stub(:setup_ssl_context)
    @ssl_socket = mock("SSLSocket", :close => nil)
    @tcp_socket = mock("TCPSocket", :close => nil)
    @connection.stub(:connect_socket).and_return([@tcp_socket, @ssl_socket])
  end

  it "should close the TCP socket" do
    @connection.connect
    @tcp_socket.should_receive(:close)
    @connection.close
  end

  it "should attempt to close the TCP socket if it does not exist" do
    @connection.connect
    @tcp_socket.should_not_receive(:close)
    @connection.instance_variable_set("@tcp_socket", nil)
    @connection.close
  end

  it "should close the SSL socket" do
    @connection.connect
    @ssl_socket.should_receive(:close)
    @connection.close
  end

  it "should attempt to close the SSL socket if it does not exist" do
    @connection.connect
    @ssl_socket.should_not_receive(:close)
    @connection.instance_variable_set("@ssl_socket", nil)
    @connection.close
  end

  it "should ignore IOError when the socket is already closed" do
    @tcp_socket.stub(:close).and_raise(IOError)
    @connection.connect
    expect {@connection.close }.should_not raise_error(IOError)
  end
end

describe Rapns::Daemon::Connection, "read" do
  before do
    @connection = Rapns::Daemon::Connection.new('Connection 0', 'gateway.push.apple.com', 2195)
    @connection.stub(:setup_ssl_context)
    @ssl_socket = mock("SSLSocket", :close => nil)
    @tcp_socket = mock("TCPSocket", :close => nil)
    @connection.stub(:connect_socket).and_return([@tcp_socket, @ssl_socket])
  end

  it "reads the number of bytes from the SSL socket" do
    @ssl_socket.should_receive(:read).with(123)
    @connection.connect
    @connection.read(123)
  end
end

describe Rapns::Daemon::Connection, "select" do
  before do
    @connection = Rapns::Daemon::Connection.new('Connection 0', 'gateway.push.apple.com', 2195)
    @connection.stub(:setup_ssl_context)
    @ssl_socket = mock("SSLSocket", :close => nil)
    @tcp_socket = mock("TCPSocket", :close => nil)
    @connection.stub(:connect_socket).and_return([@tcp_socket, @ssl_socket])
  end

  it "selects on the SSL socket until the given timeout" do
    IO.should_receive(:select).with([@ssl_socket], nil, nil, 10)
    @connection.connect
    @connection.select(10)
  end
end

shared_examples_for "when the write fails" do
  before do
    @connection = Rapns::Daemon::Connection.new('Connection 0', 'gateway.push.apple.com', 2195)
    @logger = mock("Logger", :error => nil)
    Rapns::Daemon.stub(:logger).and_return(@logger)
    @connection.stub(:reconnect)
    @connection.stub(:write_data).and_raise(error_type)
    @connection.stub(:sleep)
  end

  it "should log that the connection has been lost once only" do
    Rapns::Daemon.logger.should_receive(:error).with("[Connection 0] Lost connection to gateway.push.apple.com:2195 (#{error_type.name}), reconnecting...").once
    begin
      @connection.write(nil)
    rescue Rapns::Daemon::ConnectionError
    end
  end

  it "should retry to make a connection 3 times" do
    @connection.should_receive(:reconnect).exactly(3).times
    begin
      @connection.write(nil)
    rescue Rapns::Daemon::ConnectionError
    end
  end

  it "should raise a ConnectionError after 3 attempts at reconnecting" do
    expect do
      @connection.write(nil)
    end.to raise_error(Rapns::Daemon::ConnectionError, "Connection 0 tried 3 times to reconnect but failed (#{error_type.name}).")
  end

  it "should sleep 1 second before retrying the connection" do
    @connection.should_receive(:sleep).with(1)
    begin
      @connection.write(nil)
    rescue Rapns::Daemon::ConnectionError
    end
  end
end

describe Rapns::Daemon::Connection, "when write raises an Errno::EPIPE" do
  it_should_behave_like "when the write fails"

  def error_type
    Errno::EPIPE
  end
end

describe Rapns::Daemon::Connection, "when write raises an Errno::ETIMEDOUT" do
  it_should_behave_like "when the write fails"

  def error_type
    Errno::ETIMEDOUT
  end
end

describe Rapns::Daemon::Connection, "when write raises an OpenSSL::SSL::SSLError" do
  it_should_behave_like "when the write fails"

  def error_type
    OpenSSL::SSL::SSLError
  end
end

describe Rapns::Daemon::Connection, "when reconnecting" do
  before do
    @connection = Rapns::Daemon::Connection.new('Connection 0', 'gateway.push.apple.com', 2195)
    @connection.stub(:close)
    @connection.stub(:connect_socket)
  end

  it 'closes the socket' do
    @connection.should_receive(:close)
    @connection.send(:reconnect)
  end

  it 'connects the socket' do
    @connection.should_receive(:connect_socket)
    @connection.send(:reconnect)
  end
end

describe Rapns::Daemon::Connection, "when sending a notification" do
  before do
    @connection = Rapns::Daemon::Connection.new('Connection 0', 'gateway.push.apple.com', 2195)
    @ssl_socket = mock("SSLSocket", :write => nil, :flush => nil, :close => nil)
    @tcp_socket = mock("TCPSocket", :close => nil)
    @connection.stub(:setup_ssl_context)
    @connection.stub(:connect_socket).and_return([@tcp_socket, @ssl_socket])
    @connection.connect
  end

  it "should write the data to the SSL socket" do
    @ssl_socket.should_receive(:write).with("blah")
    @connection.write("blah")
  end

  it "should flush the SSL socket" do
    @ssl_socket.should_receive(:flush)
    @connection.write("blah")
  end
end

describe Rapns::Daemon::Connection, 'idle period' do
  before do
    @connection = Rapns::Daemon::Connection.new('Connection 0', 'gateway.push.apple.com', 2195)
    @ssl_socket = mock("SSLSocket", :write => nil, :flush => nil, :close => nil)
    @tcp_socket = mock("TCPSocket", :close => nil)
    @connection.stub(:setup_ssl_context)
    @connection.stub(:connect_socket => [@tcp_socket, @ssl_socket])
    @logger = mock("Logger", :info => nil)
    Rapns::Daemon.stub(:logger).and_return(@logger)
    @connection.connect
  end

  it 'reconnects if the connection has been idle for more than the defined period' do
    Rapns::Daemon::Connection.stub(:idle_period => 0.1)
    sleep 0.2
    @connection.should_receive(:reconnect)
    @connection.write('blah')
  end

  it 'resets the last write time' do
    now = Time.now
    Time.stub(:now => now)
    @connection.write('blah')
    @connection.last_write.should == now
  end

  it 'does not reconnect if the connection has not been idle for more than the defined period' do
    @connection.should_not_receive(:reconnect)
    @connection.write('blah')
  end

  it 'logs the the connection is idle' do
    Rapns::Daemon::Connection.stub(:idle_period => 0.1)
    sleep 0.2
    Rapns::Daemon.logger.should_receive(:info).with('[Connection 0] Idle period exceeded, reconnecting...')
    @connection.write('blah')
  end
end