= shindo

Simple depth first ruby testing, watch and learn.

== Writing tests

Tests group similar assertions, but their return value is ignored.

After that you just test based on the two things a ruby thing should do, raise or return.

Returns takes what you expect and checks a block to see if the return value matches:

  Shindo.tests do
    returns(true) { true }
    returns(false) { false }
  end

Raises takes what error you expect and checks to see if the block will raise it:

  Shindo.tests do
    raises(StandardError) { raise StandardError.new }
  end

For one off simple tests like this you can also chain the calls like this:

  Shindo.tests('raises').raises(StandardError) { raise StandardError.new }

You can also override the default descriptions:

  Shindo.tests('example/bar') do
    returns('default description', 'overriding description: non-default description') { 'default description' }
    raises(StandardError, 'overriding description: raises when true') { raise StandardError if true }
  end

Or nest things inside tests blocks:
  Shindo.tests do
    tests('examples') do
      returns(true, 'returns true description') { true }
      returns(false, 'returns false description') { false }
      raises(StandardError, 'raises StandardError description') { raise StandardError }
    end
  end

Then, if you want to get extra fancy you can tag  tests, to help narrow down which ones to run

  Shindo.tests('tests for true', 'true') do
    test(true) { true }
  end

  Shindo.tests('tests for false', 'false') do
    test(false) { false }
  end

Note: you'll have to supply a non-default description first, and then follow up with tags.

== Setup and Teardown

Tests get evaluated in the file just like you see it so you can add setup and teardown easily:

  Shindo.tests do
    bool = true # setup
    tests('bool').returns(true) { bool }

    bool = false # cleanup after last
    tests('bool').returns(false) { bool }

    foo = nil # teardown
  end

That can get pretty tedious if it needs to happen before or after every single test though, so there are helpers:

  Shindo.tests do
    before do
      @object = Object.new
    end

    after do
      @object = nil
    end

    tests('@object.class').returns(Object) { @object.class }
  end

== Running tests

Run tests with the shindo command, the easiest is to specify a file name:

  shindo something_tests.rb

You can also give directories and it will run all files ending in _tests.rb and include all files ending in _helper.rb (recurses through subdirectories)

  shindo some_test_directory

That leaves tags, which use +/-.  So run just tests with the 'true' tag:

  shindo some_test_directory +true

Or those without the 'false' tag:

  shindo some_test_directory -false

Or combine to run everything with a 'true' tag, but no 'false' tag

  shindo some_test_directory +true -false

If you are running in a non-interactive mode, or one where speed matters (i.e. continuous integration), you can run shindo with (n)o (t)race and much quieter output. It takes all the same arguments, but uses the shindont bin file.

  shindont something_tests.rb

== Command line tools

When tests fail you'll get lots of options to help you debug the problem, just enter '?' at the prompt to see your options.

== Copyright

(The MIT License)

Copyright (c) 2021 {geemus (Wesley Beary)}[http://github.com/geemus]

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
