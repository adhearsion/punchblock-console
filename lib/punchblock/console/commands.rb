module PunchblockConsole
  class Commands
    def initialize(client, call_id, queue)
      @client, @call_id, @queue = client, call_id, queue
    end

    def accept
      write Command::Accept.new
    end

    def answer
      write Command::Answer.new
    end

    def hangup
      write Command::Hangup.new
    end

    def reject(reason = :decline)
      write Command::Reject.new(:reason => reason)
    end

    def redirect(dest)
      write Command::Redirect.new(:to => dest)
    end

    def record(options = {})
      write Component::Record.new(options)
    end

    def say(string)
      output string, :text
    end

    def output(string, type = :text)
      component = Component::Output.new(type => string)
      write component
      component.complete_event
    end

    def agi(command, params = {})
      component = Component::Asterisk::AGI::Command.new :name => command, :params => params
      write component
      component.complete_event
    end

    def write(command)
      @client.execute_command command, :call_id => @call_id, :async => false
    end
  end
end
