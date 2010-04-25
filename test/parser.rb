require_relative '../lapis.rb'
require 'test/unit'

class TestParser < Test::Unit::TestCase

  def setup
    @parser = Lapis::Parser.new
  end

  def run_test_pair( lapis, array )
    a1 = @parser.parse( lapis )
    a2 = Lapis::Parser.parse( lapis ) 
    assert_kind_of( Array, a1, "Parser#parse should return an Array" )
    assert_kind_of( Array, a2, "Parser.parse should return an Array" )
    assert_equal(   a1,    a2, "Parser#parser should equal Parser.parse" )
    assert_equal(   array, a1, "Parser#parse should match given array" )
    assert_equal(   array, a2, "Parser.parse should match given array" )
  end

  INTEGER_TESTS = 
    [["(1 2 3 4 5 6 7 8 9 0)", [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]],
     ["(1)", [1]],
     ["(2)", [2]],
     ["(3)", [3]],
     ["(4)", [4]],
     ["(5)", [5]],
     ["(6)", [6]],
     ["(7)", [7]],
     ["(8)", [8]],
     ["(9)", [9]],
     ["(0)", [0]],
     ["(1 (2 (3 (4 (5 (6 (7 (8 (9 (0))))))))))", [1, [2, [3, [4, [5, [6, [7, [8, [9, [0]]]]]]]]]]],
     ["(1( 3) 4 )", [1, [3], 4]]
    ]

  FLOAT_TESTS =
    [["(1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 0.0)", [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 0.0]],
     ["(1.0( 3.0) 4.0 )", [1.0, [3.0], 4.0]],
     ["(5.09876543210987654321)", [5.09876543210987654321]],
     ["(((0.000000001)))", [[[0.000000001]]]]
    ]

  STRING_TESTS = 
    [['("simple")', ["simple"]]
    ]

  def test_INTEGER_TESTS; INTEGER_TESTS.each { |lapis, array| run_test_pair( lapis, array ) }; end
  def test_FLOAT_TESTS;   FLOAT_TESTS.each   { |lapis, array| run_test_pair( lapis, array ) }; end
  def test_STRING_TESTS;  STRING_TESTS.each  { |lapis, array| run_test_pair( lapis, array ) }; end
end
