module PunchblockConsole
  class Commands
    def initialize(client, call_id, queue) # :nodoc:
      @client, @call_id, @queue = client, call_id, queue
    end

    def accept # :nodoc:
      write Command::Accept.new
    end

    def answer # :nodoc:
      write Command::Answer.new
    end

    def hangup # :nodoc:
      write Command::Hangup.new
    end

    def reject(reason = nil) # :nodoc:
      write Command::Reject.new(:reason => reason)
    end

    def redirect(dest) # :nodoc:
      write Command::Redirect.new(:to => dest)
    end

    def record(options = {})
      write Component::Record.new(options)
    end

    def say(string, type = :text) # :nodoc:
      component = Component::Tropo::Say.new(type => string)
      write component
      component.complete_event.resource
    end

    def agi(command, params = {})
      component = Component::Asterisk::AGI::Command.new :name => command, :params => params
      write component
      puts component.complete_event.resource
    end

    def write(command) # :nodoc:
      @client.execute_command command, :call_id => @call_id, :async => false
    end
  end
end
