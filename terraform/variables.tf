# BOF
variable "namespace" {
  default = "dkp-planet-express"
}
variable "products" {
  default = {
    "bender" = {
      "name" = "Bender Bending Rodríguez",
      "description" = "A high-tech industrial metalworking robot",
      "managed-by" =  "terraform",
      "type" = "kv",
      "options" = {
        "version" = "2"
      }
      "environments" = [ "dev", "ps", "prd" ],
      "services" = [ "delivery", "security" ],
    
    },
  "fry" = {
      "name" = "Philip J. Fry",
      "description" = "A pizza delivery boy",
      "managed-by" =  "terraform",
      "type" = "kv",
      "options" = {
        "version" = "2"
      }
      "environments" = [ "dev", "ps", "prd" ],
      "services" = [ "delivery", "musician" ],
    
    },
  }
}
variable "testCases" {
  default = {
    "01" = {
      "product" = "bender"
      "path" = "beer/is/su/ps/awesome"
    }
    "02" = {
      "product" = "bender"
      "path" = "beer/ps/is/super/awesome"
    }
    "03" = {
      "product" = "bender"
      "path" = "beer/ps/testing/tester/test/case/for/testing"
    }
  }
  
}
# EOF