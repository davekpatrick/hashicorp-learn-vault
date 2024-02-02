// BOF
package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/google/uuid"

	vault "github.com/hashicorp/vault/api"
)

var version = "0.1.0"

func main() {
	fmt.Println("Hello, World! [" + version + "]")
	//info, _ := debug.ReadBuildInfo()
	//fmt.Println(info)
	//
	// vault variables
	secretEngineName := "secret"
	secretPath := "hello/world"
	// Client configuration
	config := vault.DefaultConfig()
	config.Address = os.Getenv("VAULT_HELLOWORLD_ADDR") // "http://127.0.0.1:8200"
	// Create a new client
	client, err := vault.NewClient(config)
	if err != nil {
		log.Fatalf("unable to initialize Vault client: %v", err)
	}
	// Authenticate with Vault
	client.SetToken(os.Getenv("VAULT_HELLOWORLD_TOKEN")) // the super secret VAULT_TOKEN environment variable

	// Create a secret
	token := uuid.New()
	secretData := map[string]interface{}{
		"token": token.String(),
	}
	// Create a context
	context := context.Background()
	// variable to hold the returned secret data
	var returnedSecret *vault.KVSecret
	// Write a secret
	returnedSecret, err = client.KVv2(secretEngineName).Put(context, secretPath, secretData)
	if err != nil {
		log.Fatalf("unable to write data: %v", err)
	}
	log.Printf("data written successfully to %q", secretPath)
	// Read a secret
	returnedSecret, err = client.KVv2(secretEngineName).Get(context, secretPath)
	if err != nil {
		log.Fatalf("unable to read data: %v", err)
	}
	// Check if the data exists and is not empty
	returnedSecretValue, ok := returnedSecret.Data["token"].(string)
	if !ok {
		log.Fatalf("value type assertion failed: %T %#v", returnedSecret.Data["token"], returnedSecret.Data["token"])
	}
	// Check if the data value is the same as the one we wrote
	if returnedSecretValue != token.String() {
		log.Fatalf("unexpected token value %q retrieved from vault", returnedSecretValue)
	}
	// all good
	log.Println("Good Bye!")
}

// EOF
