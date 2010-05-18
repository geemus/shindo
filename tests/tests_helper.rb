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

    def includes(value, description = "includes #{value.inspect}", &block)
      test(description) { instance_eval(&block).include?(value) }
    end

  end
end
