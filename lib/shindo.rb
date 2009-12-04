require 'rubygems'
require 'annals'
require 'formatador'

module Shindo

  def self.tests(header = nil, &block)
    STDOUT.sync = true
    Shindo::Tests.new(header, &block)
  end

  class Tests

    attr_accessor :backtrace

    def initialize(header, tags = [], &block)
      @afters     = []
      @annals     = Annals.new
      @befores    = []
      @formatador = Formatador.new
      @success    = true
      @tag_stack  = []
      Thread.current[:reload] = false;
      Thread.current[:tags] ||= []
      @if_tagged      = Thread.current[:tags].
                          select {|tag| tag.match(/^\+/)}.
                          map {|tag| tag[1..-1]}
      @unless_tagged  = Thread.current[:tags].
                          select {|tag| tag.match(/^\-/)}.
                          map {|tag| tag[1..-1]}
      @formatador.display_line('')
      tests(header, tags, &block)
      @formatador.display_line('')
      Thread.current[:success] = @success
    end

    def after(&block)
      @afters[-1].push(block)
    end

    def before(&block)
      @befores[-1].push(block)
    end

    def prompt(description, &block)
      @formatador.display("Action? [c,i,q,r,t,#,?]? ")
      choice = STDIN.gets.strip
      @formatador.display_line("")
      case choice
      when 'c'
        return
      when 'i'
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
      when 'q'
        Thread.current[:success] = false
        Thread.exit
      when 'r'
        @formatador.display_line("Reloading...")
        Thread.current[:reload] = true
        Thread.exit
      when 't'
        @formatador.indent do
          if @annals.lines.empty?
            @formatador.display_line('no backtrace available')
          else
            @annals.lines.each_with_index do |line, index|
              @formatador.display_line("#{' ' * (2 - index.to_s.length)}#{index}  #{line}")
            end
          end
        end
        @formatador.display_line('')
      when '?'
        @formatador.display_line('c - ignore this error and continue')
        @formatador.display_line('i - interactive mode')
        @formatador.display_line('q - quit Shindo')
        @formatador.display_line('r - reload and run the tests again')
        @formatador.display_line('t - display backtrace')
        @formatador.display_line('# - enter a number of a backtrace line to see its context')
        @formatador.display_line('? - display help')
      when /\d/
        index = choice.to_i - 1
        if @annals.lines[index]
          @formatador.indent do
            @formatador.display_line("#{@annals.lines[index]}: ")
            @formatador.indent do
              @formatador.display("\n")
              current_line = @annals.buffer[index]
              File.open(current_line[:file], 'r') do |file|
                data = file.readlines
                current = current_line[:line]
                min     = [0, current - (@annals.max / 2)].max
                max     = [current + (@annals.max / 2), data.length].min
                min.upto(current - 1) do |line|
                  @formatador.display_line("#{line}  #{data[line].rstrip}")
                end
                @formatador.display_line("[yellow]#{current}  #{data[current].rstrip}[/]")
                (current + 1).upto(max - 1) do |line|
                  @formatador.display_line("#{line}  #{data[line].rstrip}")
                end
              end
              @formatador.display_line('')
            end
          end
        else
          @formatador.display_line("[red]#{choice} is not a valid backtrace line, please try again.[/]")
        end
      else
        @formatador.display_line("[red]#{choice} is not a valid choice, please try again.[/]")
      end
      @formatador.display_line("[red]- #{description}[/]")
      prompt(&block)
    end

    def tests(description, tags = [], &block)
      @tag_stack.push([*tags])
      @befores.push([])
      @afters.push([])

      taggings = ''
      unless tags.empty?
        taggings = " (#{[*tags].join(', ')})"
      end

      @formatador.display_line((description || 'Shindo.tests') << taggings)
      if block_given?
        @formatador.indent { instance_eval(&block) }
      end

      @afters.pop
      @befores.pop
      @tag_stack.pop
    end

    def test(description, tags = [], &block)
      @tag_stack.push([*tags])
      taggings = ''
      unless tags.empty?
        taggings = " (#{[*tags].join(', ')})"
      end

      # if the test includes +tags and discludes -tags, evaluate it
      if (@if_tagged.empty? || !(@if_tagged & @tag_stack.flatten).empty?) &&
          (@unless_tagged.empty? || (@unless_tagged & @tag_stack.flatten).empty?)
        if block_given?
          for before in @befores.flatten.compact
            before.call
          end

          @annals.start
          begin
            success = instance_eval(&block)
            @annals.stop
          rescue => error
            @annals.stop
            success = false
            file, line, method = error.backtrace.first.split(':')
            if method
              method << "in #{method[4...-1]} " # get method from "in `foo'"
            else
              method = ''
            end
            method << "! #{error.message} (#{error.class})"
            @annals.unshift(:file => file, :line => line.to_i, :method => method)
          end
          @success = @success && success
          if success
            @formatador.display_line("[green]+ #{description}#{taggings}[/]")
          else
            @formatador.display_line("[red]- #{description}#{taggings}[/]")
            if STDOUT.tty?
              prompt(description, &block)
            end
          end

          for after in @afters.flatten.compact
            after.call
          end
        else
          @formatador.display_line("[yellow]* #{description}#{taggings}[/]")
        end
      else
        @formatador.display_line("_ #{description}#{taggings}")
      end

      @tag_stack.pop
    end

  end

end
