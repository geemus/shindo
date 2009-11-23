module Shindo

  class Rake

    def initialize
      desc "Run tests"
      task :tests do
        ruby FileList[ 'tests/**/*_tests.rb' ].join(' ')
      end
    end

  end

end
