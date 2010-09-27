#!/usr/bin/ruby
# -*- coding: utf-8 -*- Lapis Language Ruby Module
# Andy Brown <neorab@gmail.com> [April, 12, 2010]

### Ruby Class Extensions for Lapis
class Object
  def _lapis_eval( scope, forms ); self; end
end

class Symbol
  def _lapis_eval( scope, forms ); scope.lookup( self ); end
end

class Array
  def _lapis_eval( scope, forms )
    Lapis::List.new( self )._lapis_eval( scope, forms )
  end
end

module Lapis

  DEFAULTS = {
    :nil => :nil,
    :t => :t,
    :+ => lambda{ |x, y| x + y },
    :- => lambda{ |x, y| x - y },
    :* => lambda{ |x, y| x * y },
    :"/" => lambda{ |x, y| x / y },
    :car => lambda{ |x| x.car },
    :cdr => lambda{ |x| x.cdr },
    :atom? => lambda{ |x| (x.kind_of?(List) ? :nil : :t) },
    :eq? => lambda{ |x, y| (x.equal?( y ) ? :t : :nil) },
    :list => lambda{ |*args| List.new( args ) },
    :puts => lambda{ |*args| puts( *args ); nil }
  }
  
  
  FORMS = {}
  
  
  class Interpreter
    def initialize( defaults = DEFAULTS, forms = FORMS )
      @top_scope = Scope.new( nil, defaults )
      @spc_forms = Scope.new( nil, forms )
      @parser = Parser.new
    end
    
    def eval( string )
      exps = List.new( @parser.parse( string ) )
      exps._lapis_eval( @top_scope, @spc_forms )
    end

    def repl
      print "> "
      STDIN.each_line do |line|
        begin
          puts self.eval( line ).inspect
        rescue StandardError => e
          puts "ERROR: #{e}"
          if( $DEBUG )
            puts "BACKTRACE:"
            e.backtrace.each do |bt|
              puts "\t#{bt}"
            end
          end
        end
        print "> "
      end
    end
  end


  class List
    def initialize( lapis_array )
      @_list = lapis_array
    end

    def _lapis_eval( scope, forms )
      unless( forms.nil? )
        return forms.lookup( car ).call( scope, forms, *cdr ) if forms.defined?( car )
      end
      func = car._lapis_eval( scope, forms )
      return func.call( *( cdr.map{ |x| x._lapis_eval( scope, forms ) } ) )
    end

    def car; @_list[0]; end
    def cdr; ( @_list.size == 1 ? nil : @_list[1..-1] ); end
  end
  

  class Scope
    def initialize( parent = nil, defaults = {} )
      @parent, @defines = parent, defaults
    end

    def define( symbol, value )
      @defines[symbol] = value
    end

    def defined?( symbol )
      return true  if( @defines.has_key?( symbol ) )
      return false if( @parent.nil? )
      return @parent.defined?( symbol )
    end

    def lookup( symbol )
      return @defines[symbol] if( @defines.has_key?( symbol ) )
      raise "lookup on undefined symbol #{symbol}" if( @parent.nil? )
      return @parent.lookup( symbol )
    end

    def set( symbol, value )
      return @defines[symbol] = value if( @defines.has_key?( symbol ) )
      raise "set on undefined symbol #{symbol}" if( @parent.nil? )
      return @parent.set( symbol, value )
    end
  end
  
