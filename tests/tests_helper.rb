$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'shindo'
require 'tempfile'

unless Object.const_defined?(:BIN)
  BIN = File.join(File.dirname(__FILE__), '..', 'bin', 'shindo')
end