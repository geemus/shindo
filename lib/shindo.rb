require 'rubygems'
require 'formatador'

module Shindo

  class Pending < StandardError; end

  unless const_defined?(:VERSION)
    VERSION = '0.3.4'
  end

  def self.tests(description = nil, tags = [], &block)
    STDOUT.sync = true
    Shindo::Tests.new(description, tags, &block)
  end

  class Tests

    def initialize(description, tags = [], &block)
      @afters     = []
      @befores    = []
      @description_stack  = []
      @tag_stack          = []
      Thread.current[:reload] = false
      Thread.current[:tags] ||= []
      Thread.current[:totals] ||= { :failed => 0, :pending => 0, :skipped => 0, :succeeded => 0 }
      @if_tagged = []
      @unless_tagged = []
      for tag in Thread.current[:tags]
        case tag[0...1]
        when '+'
          @if_tagged << tag[1..-1]
        when '-'
          @unless_tagged << tag[1..-1]
        end
      end
      Formatador.display_line
      tests(description, tags, &block)
    end

    def after(&block)
      @afters.last.push(block)
    end

    def before(&block)
      @befores.last.push(block)
    end

    def pending
      raise(Shindo::Pending.new)
    end

    def tests(description, tags = [], &block)
      return self if Thread.main[:exit] || Thread.current[:reload]

      tags = [*tags]
      @tag_stack.push(tags)
      @befores.push([])
      @afters.push([])

      @description = nil
      @inline = false
      description ||= 'Shindo.tests'
      description = "[bold]#{description}[normal]"
      unless tags.empty?
        description << " (#{tags.join(', ')})"
      end
      @description_stack.push(description)

      # if the test includes +tags and discludes -tags, evaluate it
      if (@if_tagged.empty? || !(@if_tagged & @tag_stack.flatten).empty?) &&
          (@unless_tagged.empty? || (@unless_tagged & @tag_stack.flatten).empty?)
        if block_given?
          begin
            display_description(description)
            # HACK: increase indent
            indent = Thread.current[:formatador].instance_variable_get(:@indent)
            Thread.current[:formatador].instance_variable_set(:@indent, indent + 1)
            instance_eval(&block)
          rescue Shindo::Pending
            display_pending(description)
          rescue => error
            display_error(error)
          ensure
            # HACK: decrease indent
            indent = Thread.current[:formatador].instance_variable_get(:@indent)
            Thread.current[:formatador].instance_variable_set(:@indent, indent - 1)
          end
        else
          @inline = true
          display_description(description)
        end
      else
        display_description("[light_black]#{description}[/]")
      end

      @description_stack.pop
      @afters.pop
      @befores.pop
      @tag_stack.pop

      Thread.exit if Thread.main[:exit] || Thread.current[:reload]
      self
    end

    def raises(error, description = "raises #{error.inspect}", &block)
      assert(:raises, error, description, &block)
    end

    def returns(expectation, description = "returns #{expectation.inspect}", &block)
      assert(:returns, expectation, description, &block)
    end

    def test(description = 'returns true', &block)
      assert(:returns, true, description, &block)
    end

    private

    def assert(type, expectation, description, &block)
      return if Thread.main[:exit] || Thread.current[:reload]
      description = [@description, description].compact.join(' ')
      if block_given?
        begin
          for before in @befores.flatten.compact
            before.call
          end
          value, success = case type
          when :raises
            value = begin
              instance_eval(&block)
            rescue Shindo::Pending
              @pending = true
            rescue => error
              error
            end
            [value, value.is_a?(expectation)]
          when :returns
            [value = instance_eval(&block), value == expectation]
          end
          for after in @afters.flatten.compact
            after.call
          end
        rescue Shindo::Pending
          @pending = true
        rescue => error
          success = false
          value = error
        end
        if @pending
          @pending = false
          display_pending(description)
        elsif success
          display_success(description)
        else
          display_failure(description)
          case value
          when Exception, Interrupt
            display_error(value)
          else
            @message ||= [
              "expected => #{expectation.inspect}",
              "returned => #{value.inspect}"
            ]
            Formatador.indent do
              Formatador.display_lines([*@message].map {|message| "[red]#{message}[/]"})
            end
            @message = nil
          end
          if Thread.current[:interactive] && STDOUT.tty?
            prompt(description, &block)
          end
        end
      else
        display_pending(description)
      end
      success
    end

    def prompt(description, &block)
      return if Thread.main[:exit] || Thread.current[:reload]
      Formatador.display("Action? [c,q,r,?]? ")
      choice = STDIN.gets.strip
      continue = false
      Formatador.display_line
      Formatador.indent do
        case choice
        when 'c', 'continue'
          continue = true
        when 'q', 'quit', 'exit'
          Formatador.display_line("Exiting...")
          Thread.main[:exit] = true
        when 'r', 'reload'
          Formatador.display_line("Reloading...")
          Thread.current[:reload] = true
        when '?', 'help'
          Formatador.display_lines([
            'c - ignore this error and continue',
            'q - quit Shindo',
            'r - reload and run the tests again',
            '? - display help'
          ])
        else
          Formatador.display_line("[red]#{choice} is not a valid choice, please try again.[/]")
        end
        Formatador.display_line
      end
      unless continue || Thread.main[:exit]
        Formatador.display_line("[red]- #{description}[/]")
        prompt(description, &block)
      end
    end

  end

end
