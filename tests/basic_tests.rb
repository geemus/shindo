Shindo.tests('basics') do
  tests('exception') do
    before do
      @tempfile = tempfile('exception', <<-TESTS)
      Shindo.tests do
        test('exception') { raise StandardError.new('exception') }
      end
      TESTS
      @output = bin(@tempfile.path)
    end
    test('output') { @output.include?('- exception') }
    test('status') { $?.exitstatus == 1 }
  end
  tests('failure') do
    before do
      @tempfile = tempfile('failure', <<-TESTS)
      Shindo.tests do
        test('failure') { false }
      end
      TESTS
      @output = bin(@tempfile.path)
    end
    test('output') { @output.include?('- failure') }
    test('status') { $?.exitstatus == 1 }
  end
  tests('pending') do
    before do
      @tempfile = tempfile('pending', <<-TESTS)
      Shindo.tests do
        test('pending')
      end
      TESTS
      @output = bin(@tempfile.path)
    end
    test('output') { @output.include?('* pending') }
    test('status') { $?.exitstatus == 0 }
  end
  tests('success') do
    before do
      @tempfile = tempfile('success', <<-TESTS)
      Shindo.tests do
        test('success') { true }
      end
      TESTS
      @output = bin(@tempfile.path)
    end
    test('output') { @output.include?('+ success') }
    test('status') { $?.exitstatus == 0 }
  end
end
