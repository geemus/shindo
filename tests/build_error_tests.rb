def given_something
  raise 'ERROR!'
end

Shindo.tests('Shindo build errors', ['build_error']) do
  tests('another').returns(true) do
    true
  end

  begin
    given_something do
      tests('success').returns(true) do
        false
      end
    end
  rescue
    # an error occured above, but we intended it
  end
end

