require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'shindo'))

BIN = File.join(File.dirname(__FILE__), '..', 'bin', 'shindo')

def bin(arguments)
  `#{BIN} #{arguments}`
end

def path(name)
  File.join(File.dirname(__FILE__), 'data', name)
end
