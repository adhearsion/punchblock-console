require 'punchblock'
require 'pry'
require 'punchblock/console/commands'
require 'punchblock/console/logging'

include Punchblock

Thread.abort_on_exception = true

module PunchblockConsole
  class CLI
    attr_reader :options, :connection, :client, :call_queues

    def initialize(options)
      @options = options
      PunchblockConsole::Logging.start @options.delete(:log_file)
      logger.info "Starting up..."
      @prompt       = options.delete(:prompt)
      @connection   = options.delete(:connection_class).new options
      @client       = Client.new :connection => connection
      @call_queues  = {}

      [:INT, :TERM].each do |signal|
        trap signal do
          logger.info "Shutting down!"
          client.stop
        end
      end
    end

    def run
      run_dispatcher
      client_thread = run_client
      pry if @prompt
      client_thread.join
    end

    def run_client
      Thread.new do
        begin
          client.run
        rescue Punchblock::ProtocolError => e
          case e.name
          when 'Blather::Stream::ConnectionFailed'
            abort "The connection to the XMPP server failed. This could be due to a network failure or the server may not be started or accepting connections."
          else
            logger.error "Exception in Punchblock client thread! #{e.message}"
            logger.error e.backtrace.join("\t\n")
          end
        end
      end
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
          when Connection::Connected
            connection.ready!
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
              # puts "Ad-hoc event: #{event.inspect}"
            end
          else
            logger.warn "Unknown event: #{event.inspect}"
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

        puts "Incoming offer to #{offer.to} from #{offer.from} #{offer}"

        PunchblockConsole::Commands.new(client, offer.call_id, queue).pry

        # Clean up the queue.
        call_queues[offer.call_id] = nil
      end
    end
  end
end
