# -*- encoding: utf-8 -*-

require 'lapis.rb'

test_string = Array.new

test_string << %q{(test)}
test_string << %q{( Test )  }
test_string << %q{(AVle )}
test_string << %q{( asdf3)}
test_string << %q{ (   $  )  }
test_string << %q{ (a)}
test_string << %q{ (λ)}
test_string << %q{ ()}
test_string << %q{ ( )}
test_string << %q{ ( a b c )}
test_string << %q{ ("λ")}
test_string << %q{ ("")}
test_string << %q{ ( "\"\"" )}
test_string << %q{ ( a "b " c )}
test_string << %q{ ('λ')}
test_string << %q{ ('')}
test_string << %q{ ( '\'\'' )}
test_string << %q{ ( a '"b" ' c )}
test_string << %q{ ("/λ")}
test_string << %q{ (//)}
test_string << %q{ ( /[^0-9]/ )}
test_string << %q{ ( a /b / c )}
test_string << %q{ ("536")}
test_string << %q{ ( "2\"\"" )}
test_string << %q{ ( a "b " c 2 4)}
test_string << %q{ ('5.3')}
test_string << %q{ (1)}
test_string << %q{ ( /1234/ )}
test_string << %q{ ( 1.2 3 4 5 )}
test_string << %q{ ("/λ" 12)}
test_string << %q{ (// 1.1)}
test_string << %q{ ( /[^0-9]/ )}
test_string << %q{ ( a /b / c )}

test_string << %q{ (1 (5))}
test_string << %q{ ( /1234/ ( 123 "abc") )}
test_string << %q{ ( 1.2 3 4 5 ( 6 ( 7 ( 8 ))))}
test_string << %q{ (("/λ" 12))}
test_string << %q{ (// 1.1 ())}

#parser = Lapis::Parser.new
#test_string.each do |string|
#    puts "string: " + string
#    puts parser.parse( string ).inspect
#end

lapis = Lapis::Interpreter.new
lapis.repl
