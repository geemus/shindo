require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'shindo'))

BIN = File.join(File.dirname(__FILE__), '..', 'bin', 'shindo')

def bin(arguments)
  `#{BIN} #{arguments}`
end

def path(name)
  File.join(File.dirname(__FILE__), 'data', name)
end

module Shindo
  class Tests

    def includes(expectation, description = "includes #{expectation.inspect}", &block)
      test(description) do
        value = instance_eval(&block)
        @message = "expected #{value.inspect} to include #{expectation.inspect}"
        value.include?(expectation)
      end
    end

  end
end
