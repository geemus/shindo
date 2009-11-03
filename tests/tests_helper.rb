$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'shindo'
require 'tempfile'

unless Object.const_defined?(:BIN)
  BIN = File.join(File.dirname(__FILE__), '..', 'bin', 'shindo')
end
tags = Thread.current[:tags] || []
ARGV.each do |arg|
    if arg.match(/^[\+\-]/)
      tags << arg
    ARGV.delete(arg)
  end
end
Thread.current[:tags] = tags
