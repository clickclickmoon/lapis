
class Parser
  WHITESPACE  = /\s/      # Whitespace character (+ Line_Separator)
  LINECOMMENT = /;/       # ;; is a comment to line end
  ASTRIK      = /\*/      # A * since (* is a multiline comment *)
  OPENPAREN   = /\(/      # An open paren
  CLOSEPAREN  = /\)/      # A close paren
  OPENSQUARE  = /\[/      # An open bracket
  CLOSESQUARE = /\]/      # A close bracket
  QUOTE       = /[\"\']/  # A Double or Single quote
  REGEX       = /\|/      # A regular expression
  NUMBER      = /\d/      # Number Characters
  START_ATOM  = /[^0-9\(\)\"\'\|\[\]]/
  
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

    # pull out common code into this proc for clarity in starting cache
    proc_start_cache = ->( this_type, cache_char = true ) do
      caching = true
      cache << char if cache_char
      type = this_type
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
          i -= 1
        end

      else # not seeking
        if( caching )

        else # not caching
          if( char =~ START_ATOM )
            proc_start_cache.call( :atom )

          elsif( char =~ QUOTE )
            proc_start_cache.call( :string )
            looking = char.dup

          elsif( char =~ REGEX )
            proc_start_cache.call( :regex, false )

          elsif( char =~ NUMBER )
            proc_start_cache.call( :number )

          elsif( char=~ OPENSQUARE )
            proc_start_cache.call( :list )

          end
          
        end
        
      end
      
      i += 1
    end
  end
end

