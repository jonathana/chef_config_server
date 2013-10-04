# set path to app that will be used to configure unicorn,
# Note that THERE IS NO TRAILING SLASH.  You must supply one if you use this
@dir = File.expand_path '..', __FILE__

worker_processes 2
working_directory @dir

timeout 60

# Specify user/group for workers to run as
# THIS SHOULD BE A NON-PRIVILEGED USER UNLESS YOU WANT TO RUN ON A PORT < 1024!!!
# The master should be run privileged as it needs to access the Chef client.pem file
# so it has to have superuser read privileges (but nothing else)
user 'nobody', 'nogroup'

# Specify path to socket unicorn listens to,
# DO NOT RUN THIS ON ANYTHING OTHER THAN LOCALHOST or other 127.0.0.x address!!!
# The whole point of this is to have the thing not shipping values over a non-loopback interface
# unencrypted.  Running this on an actual network, even if it isn't attached to the internet,
# defeats the purpose.
listen "127.0.0.1:2663", :backlog => 64

# Set process id path
pid "#{@dir}/tmp/pids/unicorn.pid"

# Set log file paths
stderr_path "#{@dir}/log/unicorn.stderr.log"
stdout_path "#{@dir}/log/unicorn.stdout.log"

