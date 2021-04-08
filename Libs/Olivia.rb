
# encoding: UTF-8

class Olivia

    # This class extends Nereid with a few functions it doesn't have

    # Olivia::nyxSearchItems()
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

    # Olivia::landing(element)
    def self.landing(element)

        loop {

            puts "-- Olivia -----------------------------"

            element = NereidInterface::getElementOrNull(element["uuid"]) # could have been deleted or transmuted in the previous loop
            return if element.nil?

            puts "[nyx] #{NereidInterface::toString(element)}".green

            puts "uuid: #{element["uuid"]}".yellow
            puts "payload: #{element["payload"]}".yellow

            puts ""

            mx = LCoreMenuItemsNX1.new()

            Links::getLinkedObjectsInTimeOrder(element).each{|node|
                mx.item("related: #{Patricia::toString(node)}", lambda { 
                    Patricia::landing(node)
                })
            }

            puts ""

            mx.item("access".yellow, lambda { 
                NereidInterface::access(element)
            })

            mx.item("update/set description".yellow, lambda {
                description = Utils::editTextSynchronously(element["description"])
                return if description == ""
                element["description"] = description
                NereidInterface::commitElement(element)
            })

            mx.item("link to architectured node".yellow, lambda { 
                node = Patricia::achitectureNodeOrNull()
                return if node.nil?
                Links::linkObjectsDirectionaly(element, node)
            })

            mx.item("unlink".yellow, lambda {
                node = Links::selectOneOfTheLinkedNodeOrNull(element)
                return if node.nil?
                Links::unlinkObjects(element, node)
            })

            mx.item("reshape: select connected items -> move to architectured navigation node".yellow, lambda {

                nodes, _ = LucilleCore::selectZeroOrMore("connected", [], Links::getLinkedObjectsInTimeOrder(element), lambda{ |n| Patricia::toString(n) })
                return if nodes.empty?

                node2 = Patricia::achitectureNodeOrNull()
                return if node2.nil?

                return if nodes.any?{|node| node["uuid"] == node2["uuid"] }

                Links::reshapeDirectionaly(element, nodes, node2)
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
