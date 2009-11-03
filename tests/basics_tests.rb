require File.join(File.dirname(__FILE__), 'tests_helper')

success = Tempfile.new('success')
success << <<-TESTS
Shindo.tests do
  test('success') { true }
end
TESTS
success.close

failure = Tempfile.new('failure')
failure << <<-TESTS
Shindo.tests do
  test('failure') { false }
end
TESTS
failure.close

pending = Tempfile.new('pending')
pending << <<-TESTS
Shindo.tests do
  test('pending')
end
TESTS
pending.close

Shindo.tests('basics') do
  tests('failure') do
    test('output') { `#{BIN} #{failure.path}`.include?('- failure') }
    test('status') { $?.exitstatus == 1 }
  end
  tests('pending') do
    test('output') { `#{BIN} #{pending.path}`.include?('* pending') }
    test('status') { $?.exitstatus == 0 }
  end
  tests('success') do
    test('output') { `#{BIN} #{success.path}`.include?('+ success') }
    test('status') { $?.exitstatus == 0 }
  end
end
