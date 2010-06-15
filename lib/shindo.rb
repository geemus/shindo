require 'rubygems'
require 'formatador'
require 'gestalt'

module Shindo

  unless const_defined?(:VERSION)
    VERSION = '0.1.4'
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
      Thread.current[:formatador] = Formatador.new
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
      Thread.current[:formatador].display_line
      tests(description, tags, &block)
    end

    def after(&block)
      @afters.last.push(block)
    end

    def before(&block)
      @befores.last.push(block)
    end

    def tests(description, tags = [], &block)
      return self if Thread.main[:exit] || Thread.current[:reload]

      tags = [*tags]
      @tag_stack.push(tags)
      @befores.push([])
      @afters.push([])

      @description = nil
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
            Thread.current[:formatador].indent { instance_eval(&block) }
          rescue => error
            display_error(error)
          end
        else
          @description = description
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

    def raises(error, &block)
      assert(:raises, error, "raises #{error.inspect}", &block)
    end

    def returns(expectation, &block)
      assert(:returns, expectation, "returns #{expectation.inspect}", &block)
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
            raises?(expectation, &block)
          when :returns
            returns?(expectation, &block)
          end
          for after in @afters.flatten.compact
            after.call
          end
        rescue => error
          success = false
          value = error
        end
        if success
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
            Thread.current[:formatador].indent do
              Thread.current[:formatador].display_lines([*@message].map {|message| "[red]#{message}[/]"})
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
      Thread.current[:formatador].display("Action? [c,e,i,q,r,t,?]? ")
      choice = STDIN.gets.strip
      continue = false
      Thread.current[:formatador].display_line
      Thread.current[:formatador].indent do
        case choice
        when 'c', 'continue'
          continue = true
        when /^e .*/, /^eval .*/
          begin
            value = eval(choice[2..-1], @gestalt.bindings.last)
            if value.nil?
              value = 'nil'
            end
            Thread.current[:formatador].display_line(value)
          rescue => error
            display_error(error)
          end
        when 'i', 'interactive', 'irb'
          Thread.current[:formatador].display_line('Starting interactive session...')
          if @irb.nil?
            require 'irb'
            ARGV.clear # Avoid passing args to IRB
            IRB.setup(nil)
            @irb = IRB::Irb.new(nil)
            IRB.conf[:MAIN_CONTEXT] = @irb.context
            IRB.conf[:PROMPT][:SHINDO] = {}
          end
          for key, value in IRB.conf[:PROMPT][:SIMPLE]
            IRB.conf[:PROMPT][:SHINDO][key] = "#{Thread.current[:formatador].indentation}#{value}"
          end
          @irb.context.prompt_mode = :SHINDO
          @irb.context.workspace = IRB::WorkSpace.new(@gestalt.bindings.last)
          begin
            @irb.eval_input
          rescue SystemExit
          end
        when 'q', 'quit', 'exit'
          Thread.current[:formatador].display_line("Exiting...")
          Thread.main[:exit] = true
        when 'r', 'reload'
          Thread.current[:formatador].display_line("Reloading...")
          Thread.current[:reload] = true
        when 't', 'backtrace', 'trace'
          if @gestalt.calls.empty?
            Thread.current[:formatador].display_line("[red]No methods were called, so no backtrace was captured.[/]")
          else
            @gestalt.display_calls
          end
        when '?', 'help'
          Thread.current[:formatador].display_lines([
            'c - ignore this error and continue',
            'i - interactive mode',
            'q - quit Shindo',
            'r - reload and run the tests again',
            't - display backtrace',
            '? - display help'
          ])
        else
          Thread.current[:formatador].display_line("[red]#{choice} is not a valid choice, please try again.[/]")
        end
        Thread.current[:formatador].display_line
      end
      unless continue || Thread.main[:exit]
        Thread.current[:formatador].display_line("[red]- #{description}[/]")
        prompt(description, &block)
      end
    end

  end

end
