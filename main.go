package main

import (
	"log"

	"https://github.com/gofloodinc/goflood-perl-bot/config"
	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
)

func main() {
	ConfigRuntime()
	StartBot()
}

func ConfigRuntime() {
	var _ = runtime.GOMAXPROCS(config.NCPU)
	log.Printf("Running with %d CPUs\n", NCPU)
	log.Printf("BOT Interface %v - %v", Version, Build)
}

func StartBot() {
	bot, err := tgbotapi.NewBotAPI(config.KEY)
	if err != nil {
		log.Panic(err)
	}

	bot.Debug = true

	log.Printf("Authorized on account %s", bot.Self.UserName)

	u := tgbotapi.NewUpdate(0)
	u.Timeout = 60

	updates := bot.GetUpdatesChan(u)

	for update := range updates {
		if update.Message != nil { 
			log.Printf("[%s] %s", update.Message.From.UserName, update.Message.Text)

			msg := tgbotapi.NewMessage(update.Message.Chat.ID, update.Message.Text)
			msg.ReplyToMessageID = update.Message.MessageID

			bot.Send(msg)
		}
	}
}

