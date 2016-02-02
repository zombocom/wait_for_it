require "wait_for_it/version"

require 'pathname'
require 'shellwords'
require 'tempfile'
require 'timeout'

class WaitForIt
  class WaitForItTimeoutError < StandardError
    def initialize(options = {})
      command = options[:command]
      input   = options[:input]
      timeout = options[:timeout]
      log     = options[:log]
      super "Running command: '#{ command }', waiting for '#{ input }' did not occur within #{ timeout } seconds:\n#{ log.read }"
    end
  end

  DEFAULT_TIMEOUT = 10 # seconds
  DEFAULT_OUT     = ">>"
  DEFAULT_ENV     = {}

  # Configure global WaitForIt settings
  def self.config
    yield self
    self
  end

  # The default output is expected in the logs before the process is considered "booted"
  def self.wait_for=(wait_for)
    @wait_for = wait_for
  end

  def self.wait_for
    @wait_for
  end

  # The default timeout that is waited for a process to boot
  def self.timeout=(timeout)
    @timeout = timeout
  end

  def self.timeout
    @timeout || DEFAULT_TIMEOUT
  end


  # The default shell redirect to the logs
  def self.redirection=(redirection)
    @redirection = redirection
  end

  def self.redirection
    @redirection || DEFAULT_OUT
  end


  # Default environment variables under which commands should be executed.
  def self.env=(env)
    @env = env
  end

  def self.env
    @env || DEFAULT_ENV
  end

  # Creates a new WaitForIt instance
  #
  # @param [String] command Command to spawn
  # @param [Hash] options
  # @options options [Fixnum] :timeout The duration to wait a commmand to boot, default is 10 seconds
  # @options options [String] :wait_for The output the process emits when it has successfully booted.
  #   When present the calling process will block until the message is received in the log output
  #   or until the timeout is hit.
  # @options options [String] :redirection The shell redirection used to pipe to log file
  # @options options [Hash]   :env Keys and values for environment variables in the process
  def initialize(command, options = {})
    @command    = command
    @timeout    = options[:timeout]     || WaitForIt.timeout
    @wait_for   = options[:wait_for]    || WaitForIt.wait_for
    redirection = options[:redirection] || WaitForIt.redirection
    env         = options[:env]         || WaitForIt.env
    @log        = set_log
    @pid        = nil

    raise "Must provide a wait_for: option" unless @wait_for
    spawn(command, redirection, env)
    wait!(@wait_for)

    if block_given?
      begin
        yield self
      ensure
        cleanup
      end
    end
  end

  attr_reader :timeout, :log

  # Checks the logs of the process to see if they contain a match.
  # Can use a string or a regular expression.
  def contains?(input)
    log.read.match convert_to_regex(input)
  end

  # Returns a count of the number of times logs match the input.
  # Can use a string or a regular expression.
  def count(input)
    log.read.scan(convert_to_regex(input)).count
  end

  # Blocks parent process until given message appears at the
  def wait(input, t = timeout)
    regex = convert_to_regex(input)
    Timeout::timeout(t) do
      until log.read.match regex
        sleep 0.01
      end
    end
    sleep 0.01
    self
  rescue Timeout::Error
    puts "Timeout waiting for #{input.inspect} to find a match using #{ regex } in \n'#{ log.read }'"
    false
  end

  # Same as `wait` but raises an error if timeout is reached
  def wait!(input, t = timeout)
    unless wait(input)
      options = {}
      options[:command] = @command
      options[:input]   = input
      options[:timeout] = t
      options[:log]     = @log
      raise WaitForItTimeoutError.new(options)
    end
  end

  # Kills the process and removes temporary files
  def cleanup
    shutdown
    @tmp_file.close
    @log.unlink
  end

private
  def set_log
    @tmp_file  = Tempfile.new(["wait_for_it", ".log"])
    log_file   = Pathname.new(@tmp_file)
    log_file.mkpath unless log_file.exist?
    log_file
  end

  def spawn(command, redirection, env_hash = {})
    env     = env_hash.map {|key, value| "#{ key.to_s.shellescape }=#{ value.to_s.shellescape }" }.join(" ")
    command = "/usr/bin/env #{ env } bash -c #{ command.shellescape } #{ redirection } #{ log }"
    @pid = Process.spawn("#{ command }")
  end

  def convert_to_regex(input)
    return input if input.is_a?(Regexp)
    Regexp.new(Regexp.escape(input))
  end

  # Kills the process and waits for it to exit
  def shutdown
    if @pid
      Process.kill('TERM', @pid)
      Process.wait(@pid)
      @pid = nil
    end
  rescue Errno::ESRCH
    # Process doesn't exist, nothing to kill
  end
end
