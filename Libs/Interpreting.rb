# encoding: UTF-8

# This original of this is in Catalyst

=begin

Interpreting::tokenizer
    Takes a string and decompose it in tokens. 
    Tokens are separated by spaces unless within a double quoted string.

Usage:

    puts "select / expose / start / done (<n>) | no work today | new wave / calendar item / quark / todo / work item / project | anniversaries | calendar | waves | agents | numbers on/off".yellow

    command = LucilleCore::askQuestionAnswerAsString("> ")

    break if command == ""

    if (indx = Interpreting::readAsIntegerOrNull(command)) then
        item = projectItems[indx]
        next if item.nil?
        ProjectItems::landing(item)
    end

    if Interpreting::match("select *", command) then
        _, ordinal = Interpreting::tokenizer(command)
        ordinal = ordinal.to_i
        item = items[ordinal]
        next if item.nil?
        next if item["access"].nil?
        item["access"].call()
    end

=end

class Interpreting

    # Interpreting::decomposeInFirstTokenAndRest(str: String): [token: String, nil | rest: String]
    def self.decomposeInFirstTokenAndRest(str)
        str = str.strip
        raise "[error: f13e30b4-c452-4560]" if str == ""
        if str.start_with?('"') then
            str = str[1, str.length]
            buffer = ""
            loop {
                if str == "" then
                    return [buffer, nil]
                end
                if str.start_with?('"') then
                    str = str[1, str.length]
                    if str == "" then
                        str = nil
                    end
                    return [buffer, str]
                end
                buffer = buffer + str[0]
                str = str[1, str.length]
            }
            
        else
            pos = str.index(" ")
            if pos then
                return [str[0, pos].strip, str[pos, str.length].strip]
            else
                return [str, nil]
            end
        end
    end

    # Interpreting::tokenizerCore(tokens, rest)
    def self.tokenizerCore(tokens, rest)
        if rest.nil? then
            return tokens
        end
        first, rest = Interpreting::decomposeInFirstTokenAndRest(rest)
        tokens = tokens + [first]
        Interpreting::tokenizerCore(tokens, rest)
    end

    # Interpreting::tokenizer(str: String) # Array[String]
    def self.tokenizer(str)
        return [] if str.strip == ""
        Interpreting::tokenizerCore([], str)
    end

    # Interpreting::tokensMatch(matchers, tokens)
    def self.tokensMatch(matchers, tokens)
        return false if matchers.size != tokens.size
        return true if matchers.size == 0
        if matchers[0] == "*" then
            return Interpreting::tokensMatch(matchers[1, 999], tokens[1, 999])
        else
            if matchers[0] == tokens[0] then
                return Interpreting::tokensMatch(matchers[1, 999], tokens[1, 999])    
            else
                return false
            end
        end
    end

    # -----------------------------------------------------------

    # Interpreting::readAsIntegerOrNull(command)
    def self.readAsIntegerOrNull(command)
        if command.to_i.to_s == command then
            return command.to_i
        end
        nil
    end

    # Interpreting::match(pattern, command)
    # Example: Interpreting::match("set * *", "set key value")
    def self.match(pattern, command)
        matchers = Interpreting::tokenizer(pattern)
        tokens = Interpreting::tokenizer(command)
        Interpreting::tokensMatch(matchers, tokens)
    end
end
