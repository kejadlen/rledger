# frozen_string_literal: true

require_relative "rledger/version"

require "parslet"

module RLedger
  # It would probably make more sense to use the actual library[^1], but I'm
  # more familiar with Parslet than Haskell
  #
  # [^1]: https://github.com/simonmichael/hledger/blob/master/hledger-lib/Hledger/Read/JournalReader.hs
  class Parser < Parslet::Parser
    rule(:ws) { match['\s'].repeat(1) }
    rule(:ws?) { ws.maybe }
    rule(:eol) { str("\n") }
    rule(:comment) { str(";") >> (eol.absent? >> any).repeat.as(:comment) }

    root(:journal)

    rule(:journal) {
      (commodity.as(:commodity) | transaction.as(:transaction) | eol).repeat
    }

    # Transactions

    # Each transaction is recorded as a journal entry, beginning with a simple
    # date in column 0. This can be followed by any of the following optional
    # fields, separated by spaces:

    # - a status character (empty, !, or *)
    # - a code (any short number or text, enclosed in parentheses)
    # - a description (any remaining text until end of line or a semicolon)
    # - a comment (any remaining text following a semicolon until end of line,
    #   and any following indented lines beginning with a semicolon)
    # - 0 or more indented posting lines, describing what was transferred and
    #   the accounts involved (indented comment lines are also allowed, but not
    #    lines or non-indented lines).

    rule(:transaction) {
      simple_date.as(:date) >>
      (ws >> (str(";").absent? >> eol.absent? >> any).repeat.as(:description)).maybe >>
      comment.maybe >>
      eol >>
      (ws >> (comment >> eol | posting.as(:posting))).repeat
    }

    # Simple dates

    # Dates in the journal file use simple dates format: YYYY-MM-DD or YYYY/MM/DD
    # or YYYY.MM.DD, with leading zeros optional. The year may be omitted, in
    # which case it will be inferred from the context: the current transaction,
    # the default year set with a default year directive, or the current date
    # when the command is run.

    rule(:simple_date) {
      (year >> str("-")).maybe >> month >> str("-") >> day |
      (year >> str("/")).maybe >> month >> str("/") >> day |
      (year >> str(".")).maybe >> month >> str(".") >> day
    }
    rule(:year) { match('\d').repeat(4, 4) }
    rule(:month) { str("0").maybe >> match["1-9"] | str("1") >> match["0-2"] }
    rule(:day) {
      str("3") >> match["0-1"] |
      match["1-2"] >> match["0-9"] |
      str("0").maybe >> match["1-9"]
    }

    # Postings

    # A posting is an addition of some amount to, or removal of some amount
    # from, an account. Each posting line begins with at least one space or tab
    # (2 or 4 spaces is common), followed by:

    # - (optional) a status character (empty, !, or *), followed by a space
    # - (required) an account name (any text, optionally containing single
    #   spaces, until end of line or a double space)
    # - (optional) two or more spaces or tabs followed by an amount.

    rule(:posting) {
      (str("  ").absent? >> eol.absent? >> any).repeat(1).as(:account_name) >>
      (
        str("  ") >> ws? >>
        (str(";").absent? >> eol.absent? >> any).repeat.as(:amount) >>
        comment.maybe
      ).maybe >>
      eol
    }

    # A commodity directive is just the word commodity followed by a sample
    # amount

    rule(:commodity) {
      str("commodity") >> ws >> (eol.absent? >> any).repeat >> eol
    }
  end
end
