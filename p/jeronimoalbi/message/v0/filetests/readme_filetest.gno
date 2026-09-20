package main

import "gno.land/p/jeronimoalbi/message/v0"

func main() {
	broker := message.NewBroker()

	// Subscribe to an event
	subID, err := broker.Subscribe("EventName", func(msg message.Message) {
		println("EventName has been triggered:", msg.Data.(string))
	})
	if err != nil {
		panic(err)
	}

	// Publish an event
	err = broker.Publish("EventName", "Example event data")
	if err != nil {
		panic(err)
	}

	// Unsubscribe from the event
	unsubscribed, err := broker.Unsubscribe("EventName", subID)
	if err != nil {
		panic(err)
	}

	if !unsubscribed {
		panic("subscription not found")
	}

	// Nothing is triggered after unsubscribing
	err = broker.Publish("EventName", "Ignored event data")
	if err != nil {
		panic(err)
	}
}

// Output:
// EventName has been triggered: Example event data
