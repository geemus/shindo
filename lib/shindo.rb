require 'rubygems'
require 'formatador'
require 'gestalt'

module Shindo

  unless const_defined?(:VERSION)
    VERSION = '0.0.18'
  end

  def self.tests(description = nil, tags = [], &block)
    STDOUT.sync = true
    Shindo::Tests.new(description, tags, &block)
  end

  class Tests

    def initialize(description, tags = [], &block)
      @afters     = []
      @befores    = []
      @formatador = Formatador.new
      @tag_stack  = []
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
      @formatador.display_line
      tests(description, tags, &block)
      @formatador.display_line
    end

    def after(&block)
      @afters.last.push(block)
    end

    def before(&block)
      @befores.last.push(block)
    end

    def prompt(description, &block)
      @formatador.display("Action? [c,e,i,q,r,t,?]? ")
      choice = STDIN.gets.strip
      continue = false
      @formatador.display_line
      @formatador.indent do
        case choice
        when 'c', 'continue'
          continue = true
        when /^e .*/, /^eval .*/
          value = eval(choice[2..-1], @gestalt.bindings.last)
          if value.nil?
            value = 'nil'
          end
          @formatador.display_line(value)
        when 'i', 'interactive', 'irb'
          @formatador.display_line('Starting interactive session...')
          if @irb.nil?
            require 'irb'
            ARGV.clear # Avoid passing args to IRB
            IRB.setup(nil)
            @irb = IRB::Irb.new(nil)
            IRB.conf[:MAIN_CONTEXT] = @irb.context
            IRB.conf[:PROMPT][:SHINDO] = {}
          end
          for key, value in IRB.conf[:PROMPT][:SIMPLE]
            IRB.conf[:PROMPT][:SHINDO][key] = "#{@formatador.indentation}#{value}"
          end
          @irb.context.prompt_mode = :SHINDO
          @irb.context.workspace = IRB::WorkSpace.new(@gestalt.bindings.last)
          begin
            @irb.eval_input
          rescue SystemExit
          end
        when 'q', 'quit', 'exit'
          @formatador.display_line("Exiting...")
          @exit = true
        when 'r', 'reload'
          @formatador.display_line("Reloading...")
          Thread.current[:reload] = true
        when 't', 'backtrace', 'trace'
          if @gestalt.calls.empty?
            @formatador.display_line("[red]No methods were called, so no backtrace was captured.[/]")
          else
            @gestalt.display_calls
          end
        when '?', 'help'
          @formatador.display_lines([
            'c - ignore this error and continue',
            'i - interactive mode',
            'q - quit Shindo',
            'r - reload and run the tests again',
            't - display backtrace',
            '? - display help'
          ])
        else
          @formatador.display_line("[red]#{choice} is not a valid choice, please try again.[/]")
        end
        @formatador.display_line
      end
      unless continue || @exit
        @formatador.display_line("[red]- #{description}[/]")
        prompt(description, &block)
      end
    end

    def tests(description, tags = [], &block)
      return if @exit || Thread.current[:reload]

      tags = [*tags]
      @tag_stack.push(tags)
      @befores.push([])
      @afters.push([])

      description ||= 'Shindo.tests'
      description = "[bold]#{description}[normal]"
      unless tags.empty?
        description << " (#{tags.join(', ')})"
      end

      # if the test includes +tags and discludes -tags, evaluate it
      if (@if_tagged.empty? || !(@if_tagged & @tag_stack.flatten).empty?) &&
          (@unless_tagged.empty? || (@unless_tagged & @tag_stack.flatten).empty?)
        @formatador.display_line(description)
        if block_given?
          @formatador.indent { instance_eval(&block) }
        end
      else
        @formatador.display_line("[light_black]#{description}[/]")
      end

      @afters.pop
      @befores.pop
      @tag_stack.pop

      Thread.exit if @exit || Thread.current[:reload]
    end

    def raises(error, &block)
      assertion(:raises, error, "raises #{error.inspect}", &block)
    end

    def returns(value, &block)
      assertion(:returns, value, "returns #{value.inspect}", &block)
    end

    def test(description = "returns true", &block)
      assertion(:returns, true, description, &block)
    end

    private

    def assertion(type, expectation, description, &block)
      return if @exit || Thread.current[:reload]
      success = nil
      @gestalt = Gestalt.new({'c-call' => true, 'formatador' => @formatador})
      if block_given?
        begin
          for before in @befores.flatten.compact
            before.call
          end
          success = case type
          when :raises
            @gestalt.run(&block).is_a?(expectation)
          when :returns
            @gestalt.run(&block) == expectation
          end
          for after in @afters.flatten.compact
            after.call
          end
        rescue => error
          Thread.current[:totals][:failed] += 1
          @formatador.display_line("[red]#{error.message} (#{error.class})[/]")
        end
        if success
          Thread.current[:totals][:succeeded] += 1
          @formatador.display_line("[green]+ #{description}[/]")
        else
          Thread.current[:totals][:failed] += 1
          @formatador.display_line("[red]- #{description}[/]")
          if STDOUT.tty?
            prompt(description, &block)
          end
        end
      else
        Thread.current[:totals][:pending] += 1
        @formatador.display_line("[yellow]# #{description}[/]")
      end
    end

  end

end
