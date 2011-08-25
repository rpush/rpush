require "spec_helper"

describe Rapns::Daemon::Connection, "when setting up the SSL context" do
  before do
    @ssl_context = mock("SSLContext", :key= => nil, :cert= => nil)
    OpenSSL::SSL::SSLContext.should_receive(:new).and_return(@ssl_context)
    @rsa_key = mock("RSA public key")
    OpenSSL::PKey::RSA.stub(:new).and_return(@rsa_key)
    @certificate = mock("Certificate")
    Rapns::Daemon::Certificate.stub(:certificate).and_return(@certificate)
    @x509_certificate = mock("X509 Certificate")
    OpenSSL::X509::Certificate.stub(:new).and_return(@x509_certificate)
    Rapns::Daemon::Connection.stub(:connect_socket)
    Rapns::Daemon::Connection.stub(:setup_at_exit_hook)
  end

  it "should set the key on the context" do
    OpenSSL::PKey::RSA.should_receive(:new).with(@certificate, '').and_return(@rsa_key)
    @ssl_context.should_receive(:key=).with(@rsa_key)
    Rapns::Daemon::Connection.connect
  end

  it "should set the cert on the context" do
    OpenSSL::X509::Certificate.should_receive(:new).with(@certificate).and_return(@x509_certificate)
    @ssl_context.should_receive(:cert=).with(@x509_certificate)
    Rapns::Daemon::Connection.connect
  end
end

describe Rapns::Daemon::Connection, "when connecting the socket" do
  before do
    @ssl_context = mock("SSLContext")
    Rapns::Daemon::Connection.stub(:setup_ssl_context).and_return(@ssl_context)
    @tcp_socket = mock("TCPSocket")
    TCPSocket.stub(:new).and_return(@tcp_socket)
    Rapns::Daemon::Configuration.stub(:host).and_return("localhost")
    Rapns::Daemon::Configuration.stub(:port).and_return(123)
    @ssl_socket = mock("SSLSocket", :sync= => nil, :connect => nil)
    OpenSSL::SSL::SSLSocket.stub(:new).and_return(@ssl_socket)
    Rapns::Daemon::Connection.stub(:setup_at_exit_hook)
  end

  it "should create a TCP socket using the configured host and port" do
    TCPSocket.should_receive(:new).with("localhost", 123).and_return(@tcp_socket)
    Rapns::Daemon::Connection.connect
  end

  it "should create a new SSL socket using the TCP socket and SSL context" do
    OpenSSL::SSL::SSLSocket.should_receive(:new).with(@tcp_socket, @ssl_context).and_return(@ssl_socket)
    Rapns::Daemon::Connection.connect
  end

  it "should set the sync option on the SSL socket" do
    @ssl_socket.should_receive(:sync=).with(true)
    Rapns::Daemon::Connection.connect
  end

  it "should connect the SSL socket" do
    @ssl_socket.should_receive(:connect)
    Rapns::Daemon::Connection.connect
  end
end

describe Rapns::Daemon::Connection, "when shuting down the connection" do
  before do
    @ssl_socket = mock("SSLSocket", :close => nil)
    Rapns::Daemon::Connection.instance_variable_set("@ssl_socket", @ssl_socket)
    @tcp_socket = mock("TCPSocket", :close => nil)
    Rapns::Daemon::Connection.instance_variable_set("@tcp_socket", @tcp_socket)
  end

  it "should close the TCP socket" do
    @tcp_socket.should_receive(:close)
    Rapns::Daemon::Connection.shutdown_socket
  end

  it "should attempt to close the TCP socket if it does not exist" do
    @tcp_socket.should_not_receive(:close)
    Rapns::Daemon::Connection.instance_variable_set("@tcp_socket", nil)
    Rapns::Daemon::Connection.shutdown_socket
  end

  it "should close the SSL socket" do
    @ssl_socket.should_receive(:close)
    Rapns::Daemon::Connection.shutdown_socket
  end

  it "should attempt to close the SSL socket if it does not exist" do
    @ssl_socket.should_not_receive(:close)
    Rapns::Daemon::Connection.instance_variable_set("@ssl_socket", nil)
    Rapns::Daemon::Connection.shutdown_socket
  end
end