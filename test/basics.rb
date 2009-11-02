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


Shindo.tests('tags') do
  tests('positive') do
    self.if_tagged = ['+pos']
    test('should run', ['pos']) {true}
    test('should not run') {false}
  end

  tests('negative') do
    self.if_tagged = []
    self.unless_tagged = ['neg']
    test('should run') {true}
    test('should not run', ['neg']) {false}
  end
end
