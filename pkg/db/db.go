package db

import (
	"fmt"
	"time"

	"github.com/thaitanloi365/go-rest-boilerplate/pkg/config"
	"go.uber.org/zap"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// DB instance
type DB struct {
	*gorm.DB
}

// New new
func New(config *config.Config) *DB {
	// zap, err := zap.NewProduction()
	// if err != nil {
	// 	panic(err)
	// }

	var logger = NewLogger(zap.L())
	fmt.Println("logger", logger)
	db, err := gorm.Open(postgres.Open(config.GetDatabaseURI()), &gorm.Config{
		PrepareStmt:                              true,
		DisableForeignKeyConstraintWhenMigrating: true,
		SkipDefaultTransaction:                   true,
		Logger:                                   logger,
	})
	if err != nil {
		panic(err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		panic(err)
	}

	for i := 0; i < 10; i++ {
		var err = sqlDB.Ping()
		if err == nil {
			fmt.Printf("Database %s connected success\n", config.GetDatabaseURI())
			break
		}
		fmt.Println(err)
		time.Sleep(time.Second * 2)
		fmt.Printf("Retry connect to %s %d/%d \n", config.GetDatabaseURI(), i, 10)
	}

	return &DB{
		DB: db.Debug(),
	}
}
