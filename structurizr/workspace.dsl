workspace "Toy Preorder Lottery Service" "C4 Workshop" {

    model {
        buyer = person "Buyer" "A consumer who wants to preorder popular toys and registers through the agent's real-name app."
        operator = person "Operator" "The agent's operations staff, who set each campaign's period and the total number of toys each buyer may enter for."

        preorderSystem = softwareSystem "Preorder Lottery System" "Lets buyers register for the toys they want, draws the winners when registration closes, and lets winners choose a pickup store." {
            adminWeb = container "Admin Web" "Lets operators set a campaign's period, each buyer's total entry limit, the toys open for registration and the pickup stores." "React / Web browser"
            preorderApi = container "Preorder API" "Receives registrations and pickup-store choices forwarded by the real-name app, and lets the admin web read and write campaign settings." "Node.js / Express REST API" {
                authGuard = component "Credential Guard" "Verifies the real-name credential issued by the real-name app (signature and expiry) and rejects buyer requests that fail." "TypeScript Middleware"
                campaignService = component "Campaign Rules Service" "Manages preorder campaigns and checks the campaign period and each buyer's total entry limit." "TypeScript Service"
                registrationService = component "Registration Service" "Accepts a buyer's registration for the toys they want, applies the campaign rules before saving it, and serves result queries." "TypeScript Service"
                pickupService = component "Pickup Service" "Lets winning buyers choose a pickup store and sends the winner list and pickup stores to the store pickup system." "TypeScript Service"
            }
            lotteryJob = container "Lottery Job" "When a campaign closes, reads all registrations, draws winners by the rules, saves the results, and asks the real-name app to push notifications." "Node.js / scheduled job"
            preorderDb = container "Preorder Database" "Stores campaign settings, buyer registrations, lottery results and pickup stores." "PostgreSQL"
        }
        realnameApp = softwareSystem "Agent Real-name App" "The agent's existing app where buyers log in and complete real-name verification; the registration entry point and result push notifications both reuse it." "External System"
        storeSystem = softwareSystem "Store Pickup System" "The agent's existing store system, which checks the winner list and pickup store and hands over the goods." "External System"

        buyer -> realnameApp "Registers, views results and chooses a pickup store in the app"
        realnameApp -> authGuard "Forwards preorder requests (with the real-name credential)" "HTTPS"
        authGuard -> registrationService "Forwards registrations and result queries once the credential passes"
        authGuard -> pickupService "Forwards pickup-store choices once the credential passes"
        registrationService -> campaignService "Looks up the campaign period and per-buyer entry limit"
        pickupService -> campaignService "Looks up the available pickup stores"
        operator -> adminWeb "Sets up preorder campaigns and lottery rules"
        adminWeb -> campaignService "Reads and writes campaign settings" "HTTPS"
        campaignService -> preorderDb "Reads and writes campaign settings" "SQL"
        registrationService -> preorderDb "Saves registrations and reads lottery results" "SQL"
        pickupService -> preorderDb "Saves pickup stores" "SQL"
        pickupService -> storeSystem "Sends the winner list and pickup stores" "HTTPS"
        lotteryJob -> preorderDb "Reads registrations and writes lottery results" "SQL"
        lotteryJob -> realnameApp "Asks the app to push the lottery results" "HTTPS"
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
        container preorderSystem "Containers" {
            include *
            include buyer
            autoLayout lr
        }
        component preorderApi "Components" {
            include *
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
