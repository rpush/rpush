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
    @connection = Rapns::Daemon::Connection.new("Connection 1", Queue.new)
    @connection.stub(:connect_socket)
    @connection.stub(:setup_at_exit_hook)
    configuration = mock("Configuration", :host => "localhost", :port => 123, :certificate_password => "abc123")
    Rapns::Daemon.stub(:configuration).and_return(configuration)
  end

  after do
    @connection.close
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
    @connection = Rapns::Daemon::Connection.new("Connection 1", Queue.new)
    @connection.stub(:setup_at_exit_hook)
    @ssl_context = mock("SSLContext")
    @connection.stub(:setup_ssl_context).and_return(@ssl_context)
    @tcp_socket = mock("TCPSocket", :close => nil)
    TCPSocket.stub(:new).and_return(@tcp_socket)
    Rapns::Daemon::Configuration.stub(:host).and_return("localhost")
    Rapns::Daemon::Configuration.stub(:port).and_return(123)
    @ssl_socket = mock("SSLSocket", :sync= => nil, :connect => nil, :close => nil)
    OpenSSL::SSL::SSLSocket.stub(:new).and_return(@ssl_socket)
    configuration = mock("Configuration", :host => "localhost", :port => 123)
    Rapns::Daemon.stub(:configuration).and_return(configuration)
    @logger = mock("Logger", :info => nil)
    Rapns::Daemon.stub(:logger).and_return(@logger)
  end

  after do
    @connection.close
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
    @connection = Rapns::Daemon::Connection.new("Connection 1", Queue.new)
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
end

describe Rapns::Daemon::Connection, "when the connection is lost" do
  before do
    @connection = Rapns::Daemon::Connection.new("Connection 1", mock("Queue", :pop => Rapns::Daemon::Connection::CLOSE_CMD))
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
    Rapns::Daemon.logger.should_receive("warn").with("[Connection 1] Lost connection to localhost:123, reconnecting...")
    begin
      @connection.send(:write, nil)
    rescue Rapns::Daemon::Connection::ConnectionError
    end
  end

  it "should retry to make a connection 3 times" do
    @connection.should_receive(:connect_socket).exactly(3).times
    begin
      @connection.send(:write, nil)
    rescue Rapns::Daemon::Connection::ConnectionError
    end
  end

  it "should raise a ConnectionError after 3 attempts at reconnecting" do
    expect do
      @connection.send(:write, nil)
    end.to raise_error(Rapns::Daemon::Connection::ConnectionError, "Connection 1 tried 3 times to reconnect but failed: #<Errno::EPIPE: Broken pipe>")
  end

  it "should sleep 1 second before retrying the connection" do
    @connection.should_receive(:sleep).with(1)
    begin
      @connection.send(:write, nil)
    rescue Rapns::Daemon::Connection::ConnectionError
    end
  end
end

describe Rapns::Daemon::Connection, "when sending a notification" do
  before do
    @queue = Queue.new
    @connection = Rapns::Daemon::Connection.new("Connection 1", @queue)
    @ssl_socket = mock("SSLSocket", :write => nil, :flush => nil, :close => nil)
    @tcp_socket = mock("TCPSocket", :close => nil)
    @connection.stub(:setup_ssl_context)
    @connection.stub(:connect_socket).and_return([@tcp_socket, @ssl_socket])
    @connection.stub(:check_for_error)
    @connection.connect
  end

  after do
    @connection.close
  end

  it "should write the data to the SSL socket" do
    @ssl_socket.should_receive(:write).with("blah")
    @queue.push("blah")
  end

  it "should flush the SSL socket" do
    @ssl_socket.should_receive(:flush)
    @queue.push("blah")
  end

  it "should select check for an error packet" do
    @connection.should_receive(:check_for_error)
    @queue.push("blah")
  end
end

