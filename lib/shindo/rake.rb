module Shindo

  class Rake

    include ::Rake::DSL

    def initialize
      desc "Run shindo tests"
      task :tests do
        system 'shindo'
        fail if $? != 0
      end
    end

  end

end
