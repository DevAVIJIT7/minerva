# frozen_string_literal: true

# Copyright 2018 ACT, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#         limitations under the License.

module Minerva
  module Search
    class Parser < Parslet::Parser
      rule(:operator) { (str('>=') | str('<=') | str('!=') | str('=') | str('>') | str('<') | str('~')).as(:operator) }
      rule(:cond_operator) { (str('AND') | str('OR') | str('&&') | str('||')).as(:cond_operator) }
      rule(:term) { match("[\-a-zA-Z0-9\_\.\s\,\/\:&]").repeat(1).as(:term) }
      rule(:quote) { str("'") | str('"') }
      rule(:lparen) { str('(') }
      rule(:rparen) { str(')') }
      rule(:phrase) { (quote >> (term >> space?).repeat >> quote).as(:phrase) }
      rule(:field) { ((term >> space?).repeat >> operator).as(:field) }
      rule(:clause) { (space? >> lparen.repeat(0).as(:lparen) >> space? >> field >> space? >> operator.maybe >> space? >> phrase >> space? >> rparen.repeat(0).as(:rparen)).as(:clause) }
      rule(:space) { match('\s').repeat(1) }
      rule(:space?) { space.maybe }
      rule(:factor) { clause | lparen >> expression.as(:expression) >> rparen }
      rule(:expression) { factor >> (space? >> cond_operator >> space? >> factor).repeat(0) }

      root :expression
    end
  end
end
