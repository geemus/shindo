require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'shindo'))

require 'tempfile'

BIN = File.join(File.dirname(__FILE__), '..', 'bin', 'shindo')

def bin(arguments)
  `#{BIN} #{arguments}`
end

def tempfile(name, data)
  tempfile = Tempfile.new(name)
  tempfile << data
  tempfile.close
  tempfile
end
