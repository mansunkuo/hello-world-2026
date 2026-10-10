workspace "Toy Preorder Lottery Service" "C4 Workshop" {

    model {
        buyer = person "Buyer" "A consumer who wants to preorder popular toys and registers through the agent's real-name app."
        operator = person "Operator" "The agent's operations staff, who set each campaign's period and the total number of toys each buyer may enter for."

        preorderSystem = softwareSystem "Preorder Lottery System" "Lets buyers register for the toys they want, draws the winners when registration closes, and lets winners choose a pickup store."
        realnameApp = softwareSystem "Agent Real-name App" "The agent's existing app where buyers log in and complete real-name verification; the registration entry point and result push notifications both reuse it." "External System"
        storeSystem = softwareSystem "Store Pickup System" "The agent's existing store system, which checks the winner list and pickup store and hands over the goods." "External System"

        buyer -> realnameApp "Registers, views results and chooses a pickup store in the app"
        realnameApp -> preorderSystem "Forwards preorder requests (already real-name verified)"
        preorderSystem -> realnameApp "Pushes lottery result notifications"
        operator -> preorderSystem "Sets up preorder campaigns and lottery rules"
        preorderSystem -> storeSystem "Sends the winner list and pickup stores"
    }

    configuration {
        scope softwaresystem
    }

    views {
        systemContext preorderSystem "SystemContext" {
            include *
            include buyer
            autoLayout lr
        }
        styles {
            element "External System" {
                background #999999
                color #ffffff
            }
        }
        theme https://raw.githubusercontent.com/structurizr/themes/master/default/theme.json
    }
}
