module Shindo

  class Rake

    include ::Rake::DSL

    def initialize
      desc "Run shindo tests"
      task :tests do
        system 'shindo'
      end
    end

  end

end
