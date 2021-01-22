package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

// RootCmd root command
var RootCmd = &cobra.Command{
	Use:   "Go REST Boilerplate",
	Short: "Go REST Boilerplate",
}

var cfgFile string
var pwd string

// Execute Execute root command
func Execute() {
	if err := RootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}

func init() {
	dir, err := os.Getwd()
	if err != nil {
		panic(err)
	}
	pwd = dir

	RootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", fmt.Sprintf("config file (default is %s/%s.yaml)", dir, "config"))
}
