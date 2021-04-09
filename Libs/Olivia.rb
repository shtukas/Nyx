
# encoding: UTF-8

class Olivia

    # This class extends Nereid with a few functions it doesn't have

    # Olivia::nx19s()
    def self.nx19s()
        NereidInterface::getElements()
            .map{|element|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{NereidInterface::toString(element)}",
                    "nx15"     => {
                        "type"    => "neiredElement",
                        "payload" => element
                    }
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

            mx.item("attach".yellow, lambda { 

            })

            mx.item("detach".yellow, lambda {

            })

            mx.item("transmute".yellow, lambda { 
                FileSystemAdapter::transmute(element["uuid"])
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
