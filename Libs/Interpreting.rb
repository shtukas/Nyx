# encoding: UTF-8

=begin

Interpreting::tokenizer
    Takes a string and decompose it in tokens. 
    Tokens are separated by spaces unless within a double quoted string.

action: (commandPattern: String, usage: String, lambda(context:Object, command: String): ActionStatus)
actions: Array[action]

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

    # Interpreting::interpreter(context, actions, config)
    def self.interpreter(context, actions, config)
        defaultConfig = {}
        defaultConfig["displayHelpInLineAtIntialization"] = false
        config = defaultConfig.merge(config)

        if config["displayHelpInLineAtIntialization"] then
            puts actions.map{|action| action[1]}.join(" | ").yellow
            puts ""
        end

        command = LucilleCore::askQuestionAnswerAsString("> ")
        if command == "help" then
            puts actions.map{|action| action[1]}.join("\n")
            LucilleCore::pressEnterToContinue()
            return
        end
        action = actions
                .select{|action|
                    Interpreting::tokensMatch(Interpreting::tokenizer(action[0]), Interpreting::tokenizer(command))   
                }
                .first
        return if action.nil?
        action[2].call(context, command) 
    end
end

