require 'socket'
require 'singleton'

module Rpush
  module Daemon
    module Rpc
      class Server
        include Singleton
        include Loggable
        include Reflectable

        def self.start
          instance.start
        end

        def self.stop
          instance.stop
        end

        def start
          @server = UNIXServer.open(Rpc.socket_path)

          @thread = Thread.new do
            begin
              loop do
                read_loop(@server.accept)
              end
            rescue SystemCallError, IOError # rubocop:disable Lint/HandleExceptions
            ensure
              File.unlink(Rpc.socket_path) if File.exist?(Rpc.socket_path)
            end
          end
        end

        def stop
          @server.close if @server
          @thread.join if @thread
        rescue StandardError => e
          log_debug(e)
        end

        private

        def read_loop(socket)
          loop do
            line = socket.gets
            break unless line

            begin
              cmd, args = JSON.load(line)
              log_debug("[rpc:server] #{cmd.to_sym.inspect}, args: #{args.inspect}")
              response = process(cmd, args)
              socket.puts(JSON.dump(response))
            rescue StandardError => e
              log_error(e)
              reflect(:error, e)
            end
          end

          socket.close
        end

        def process(cmd, args) # rubocop:disable Lint/UnusedMethodArgument
          case cmd
          when 'status'
            status
          end
        end

        def status
          Rpush::Daemon::AppRunner.status
        end
      end
    end
  end
end
