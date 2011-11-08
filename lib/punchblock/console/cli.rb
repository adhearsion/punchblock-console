require 'punchblock'
require 'pry'
require 'punchblock/console/commands'

include Punchblock

Thread.abort_on_exception = true

module PunchblockConsole
  class CLI
    attr_reader :options, :connection, :client, :call_queues

    def initialize(options)
      @options = options
      setup_logging
      @connection   = options.delete(:connection_class).new options
      @client       = Client.new :connection => connection
      @call_queues  = {}

      [:INT, :TERM].each do |signal|
        trap signal do
          puts "Shutting down!"
          client.stop
        end
      end
    end

    def setup_logging
      if options.has_key? :wire_log_file
        options[:wire_logger] = Logger.new options.delete(:wire_log_file)
        options[:wire_logger].level = Logger::DEBUG
        options[:wire_logger].debug "Starting up..."
      end

      if options.has_key? :transport_log_file
        options[:transport_logger] = Logger.new options.delete(:transport_log_file)
        options[:transport_logger].level = Logger::DEBUG
        options[:transport_logger].debug "Starting up..."
      end
    end

    def run
      run_dispatcher
      client.run
    end

    def run_dispatcher
      ### DISPATCHER THREAD
      # This thread multiplexes the event stream from the underlying connection
      # handler and routes them to the correct queue for each call.  It also starts
      # a call handler, the run_call method) after creating the queue.
      Thread.new do
        loop do
          event = client.event_queue.pop
          case event
          when Punchblock::Connection::Connected
            puts "Punchblock connected!"
          when Event::Offer
            raise "Duplicate call ID for #{event.call_id}" if call_queues.has_key?(event.call_id)
            call_queues[event.call_id] = Queue.new
            call_queues[event.call_id].push event
            run_call client, event
          when Event
            if event.call_id
              call_queues[event.call_id].push event
            else
              puts "Ad-hoc event: #{event.inspect}"
            end
          else
            puts "Unknown event: #{event.inspect}"
          end
        end
      end
    end

    def run_call(client, offer)
      ### CALL THREAD
      # One thread is spun up to handle each call.
      Thread.new do
        raise "Unknown call #{offer.call_id}" unless call_queues.has_key?(offer.call_id)
        queue = call_queues[offer.call_id]
        call = queue.pop

        puts "Incoming offer to #{offer.to} from #{offer.headers_hash[:from]} #{offer}"

        PunchblockConsole::Commands.new(client, offer.call_id, queue).pry

        # Clean up the queue.
        call_queues[offer.call_id] = nil
      end
    end
  end
end
