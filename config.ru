# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

run Rails.application
Rails.application.load_server
if File.exist?('tmp/pids/server.pid')
  File.delete('tmp/pids/server.pid')
end
