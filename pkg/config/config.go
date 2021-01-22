package config

import "fmt"

// Config config
type Config struct {
	// Database
	DBName     string `mapstructure:"DB_NAME" json:"db_name"`
	DBUser     string `mapstructure:"DB_USER" json:"db_user"`
	DBPassword string `mapstructure:"DB_PASSWORD" json:"db_password"`
	DBPort     string `mapstructure:"DB_PORT" json:"db_port"`
	DBHost     string `mapstructure:"DB_HOST" json:"db_host"`
	DBURI      string `mapstructure:"DB_URI" json:"db_uri"`
	DBSSLMode  string `mapstructure:"DB_SSL_MODE" json:"db_sslmode"`
}

// GetDatabaseURI get full uri
func (c Config) GetDatabaseURI() string {
	var dbHost = c.DBHost
	var dbPort = c.DBPort
	var dbName = c.DBName
	var dbUser = c.DBUser
	var dbPassword = c.DBPassword
	var dbSSLMode = c.DBSSLMode

	var dbURI = fmt.Sprintf("host=%s port=%s user=%s dbname=%s password=%s sslmode=%s", dbHost, dbPort, dbUser, dbName, dbPassword, dbSSLMode)

	return dbURI
}
