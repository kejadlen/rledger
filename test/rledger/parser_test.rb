# frozen_string_literal: true

require "test_helper"

require "parslet/convenience"

class ParserTest < Minitest::Test
  make_my_diffs_pretty!

  include RLedger

  TRANSACTIONS = [<<~A, <<~B]
    2008/01/01 income
      assets:bank:checking   $1
      income:salary         $-1
  A
    2012/5/14 something  ; a transaction comment
        ; the transaction comment, continued
        posting1  1  ; a comment for posting 1
        posting2
        ; a comment for posting 2
        ; another comment line for posting 2
  B

  def test_journal
    journal = ([ "commodity $1000.00\n" ] + TRANSACTIONS).join("\n")

    Parser.new.journal.parse_with_debug(journal)
    Parser.new.parse_with_debug(journal)
  end

  def test_transaction
    parsed = Parser.new.transaction.parse_with_debug(TRANSACTIONS[0])
    assert_equal [
      { date: "2008/01/01", description: "income" },
      { posting: { account_name: "assets:bank:checking", amount: "$1" } },
      { posting: { account_name: "income:salary", amount: "$-1" } },
    ], parsed

    parsed = Parser.new.transaction.parse_with_debug(TRANSACTIONS[1])
    assert_equal [
      { date: "2012/5/14", description: "something", comment: "a transaction comment" },
      { comment: "the transaction comment, continued" },
      { posting: { account_name: "posting1", amount: "1", comment: "a comment for posting 1" } },
      { posting: { account_name: "posting2" } },
      { comment: "a comment for posting 2" },
      { comment: "another comment line for posting 2" },
    ], parsed
  end

  def test_simple_date
    Parser.new.simple_date.parse_with_debug("2010-01-31")
    Parser.new.simple_date.parse_with_debug("2010/01/31")
    Parser.new.simple_date.parse_with_debug("2010.01.31")
    Parser.new.simple_date.parse_with_debug("1/31")
    Parser.new.simple_date.parse_with_debug("2012/5/14")
  end

  def test_posting
    parsed = Parser.new.posting.parse_with_debug("assets:bank:checking   $1\n")
    assert_equal "assets:bank:checking", parsed[:account_name]
    assert_equal "$1", parsed[:amount]

    parsed = Parser.new.posting.parse_with_debug("income:salary         $-1\n")
    assert_equal "income:salary", parsed[:account_name]
    assert_equal "$-1", parsed[:amount]
  end

  def test_commodity
    Parser.new.commodity.parse_with_debug("commodity $1000.00\n")
  end
end