class Parser
  WHITESPACE  = /\s/      # Whitespace character (+ Line_Separator)
  ASTRIK      = /\*/      # A * since (* is a multiline comment *)
  OPENPAREN   = /\(/      # An open paren
  CLOSEPAREN  = /\)/      # A close paren
  OPENSQUARE  = /\[/      # An open bracket
  CLOSESQUARE = /\]/      # A close bracket
  QUOTE       = /[\"\']/  # A Double or Single quote
  REGEX       = /\|/      # A regular expression
  NUMBER      = /\d/      # Number Characters
  START_ATOM  = /[^0-9\(\)\"\'\|\[\]\s]/
  
  def initialize
  end
  
  def Parser.parse( input )
    parser = Parser.new
    return parser.parse( input )
  end
  
  def parse( input )
    seeking = true       # We are looking for the first token
    caching = false      # We are building a token
    i       = 0          # Loop Iterator
    cache   = String.new # This is the cache for our reading
    result  = Array.new  # This will be our return
    curtype = nil        # What are we caching?
    looking = nil        # In case we are looking for a special char
    comment = 0          # Level that we are currently nested in comments

    # pull out common code into this proc for clarity in starting cache
    proc_start_cache = ->( this_type, cache_char = nil ) do
      caching = true
      cache << cache_char unless cache_char.nil?
      curtype = this_type
    end

    proc_reset_cache = ->( to_result ) do
      caching = false
      result << to_result
      cache = ""
      curtype = nil
      looking = nil
    end

    # Remove newlines (treat as whitespace)
    input.gsub!( "\n", " " )
    input.gsub!( "\r", " " )

    while( i < input.length )
      char = input[i]

      if( seeking )
        # Basically we are just eating whitespace
        unless( char =~ WHITESPACE )
          seeking = false
          if( char =~ OPENPAREN and input[i+1] =~ ASTRIK )
            i -= 1
          end
        end

      else # not seeking

        if( caching )

          if( curtype == :atom )
            if( char =~ CLOSESQUARE || char =~ WHITESPACE || char =~ OPENSQUARE or ( char =~ OPENPAREN and input[i+1] =~ ASTRIK ) )
              proc_reset_cache.call( cache.dup.to_sym )
              i -= 1 if( char =~ OPENSQUARE || char =~ OPENPAREN ) # roll back one so we don't miss the bracket
            else
              cache << char
            end

          elsif( curtype == :string )
            if( char == looking )
              unless( input[i-1] == "\\" )
                proc_reset_cache.call( cache.dup )
              else
                cache << char
              end
            else
              cache << char
            end

          elsif( curtype == :regex )
            if( char =~ REGEX )
              unless( input[i - 1] == "\\" )
                proc_reset_cache.call( Regexp.new( cache.dup ) )
              else
                cache << char
              end
            else
              cache << char
            end

          elsif( curtype == :number )
            if( char =~ CLOSESQUARE || char =~ WHITESPACE || char =~ OPENSQUARE )
              proc_reset_cache.call( cache.dup.to_f )
              i -= 1 if( char =~ OPENSQUARE ) # roll back one so we don't miss the bracket
            else
              cache << char
            end

          elsif( curtype == :list )
            cache << char
            if( char =~ CLOSESQUARE )
              proc_reset_cache.call( parse( cache ) )
            end

          elsif( curtype == :comment )
            if( char =~ ASTRIK and input[i-1] =~ OPENPAREN )
              comment += 1
            elsif( char =~ CLOSEPAREN and input[i-1] =~ ASTRIK )
              comment -= 1
              if( comment == 0 )
                caching = false
                curtype = nil
              end
            end

          end

        else # not caching

          if( char =~ START_ATOM )
            proc_start_cache.call( :atom, char )

          elsif( char =~ QUOTE )
            proc_start_cache.call( :string )
            looking = char.dup

          elsif( char =~ REGEX )
            proc_start_cache.call( :regex )

          elsif( char =~ NUMBER )
            proc_start_cache.call( :number, char )

          elsif( char =~ OPENSQUARE )
            proc_start_cache.call( :list, char )

          elsif( char =~ OPENPAREN and input[i+1] =~ ASTRIK )
            proc_start_cache.call( :comment )
            comment += 1
            i += 1 # eat the ASTRIK

          end
          
        end
        
      end
      
      i += 1
    end
    
    return result
  end
end

end
