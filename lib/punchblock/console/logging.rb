require 'logging'

class Object
  def pb_logger
    logger
  end

  def logger
    @logger ||= ::Logging.logger[self]
  end
end

module PunchblockConsole
  module Logging

    LOG_LEVELS = %w(TRACE DEBUG INFO WARN ERROR FATAL)

    class << self

      ::Logging.color_scheme('bright',
        :levels => {
          :info  => :green,
          :warn  => :yellow,
          :error => :red,
          :fatal => [:white, :on_red]
        },
        :date => :blue,
        :logger => :cyan,
        :message => :magenta
      )

      def silence!
        self.logging_level = :fatal
      end

      def unsilence!
        self.logging_level = :info
      end

      def reset
        ::Logging.reset
      end

      def start(log_file = nil)
        opts = {
                  :layout => ::Logging.layouts.pattern(
                    :pattern => '[%d] %-5l %c: %m\n',
                    :color_scheme => 'bright'
                  )
                }
        self.outputters = if log_file
          ::Logging.appenders.file log_file, opts
        else
          ::Logging.appenders.stdout 'stdout', opts
        end

        ::Logging.init LOG_LEVELS

        LOG_LEVELS.each do |level|
          PunchblockConsole::Logging.const_defined?(level) or PunchblockConsole::Logging.const_set(level, ::Logging::LEVELS[::Logging.levelify(level)])
        end
      end

      def logging_level=(new_logging_level)
        ::Logging::Logger[:root].level = new_logging_level
      end

      alias :level= :logging_level=

      def logging_level
        ::Logging::Logger[:root].level
      end

      def get_logger(logger_name)
        ::Logging::Logger[logger_name]
      end

      alias :level :logging_level

      def sanitized_logger_name(name)
        name.to_s.gsub(/\W/, '').downcase
      end

      def outputters=(outputters)
        ::Logging.logger.root.appenders = Array(outputters)
      end

      alias :appenders= :outputters=

      def outputters
        ::Logging.logger.root.appenders
      end

      alias :appenders :outputters

      def formatter=(formatter)
        _set_formatter formatter
      end

      alias :layout= :formatter=

      def formatter
        ::Logging.logger.root.appenders.first.layout
      end

      alias :layout :formatter

      private

      def _set_formatter(formatter)
        ::Logging.logger.root.appenders.each do |appender|
          appender.layout = formatter
        end
      end

    end

  end
end
