package db

import (
	"fmt"
	"testing"

	"github.com/thaitanloi365/go-rest-boilerplate/pkg/config"
)

type User struct {
	Name string `json:"name"`
}

func TestDB(t *testing.T) {
	var db = New(&config.Config{
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
	fmt.Println(db)
}