describe Rapns::Daemon::Connection, "when receiving an error packet" do
  before do
    @queue = Queue.new
    @notification = Rapns::Notification.create!(:device_token => "a" * 64)
    @notification.stub(:save!)
    @connection = Rapns::Daemon::Connection.new("Connection 1", @queue)
    @ssl_socket = mock("SSLSocket", :write => nil, :flush => nil, :close => nil, :read => [8, 4, @notification.id].pack("ccN"))
    @connection.stub(:setup_ssl_context)
    @connection.stub(:connect_socket).and_return([@tcp_socket, @ssl_socket])
    IO.stub(:select).and_return([@ssl_socket, [], []])
    logger = mock("Logger", :error => nil)
    Rapns::Daemon.stub(:logger).and_return(logger)
    @connection.connect
  end

  after do
    @connection.close
  end

  it "should log that an error has been received" do
    Rapns::Daemon.logger.should_receive(:error).with(Rapns::DeliveryError.new("Received APN error 4 (Missing payload) for notification #{@notification.id}"))
    @queue.push("msg with an error")
  end

  it "should not attempt to handle the error if the packet cmd value is not 8" do
    @connection.should_not_receive(:handle_error)
    @ssl_socket.stub(:read).and_return([6, 4, 12].pack("ccN"))
    @queue.push("msg with an error")
  end

  it "should not attempt to handle the error if the status code is 0 (no error)" do
    @connection.should_not_receive(:handle_error)
    @ssl_socket.stub(:read).and_return([8, 0, 12].pack("ccN"))
    @queue.push("msg with an error")
  end

  it "should read 6 bytes from the socket" do
    @ssl_socket.should_receive(:read).with(6).and_return(nil)
    @queue.push("msg with an error")
  end

  it "should not attempt to read from the socket if the socket was not selected for reading after the timeout" do
    IO.stub(:select).and_return(nil)
    @ssl_socket.should_not_receive(:read)
    @queue.push("msg with an error")
  end

  it "should not attempt to handle the error if the socket read returns nothing" do
    @ssl_socket.stub(:read).with(6).and_return(nil)
    @connection.should_not_receive(:handle_error)
    @queue.push("msg with an error")
  end

  it "should set the notification as not delivered" do
    Rapns::Notification.stub(:find_by_id).and_return(@notification)
    @notification.should_receive(:delivered=).with(false)
    @queue.push("msg with an error")
  end

  it "should set the notification delivered_at timestamp to nil" do
    Rapns::Notification.stub(:find_by_id).and_return(@notification)
    @notification.should_receive(:delivered_at=).with(nil)
    @queue.push("msg with an error")
  end

  it "should set the notification as failed" do
    Rapns::Notification.stub(:find_by_id).and_return(@notification)
    @notification.should_receive(:failed=).with(true)
    @queue.push("msg with an error")
  end

  it "should set the notification failed_at timestamp" do
    now = Time.now
    Time.stub(:now).and_return(now)
    Rapns::Notification.stub(:find_by_id).and_return(@notification)
    @notification.should_receive(:failed_at=).with(now)
    @queue.push("msg with an error")
  end

  it "should set the notification error code" do
    Rapns::Notification.stub(:find_by_id).and_return(@notification)
    @notification.should_receive(:error_code=).with(4)
    @queue.push("msg with an error")
  end

  it "should set the notification error description" do
    Rapns::Notification.stub(:find_by_id).and_return(@notification)
    @notification.should_receive(:error_description=).with("Missing payload")
    @queue.push("msg with an error")
  end

  it "should skip validation when saving the notification" do
    Rapns::Notification.stub(:find_by_id).and_return(@notification)
    @notification.should_receive(:save!).with(:validate => false)
    @queue.push("msg with an error")
  end

  it "should log if an error is raised when updating the notification" do
    Rapns::Notification.stub(:find_by_id).and_return(@notification)
    e = StandardError.new("bork!")
    @notification.stub(:save!).and_raise(e)
    Rapns::Daemon.logger.should_receive(:error).with(e)
    @queue.push("msg with an error")
  end

  it "should not raise an error if the given notification ID from the error does not exist" do
    @ssl_socket.stub(:read).and_return([8, 4, @notification.id + 2].pack("ccN"))
    @queue.push("msg with an error")
  end

  it "should close the socket after handling the error" do
    @connection.should_receive(:close_socket).twice
    @queue.push("msg with an error")
  end

  it "should reconnect the socket" do
    @connection.should_receive(:connect_socket)
    @queue.push("msg with an error")
  end
end
