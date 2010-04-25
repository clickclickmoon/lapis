#!/usr/bin/ruby
# encoding: utf-8 - Lapis Language Ruby Module
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
    :quote => lambda{ |*args| puts( *args ); nil }
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
    COMMENT     = /;;.*$/   # ;; starts a comment and it lasts to end of line
    WHITESPACE  = /\s/      # Whitespace character (+ Line_Separator)
    OPENPAREN   = /\(/      # An open paren
    CLOSEPAREN  = /\)/      # A close paren
    QUOTE       = /[\"\']/  # A Double or Single quote
    REGEX       = /\|/      # A regular expression
    NUMBER      = /\d/      # Number Characters
    START_ATOM  = /[^0-9\(\)\"\'\|]/
        
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
      type    = nil        # What are we caching?
      looking = nil        # In case we are looking for a special char
      
      # Remove Comments, along with Unix and Windows newlines
      input.gsub!( COMMENT, " " )
      input.gsub!( "\n", " ")
      input.gsub!( "\r", " ")
      
      while( i < input.length )
        char = input[i]
        if( seeking )
          unless( char =~ WHITESPACE )
            if( char =~ OPENPAREN )
              seeking = false
            end
          end
        else
          
          if( caching )
            if( type == :atom )
              if( char =~ CLOSEPAREN || char =~ WHITESPACE || char =~ OPENPAREN )
                caching = false
                result << cache.dup.to_sym
                cache = String.new
                type = nil
                i -= 1 if( char =~ OPENPAREN ) # roll back one so we don't miss the paren
              else
                cache << char
              end
              
            elsif( type == :string )
              if( char == looking )
                unless( input[i - 1] == "\\" )
                  caching = false
                  result << cache.dup
                  cache = String.new
                  type = nil
                  looking = nil
                else
                  cache << char
                end
              else
                cache << char
              end
              
            elsif( type == :regex )
              if( char =~ REGEX )
                unless( input[i - 1] == "\\" )
                  caching = false
                  result << Regexp.new( cache.dup )
                  cache = String.new
                  type = nil
                  looking = nil
                else
                  cache << char
                end
              else
                cache << char
              end
              
            elsif( type == :number )
              if( char =~ CLOSEPAREN || char =~ WHITESPACE || char =~ OPENPAREN )
                caching = false
                result << cache.dup.to_f
                cache = String.new
                type = nil
                i -= 1 if( char =~ OPENPAREN ) # roll back one so we don't miss the paren
              else
                cache << char
              end
              
            elsif( type == :list )
              cache << char
              if( char =~ CLOSEPAREN )
                caching = false
                result << parse( cache )
                cache = String.new
                type = nil
              end
            end
            
            
          else # (not caching)
            unless( char =~ WHITESPACE )
              if( char =~ START_ATOM )
                caching = true
                cache << char
                type = :atom
              elsif( char =~ QUOTE )
                caching = true
                type = :string
                looking = char.dup
              elsif( char =~ REGEX )
                caching = true
                type = :regex
              elsif( char =~ NUMBER )
                caching = true
                cache << char
                type = :number
              elsif( char=~ OPENPAREN )
                caching = true
                cache << char
                type = :list
              end
            end
          end
        end
        
        i += 1
      end
      
      return result
    end
  end
end
