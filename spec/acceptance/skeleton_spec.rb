require 'timeout'
require 'redis'

TEST_PORT = 6380

describe 'Nedis', :acceptance do
 it 'responds to ping' do
   with_server do
     expect(client.ping).to eq("OK")
   end
 end

 def client
   Redis.new(host: '127.0.0.1', port: TEST_PORT)
 end

  def with_server
     Thread.report_on_exception = true

     server_thread = Thread.new do
       server = Nedis::Server.new(TEST_PORT)
       server.listen
     end

     wait_for_open_port TEST_PORT
     
     yield  
  rescue TimeoutError
    sleep 0.01
    server_thread.value unless server_thread.alive?
    raise
  ensure 
    Thread.kill(server_thread) if server_thread
  end

  def wait_for_open_port(port)
    time = Time.now
   
    while !check_port(port) && 1 > Time.now - time
      sleep(0.01)
    end

    raise TimeoutError unless check_port(port)
  end

  def check_port(port)
    `nc -z localhost #{port}`
     $?.success?
  end 
end