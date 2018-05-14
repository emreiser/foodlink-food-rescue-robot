worker_processes 3
timeout 120

# Enable streaming (for CSV downloads)
port = (ENV["PORT"] || 3000).to_i
listen port, :tcp_nopush => false