package main

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/thaitanloi365/go-rest-boilerplate/pkg/config"
	"github.com/thaitanloi365/go-rest-boilerplate/pkg/db"
)

type User struct {
	Name string `json:"name"`
}

// serveCmd represents the serve command
var serveCmd = &cobra.Command{
	Use:   "serve",
	Short: "start http server with configured api",
	Long:  `Starts a http server and serves the configured api`,
	Run: func(cmd *cobra.Command, args []string) {
		var db = db.New(&config.Config{
			DBName:     "postgres",
			DBUser:     "postgres",
			DBPassword: "",
			DBPort:     "5432",
			DBHost:     "localhost",
			DBSSLMode:  "disable",
		})

		db.AutoMigrate(&User{})

		for i := 0; i < 10; i++ {
			var user = User{
				Name: fmt.Sprintf("User %d", i),
			}
			var err = db.Debug().Create(&user).Error
			if err != nil {

			}

		}
	},
}

func init() {
	RootCmd.AddCommand(serveCmd)
}
