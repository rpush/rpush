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
    @connection = Rapns::Daemon::Connection.new
    @connection.stub(:connect_socket)
    @connection.stub(:setup_at_exit_hook)
    configuration = mock("Configuration", :host => "localhost", :port => 123, :certificate_password => "abc123")
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
    @connection = Rapns::Daemon::Connection.new
    @connection.stub(:setup_at_exit_hook)
    @ssl_context = mock("SSLContext")
    @connection.stub(:setup_ssl_context).and_return(@ssl_context)
    @tcp_socket = mock("TCPSocket")
    TCPSocket.stub(:new).and_return(@tcp_socket)
    Rapns::Daemon::Configuration.stub(:host).and_return("localhost")
    Rapns::Daemon::Configuration.stub(:port).and_return(123)
    @ssl_socket = mock("SSLSocket", :sync= => nil, :connect => nil)
    OpenSSL::SSL::SSLSocket.stub(:new).and_return(@ssl_socket)
    configuration = mock("Configuration", :host => "localhost", :port => 123)
    Rapns::Daemon.stub(:configuration).and_return(configuration)
  end

  it "should create a TCP socket using the configured host and port" do
    TCPSocket.should_receive(:new).with("localhost", 123).and_return(@tcp_socket)
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
end

describe Rapns::Daemon::Connection, "when shuting down the connection" do
  before do
    @connection = Rapns::Daemon::Connection.new
    @ssl_socket = mock("SSLSocket", :close => nil)
    @connection.instance_variable_set("@ssl_socket", @ssl_socket)
    @tcp_socket = mock("TCPSocket", :close => nil)
    @connection.instance_variable_set("@tcp_socket", @tcp_socket)
  end

  it "should close the TCP socket" do
    @tcp_socket.should_receive(:close)
    @connection.send(:shutdown_socket)
  end

  it "should attempt to close the TCP socket if it does not exist" do
    @tcp_socket.should_not_receive(:close)
    @connection.instance_variable_set("@tcp_socket", nil)
    @connection.send(:shutdown_socket)
  end

  it "should close the SSL socket" do
    @ssl_socket.should_receive(:close)
    @connection.send(:shutdown_socket)
  end

  it "should attempt to close the SSL socket if it does not exist" do
    @ssl_socket.should_not_receive(:close)
    @connection.instance_variable_set("@ssl_socket", nil)
    @connection.send(:shutdown_socket)
  end
end

describe Rapns::Daemon::Connection, "when the connection is lost" do
  before do
    @connection = Rapns::Daemon::Connection.new
    @ssl_socket = mock("SSLSocket")
    @connection.instance_variable_set("@ssl_socket", @ssl_socket)
    @connection.stub(:connect_socket).and_return([mock("TCPSocket"), @ssl_socket])
    @ssl_socket.stub(:write).and_raise(Errno::EPIPE)
    @logger = mock("Logger", :warn => nil)
    Rapns::Daemon.stub(:logger).and_return(@logger)
    @connection.stub(:sleep)
    configuration = mock("Configuration", :host => "localhost", :port => 123)
    Rapns::Daemon.stub(:configuration).and_return(configuration)
  end

  it "should log a warning" do
    Rapns::Daemon.logger.should_receive("warn").with("Lost connection to localhost:123, reconnecting...")
    begin
      @connection.write(nil)
    rescue Rapns::Daemon::Connection::ConnectionError
    end
  end

  it "should retry to make a connection 3 times" do
    @connection.should_receive(:connect_socket).exactly(3).times
    begin
      @connection.write(nil)
    rescue Rapns::Daemon::Connection::ConnectionError
    end
  end

  it "should raise a ConnectionError after 3 attempts at reconnecting" do
    expect do
      @connection.write(nil)
    end.to raise_error(Rapns::Daemon::Connection::ConnectionError, "Tried 3 times to reconnect but failed: #<Errno::EPIPE: Broken pipe>")
  end

  it "should sleep 1 second before retrying the connection" do
    @connection.should_receive(:sleep).with(1)
    begin
      @connection.write(nil)
    rescue Rapns::Daemon::Connection::ConnectionError
    end
  end
end