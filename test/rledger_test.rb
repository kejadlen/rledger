# frozen_string_literal: true

require "test_helper"

class RLedgerTest < Minitest::Test
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

    RLedger::Parser.new.journal.parse(journal)
    RLedger::Parser.new.parse(journal)
  end

  def test_transaction
    parsed = RLedger::Parser.new.transaction.parse(TRANSACTIONS[0])
    assert_equal "2008/01/01", parsed[0][:date]
    assert_equal "income", parsed[0][:description]
    assert_equal "assets:bank:checking", parsed[1][:posting][:account_name]
    assert_equal "$1", parsed[1][:posting][:amount]
    assert_equal "income:salary", parsed[2][:posting][:account_name]
    assert_equal "$-1", parsed[2][:posting][:amount]

    parsed = RLedger::Parser.new.transaction.parse(TRANSACTIONS[1])
    assert_equal "2012/5/14", parsed[0][:date]
    assert_equal "something  ", parsed[0][:description]
    assert_equal " a transaction comment", parsed[0][:comment]
    assert_equal " the transaction comment, continued", parsed[1][:comment]
    assert_equal "posting1", parsed[2][:posting][:account_name]
    assert_equal "1  ", parsed[2][:posting][:amount]
    assert_equal " a comment for posting 1", parsed[2][:posting][:comment]
    assert_equal "posting2", parsed[3][:posting][:account_name]
    assert_nil parsed[3][:posting][:amount]
    assert_nil parsed[3][:posting][:comment]
    assert_equal " a comment for posting 2", parsed[4][:comment]
    assert_equal " another comment line for posting 2", parsed[5][:comment]
  end

  def test_simple_date
    RLedger::Parser.new.simple_date.parse("2010-01-31")
    RLedger::Parser.new.simple_date.parse("2010/01/31")
    RLedger::Parser.new.simple_date.parse("2010.01.31")
    RLedger::Parser.new.simple_date.parse("1/31")
    RLedger::Parser.new.simple_date.parse("2012/5/14")
  end

  def test_posting
    parsed = RLedger::Parser.new.posting.parse("assets:bank:checking   $1\n")
    assert_equal "assets:bank:checking", parsed[:account_name]
    assert_equal "$1", parsed[:amount]

    parsed = RLedger::Parser.new.posting.parse("income:salary         $-1\n")
    assert_equal "income:salary", parsed[:account_name]
    assert_equal "$-1", parsed[:amount]
  end

  def test_commodity
    RLedger::Parser.new.commodity.parse("commodity $1000.00\n")
  end
end
