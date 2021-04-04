
# encoding: UTF-8

class NereidNyxExt

    # This class exists to allow Nereid Elements to be landed on as elements on the Nyx ecosystem, and not as native Nereid elements

    # -------------------------------------------------------

    # NereidNyxExt::elementMatchesIdentifier(element, identifier)
    def self.elementMatchesIdentifier(element, identifier)
        return true if element["description"] == identifier
    end

    # NereidNyxExt::getElementsByIdentifier(identifier)
    def self.getElementsByIdentifier(identifier)
        NereidInterface::getElements()
            .select{|element| NereidNyxExt::elementMatchesIdentifier(element, identifier) }
    end

    # NereidNyxExt::selectElementOrNull()
    def self.selectElementOrNull()
        CatalystUtils::selectOneObjectOrNullUsingInteractiveInterface(NereidInterface::getElements(), lambda{|element| NereidInterface::toString(element) })
    end

    # NereidNyxExt::selectExistingOrMakeNewElementOrNull()
    def self.selectExistingOrMakeNewElementOrNull()
        system("clear")
        puts "NereidNyxExt::selectExistingOrMakeNewElementOrNull()"
        LucilleCore::pressEnterToContinue()
        element = NereidNyxExt::selectElementOrNull()
        return element if element
        NereidInterface::interactivelyIssueNewElementOrNull()
    end

    # NereidNyxExt::nyxSearchItems()
    def self.nyxSearchItems()
        NereidInterface::getElements()
            .map{|element|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce"     => "#{volatileuuid} #{NereidInterface::toString(element)}",
                    "payload"      => element
                }
            }
    end

    # NereidNyxExt::landing(element)
    def self.landing(element)

        loop {
            system("clear")
            element = NereidInterface::getElementOrNull(element["uuid"]) # could have been deleted or transmuted in the previous loop
            return if element.nil?

            puts "[nyx] #{NereidInterface::toString(element)}".green

            puts "uuid: #{element["uuid"]}".yellow
            puts "payload: #{element["payload"]}".yellow

            puts ""

            mx = LCoreMenuItemsNX1.new()

            Network::getLinkedObjectsInTimeOrder(element).each{|node|
                mx.item("related: #{Patricia::toString(node)}", lambda { 
                    Patricia::landing(node)
                })
            }

            puts ""

            mx.item("access".yellow, lambda { 
                NereidInterface::access(element)
            })

            mx.item("update/set description".yellow, lambda {
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                return if description == ""
                element["description"] = description
                NereidInterface::insertElement(element)
            })

            mx.item("link to architectured node".yellow, lambda { 
                node = Patricia::achitectureNodeOrNull()
                return if node.nil?
                Network::link(element, node)
            })

            mx.item("unlink".yellow, lambda {
                node = Patricia::selectOneOfTheLinkedNodeOrNull(element)
                return if node.nil?
                Network::unlink(element, node)
            })

            mx.item("reshape: select connected items -> move to architectured navigation node".yellow, lambda {

                nodes, _ = LucilleCore::selectZeroOrMore("connected", [], Network::getLinkedObjectsInTimeOrder(element), lambda{ |n| Patricia::toString(n) })
                return if nodes.empty?

                node2 = Patricia::achitectureNodeOrNull()
                return if node2.nil?

                return if nodes.any?{|node| node["uuid"] == node2["uuid"] }

                Network::reshape(element, nodes, node2)
            })

            mx.item("transmute".yellow, lambda { 
                NereidInterface::transmuteOrNull(element)
            })

            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(element)
                LucilleCore::pressEnterToContinue()
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    NereidInterface::destroyElement(element["uuid"])
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

end
