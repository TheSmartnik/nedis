require 'socket'

module Nedis
  class Server
    attr_reader :port

    def initialize(port)
      @port = port
    end

    def listen
      readable = []
      clients = {}
      server = TCPServer.new(port)
      readable << server

      loop do
        read_to_read, _ = IO.select(readable + clients.keys)

        read_to_read.each do |socket|
          case socket
          when server
            child_socket = socket.accept
            clients[child_socket] = Handler.new(child_socket)
          else
            clients[socket].proccess!
          end
        end
      end
    ensure
      readable.each(&:close)
    end
  end

  class Handler
    attr_reader :client

    def initialize(socket)
      @client = socket
      @buffer = ""
    end

    def proccess!
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
  end
end
