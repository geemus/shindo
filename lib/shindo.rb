require 'rubygems'
require 'gestalt'
require 'formatador'

module Shindo

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
      Thread.current[:success] = true
      Thread.current[:tags] ||= []
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
      @formatador.display_line
      case choice
      when 'c', 'continue'
        return
      when /^e .*/, /^eval .*/
        @formatador.display_line(eval(choice[2..-1], block.binding))
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
        @irb.context.workspace = IRB::WorkSpace.new(block.binding)
        begin
          @irb.eval_input
        rescue SystemExit
        end
      when 'q', 'quit', 'exit'
        Thread.current[:success] = false
        Thread.exit
      when 'r', 'reload'
        @formatador.display_line("Reloading...")
        Thread.current[:reload] = true
        Thread.exit
      when 't', 'backtrace', 'trace'
        Gestalt.trace(&block)
      when '?', 'help'
        @formatador.display_line('c - ignore this error and continue')
        @formatador.display_line('i - interactive mode')
        @formatador.display_line('q - quit Shindo')
        @formatador.display_line('r - reload and run the tests again')
        @formatador.display_line('t - display backtrace')
        @formatador.display_line('? - display help')
      else
        @formatador.display_line("[red]#{choice} is not a valid choice, please try again.[/]")
      end
      @formatador.display_line
      @formatador.display_line("[red]- #{description}[/]")
      prompt(description, &block)
    end

    def tests(description, tags = [], &block)
      tags = [*tags]
      @tag_stack.push(tags)
      @befores.push([])
      @afters.push([])

      unless tags.empty?
        taggings = " (#{tags.join(', ')})"
      end

      @formatador.display_line((description || 'Shindo.tests') << taggings.to_s)
      if block_given?
        @formatador.indent { instance_eval(&block) }
      end

      @afters.pop
      @befores.pop
      @tag_stack.pop
    end

    def test(description, tags = [], &block)
      tags = [*tags]
      @tag_stack.push(tags)
      unless tags.empty?
        taggings = " (#{tags.join(', ')})"
      end

      # if the test includes +tags and discludes -tags, evaluate it
      if (@if_tagged.empty? || !(@if_tagged & @tag_stack.flatten).empty?) &&
          (@unless_tagged.empty? || (@unless_tagged & @tag_stack.flatten).empty?)
        if block_given?
          begin
            for before in @befores.flatten.compact
              before.call
            end
            Thread.current[:success] = instance_eval(&block)
            for after in @afters.flatten.compact
              after.call
            end
          rescue => error
            Thread.current[:success] = false
            @formatador.display_line("[red]#{error.message} (#{error.class})[/]")
          end
          if Thread.current[:success]
            @formatador.display_line("[green]+ #{description}#{taggings.to_s}[/]")
          else
            @formatador.display_line("[red]- #{description}#{taggings.to_s}[/]")
            if STDOUT.tty?
              prompt(description, &block)
            end
          end
        else
          @formatador.display_line("[yellow]* #{description}#{taggings.to_s}[/]")
        end
      else
        @formatador.display_line("_ #{description}#{taggings.to_s}")
      end

      @tag_stack.pop
    end

  end

end


if __FILE__ == $0

  def bar(string, remaining = ['b','a','r'])
    if remaining.empty?
      string
    else
      bar(string << remaining.shift, remaining)
    end
  end

  Shindo.tests do

    test('failure') do
      raise StandardError.new('exception')
      @foo = ''
      bar(@foo)
      @foo == 'foo'
    end

  end

end
