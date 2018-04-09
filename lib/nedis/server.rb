require 'socket'

module Nedis
  class Server
    attr_reader :port

    def initialize(port)
      @port = port
    end

    def listen
      socket = TCPServer.new(port)
      loop do
        Thread.start(socket.accept) do |client|
          handle_client client
        end
      end
    ensure
      socket.close if socket
    end

    def handle_client(client)
      loop do
        header = client.gets.to_s

        return unless header[0] == '*'

        arguments_count = header[1..-1].to_i

        cmd = arguments_count.times.map do
          len = client.gets[1..-1].to_i
          carriage_return_length = 2
          client.read(len + carriage_return_length).chomp
        end

        command, *cmd_arguments = cmd

        response = case command.downcase
        when 'ping' then"+PONG\r\n"
        when 'echo' then "$#{cmd_arguments[0].length}\r\n#{cmd_arguments[0]}\r\n"
        end

        client.write response
      end
    ensure
      client.close
    end
  end
end
