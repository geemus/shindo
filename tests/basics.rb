require File.join(File.dirname(__FILE__), 'tests_helper')

success = Tempfile.new('success')
success << <<-TESTS
Shindo.tests {
  test('success') { true }
}
TESTS
success.close

failure = Tempfile.new('failure')
failure << <<-TESTS
Shindo.tests {
  test('failure') { false }
}
TESTS
failure.close

pending = Tempfile.new('pending')
pending << <<-TESTS
Shindo.tests {
  test('pending')
}
TESTS
pending.close

Shindo.tests('basics') {
  tests('failure') {
    test('output') { `#{BIN} #{failure.path}`.include?('- failure') }
    test('status') { $?.exitstatus == 1 }
  }
  tests('pending') {
    test('output') { `#{BIN} #{pending.path}`.include?('* pending') }
    test('status') { $?.exitstatus == 0 }
  }
  tests('success') {
    test('output') { `#{BIN} #{success.path}`.include?('+ success') }
    test('status') { $?.exitstatus == 0 }
  }
}
