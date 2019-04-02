treetracker.org as expressed in a hashicorp terraform repo, with dns records presented in a declaritive format (HCL, Hashicorp Configuration Language). 

DNS records are managed via DigitalOcean's API and terraform provider.

You will need a token from DigitalOcean in order to manage objects on the Greenstand cloud account.

Some info can be gleaned from this introductory tutorial:

https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean


The provider expects the DigitalOcean token to be provided in an environment variable named `DIGITALOCEAN_TOKEN`:

export DIGITALOCEAN_TOKEN={YOUR_PERSONAL_ACCESS_TOKEN}
