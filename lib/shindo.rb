require 'rubygems'
require 'annals'

module Shindo

  def self.tests(header = nil, &block)
    STDOUT.sync = true
    Shindo::Tests.new(header, &block)
  end

  class Tests

    attr_accessor :backtrace

    attr_accessor :if_tagged, :unless_tagged

    def initialize(header, tags = [], &block)
      @afters     = []
      @annals     = Annals.new
      @befores    = []
      @description_stack = []
      self.if_tagged      = Thread.current[:tags].select {|tag| tag.match(/^\+/)}
      self.unless_tagged  = Thread.current[:tags].
                              select {|tag| tag.match(/^\-/)}.
                              map {|tag| tag[1..-1]}
      @indent     = 1
      @success    = true
      @tag_stack  = []
      Thread.current[:reload] = false
      print("\n")
      tests(header, &block)
      print("\n")
      if @success
        Thread.current[:success] = true
      else
        Thread.current[:success] = false
      end
    end

    def after(&block)
      @afters[-1].push(block)
    end

    def before(&block)
      @befores[-1].push(block)
    end

    def full_description
      "#{@description_stack.compact.join(' ')}#{full_tags}"
    end

    def full_tags
      unless @tag_stack.flatten.empty?
        " [#{@tag_stack.flatten.join(', ')}]"
      end
    end

    def green_line(content)
      print_line(content, "\e[32m")
    end

    def indent(&block)
      @indent += 1
      yield
      @indent -= 1
    end

    def indentation
      '  ' * @indent
    end

    def print_line(content, color = nil)
      if color && STDOUT.tty?
        content = "#{color}#{content}\e[0m"
      end
      print("#{indentation}#{content}\n")
    end

    def prompt(&block)
      print("#{indentation}Action? [c,i,q,r,t,#,?]? ")
      choice = STDIN.gets.strip
      print("\n")
      case choice
      when 'c'
        return
      when 'i'
        print_line('Starting interactive session...')
        if @irb.nil?
          require 'irb'
          ARGV.clear # Avoid passing args to IRB
          IRB.setup(nil)
          @irb = IRB::Irb.new(nil)
          IRB.conf[:MAIN_CONTEXT] = @irb.context
          IRB.conf[:PROMPT][:TREST] = {}
        end
        for key, value in IRB.conf[:PROMPT][:SIMPLE]
          IRB.conf[:PROMPT][:TREST][key] = "#{indentation}#{value}"
        end
        @irb.context.prompt_mode = :TREST
        @irb.context.workspace = IRB::WorkSpace.new(block.binding)
        begin
          @irb.eval_input
        rescue SystemExit
        end
      when 'q'
        Thread.current[:success] = false
        Thread.exit
      when 'r'
        print("Reloading...\n")
        Thread.current[:reload] = true
        Thread.exit
      when 't'
        indent {
          if @annals.lines.empty?
            print_line('no backtrace available')
          else
            index = 1
            for line in @annals.lines
              print_line("#{' ' * (2 - index.to_s.length)}#{index}  #{line}")
              index += 1
            end
          end
        }
        print("\n")
      when '?'
        print_line('c - ignore this error and continue')
        print_line('i - interactive mode')
        print_line('q - quit Shindo')
        print_line('r - reload and run the tests again')
        print_line('t - display backtrace')
        print_line('# - enter a number of a backtrace line to see its context')
        print_line('? - display help')
      when /\d/
        index = choice.to_i - 1
        if @annals.lines[index]
          indent {
            print_line("#{@annals.lines[index]}: ")
            indent {
              print("\n")
              current_line = @annals.buffer[index]
              File.open(current_line[:file], 'r') do |file|
                data = file.readlines
                current = current_line[:line]
                min     = [0, current - (@annals.max / 2)].max
                max     = [current + (@annals.max / 2), data.length].min
                min.upto(current - 1) do |line|
                  print_line("#{line}  #{data[line].rstrip}")
                end
                yellow_line("#{current}  #{data[current].rstrip}")
                (current + 1).upto(max - 1) do |line|
                  print_line("#{line}  #{data[line].rstrip}")
                end
              end
              print("\n")
            }
          }
        else
          red_line("#{choice} is not a valid backtrace line, please try again.")
        end
      else
        red_line("#{choice} is not a valid choice, please try again.")
      end
      red_line("- #{full_description}")
      prompt(&block)
    end

    def red_line(content)
      print_line(content, "\e[31m")
    end

    def tests(description, tags = [], &block)
      @tag_stack.push([*tags])
      @befores.push([])
      @afters.push([])

      print_line(description || 'Shindo.tests')
      if block_given?
        indent { instance_eval(&block) }
      end

      @afters.pop
      @befores.pop
      @tag_stack.pop
    end

    def test(description, tags = [], &block)
      @description_stack.push(description)
      @tag_stack.push([*tags])

      # if the test includes tags and discludes ^tags, evaluate it
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
            success = false
            file, line, method = error.backtrace.first.split(':')
            if method
              method << "in #{method[4...-1]} " # get method from "in `foo'"
            else
              method = ''
            end
            method << "! #{error.message} (#{error.class})"
            @annals.stop
            @annals.unshift(:file => file, :line => line.to_i, :method => method)
          end
          @success = @success && success
          if success
            green_line("+ #{full_description}")
          else
            red_line("- #{full_description}")
            if STDOUT.tty?
              prompt(&block)
            end
          end

          for after in @afters.flatten.compact
            after.call
          end
        else
          yellow_line("* #{full_description}")
        end
      else
        print_line("_ #{full_description}")
      end

      @tag_stack.pop
      @description_stack.pop
    end

    def yellow_line(content)
      print_line(content, "\e[33m")
    end

  end

end
