#!/usr/bin/racc
# -*- encoding: utf-8 -*- Lapis Racc Parser Class
# Andy Brown <neorab@gmail.com> [April, 12, 2010]

/* This is a BNF style parser generator grammar for the
 * Lapis Language to be used by racc.  Racc is a tool
 * much like Yacc or Bison implemented for Ruby.
 *
 * Racc will parse this file and create a lapis.tab.rb
 * file that contains a Parser class with a do_parse
 * method that uses the grammar (actually the rule table
 * that is built by the racc command) to parse a Ruby
 * String into whatever you choose to build (likely an
 * expression tree).
 *
 * While Bison and Yacc both have their own lexical
 * analysis tools, Flex and Lex, racc expects the class
 * to provide a next_token method that do_parse will use
 * to feed tokens into the parser, one at a time.  See
 * the comment below (just above the ---- inner marker)
 * for more information on next_token and how racc will
 * expect to see the token list.
 *
 * To build the parser class with this file, the racc gem
 * must be present.  The built parser relies on the LGPL
 * racc runtime, which is included with Ruby since 1.8.
 *
 * While the racc parser and runtime are LGPL licensed,
 * any parser you create with it is your own and you are
 * free to license it as you please.
 *
 * This is a C-style comment to ensure that ruby does not
 * attempt to run this script on it's own and the racc
 * generator specifically allows C-style comments.  This
 * whole block is all about racc, so it seems appropriate.
 */


/* We want all Language classes to be contained inside the
 * Language module.  Thankfully racc will handle this for us.
 * Rather than Ruby's "module M; class C; ... end; end" style,
 * racc expects to see "class M::C".  Everything about this
 * file is going to be used to build this single class.
 */
class Language::Parser
    token   OPEN_PAREN      # Open Paren Token      '('
            CLOSE_PAREN     # Close Paren Token     ')'
            SYMBOL          # atoms and special characters
    
    rule
        input: /* empty */
             | input s_expression
             ;
    
        s_expression: atom
                    | lapis_list
                    ;
        
        lapis_list: OPEN_PAREN SYMBOL CLOSE_PAREN { @result << val[1] }
                  | OPEN_PAREN CLOSE_PAREN        { @result << nil }
                  ;
        
        atom: SYMBOL;
end


/* Racc does not do the actual lexical parsing on it's own, it
 * requires a function, next_token, be made available.  To do
 * this, we use the '---- inner' heading to insert some code into
 * the racc generated class.  It might seem odd have the grammar
 * side of the tools and not the lexical parser, but Ruby has
 * amazing built in support for lexical analysis with the String
 * class and regular expresions.
 *
 * We also provide parse function for us to call that will set
 * the parser up with some defaults and call the do_parse method
 * for us.  Everything after the ---- inner headline is going to
 * be inserted (via eval) into the class as is.
 *
 * The parser is going to expect the tokens as an Array pair with
 * the first part being the token (as defined in the grammar) and
 * the second element being the value, the actual string matched.
 * When we have finished parsing the entire string, we attach the
 * closing array, [false, false], to let the parser know it's done.
 */
---- inner

attr_accessor :result   ## Instance Variable to stash parser result

## This method will take a given string and split it up completely
## into the token array needed for the racc generated parser.
def make_tokens( input )
    result = []
    
    input.gsub!(/;;\n/, " ")  # Remove All Comments
    input.gsub!("\n", " ")    # Eat the newlines
    input.gsub!("\r", " ")    # and the Carrage Return
    
    while( input.length > 0 )
        if( part = input.slice!( /\A\s+/ ) )
            # do nothing (eat whitespace)
        elsif( part = input.slice!( /\A\(/ ) )
            result << [:OPEN_PAREN, nil]
        elsif( part = input.slice!( /\A\)/ ) )
            result << [:CLOSE_PAREN, nil]
        elsif( part = input.slice!( /\A[^0-9\(\)]\w*/ ) )
            result << [:SYMBOL, part]
        else
            raise "FAIL TOKEN: @#{input}\n"
        end
    end
    
    result << [false, false]
    puts result.inspect
    return result
end


def parse( str )
    @result = []
    @tokens = make_tokens( str )
    do_parse
end

def next_token
    @tokens.shift
end
