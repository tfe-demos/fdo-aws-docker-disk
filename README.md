This repo demonstrates deploying TFE FDO Docker on AWS in "Mounted Disk" operational mode using publicly signed certificates

### Versions in use
TFE `v202502-1`
Docker `v26.1.4`
OS `Ubuntu 22.04`

### Prerequisites
- Bring your own Domain and SSL certificates. Make sure to rename and add your certs to the directory "tfeparty"
```
cert.pem    # Server Cert
key.pem     # Server Key
bundle.pem  # CA (Full Chain)
```
For example, the repo was tested with domain `tfeparty.cfd` resolving to the public IP of the ec2 instance, and using "Let's Encrypt" `certbot` to get SSL certs for the domain
```
sudo certbot certonly --standalone    # Download
sudo certbot renew                    # Renew
sudo certbot renew --dry-run          # Verify Renew
```
- Update the TFE_HOSTNAME in `cloudinit.yaml`
```
#42    export TFE_HOSTNAME=tfeparty.cfd
```
- Add your TFE license to the file `tfeparty/license.hclic`
- Setup your AWS env
```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_SESSION_TOKEN=
```
- The repo defaults to `var.region=eu-north-1` If you set a different region make sure to set the correct `var.ami` for Ubuntu 22.04 of that region

### Deploy Infrastructure
```
terraform init
terraform plan
terraform apply -auto-approve
```

### Login using the domain name
```
ssh -i ubuntu.pem ubuntu@tfeparty.cfd
```
- Confirm cloudinit is "done"
```
cloud-init status
```
If not, monitor with `cloud-init status --wait` till finished then re-login to the instance for the updated environment

- Confirm TFE variables are configured in shell
```
env | grep TFE
```

### Deploy TFE
```
echo $TFE_LICENSE | docker login --username terraform images.releases.hashicorp.com --password-stdin
docker compose --file /opt/tfe/compose.yaml up --detach
```

### Optional commands for monitoring and troubleshooting
```
docker compose --file /opt/tfe/compose.yaml exec tfe tfe-health-check-status
docker exec terraform-enterprise-tfe-1 tfe-health-check-status
docker compose --file /opt/tfe/compose.yaml logs --follow
docker exec terraform-enterprise-tfe-1 ls -lrt /var/log/terraform-enterprise/
docker exec terraform-enterprise-tfe-1 supervisorctl status
docker exec terraform-enterprise-tfe-1 supervisorctl tail -f <NAME> #tfe:vault
docker exec terraform-enterprise-tfe-1 tfectl app config --unredacted
```

### Create initial admin user using IACT (Initial Admin Creation Token)
The following command will return a URL to navigate to and create user form GUI directly
```
docker exec terraform-enterprise-tfe-1 tfectl admin token --url
```
Or you can assign the IACT to env. variable using either of the following commands
```
export IACT=$(docker exec terraform-enterprise-tfe-1 tfectl admin token)
export IACT=$(docker exec terraform-enterprise-tfe-1 curl -s http://localhost:80/admin/retrieve-iact && echo)
```
then, create the initial admin user (tfeparty - longpassword) with curl "admin-payload.json"
```
curl --header "Content-Type: application/json" --request POST --data @tfeparty/admin-payload.json https://${TFE_HOSTNAME}/admin/initial-admin-user?token=${IACT} && echo
```
Lastly, test login to the UI at `https://${TFE_HOSTNAME}`

### Create TFE Organization, and CLI Workspace
- test-org
- test-workspace

### Login to TFE from the EC2 instance
terraform login tfeparty.cfd

### Create a simple TF module and test Run on TFE
```
cat << EOF > main.tf
terraform {
  cloud {
    hostname     = "${TFE_HOSTNAME}"
    organization = "test-org"

    workspaces {
      name = "test-workspace"
    }
  }
}
resource "random_uuid" "test" {
}
output "uuid" {
  value       = random_uuid.test.id
  description = "UUID"
}
EOF

terraform init
terraform plan
terraform apply
```

### Optional: Add a "variable set" to your "TFE Organization > Settings" with your AWS credenetials to be able to create AWS resrouces using TFE

### Optional: Integrate with Non-Enterprise Github using OAuth
- TFE > Organization > Settings > Providers > Add VCS Provider > Github.com > Click "register a new OAuth app"
- Populate the fields on Github from TFE
- From Github provide Client ID and Secret to TFE
- Create and configure a "Github" type workspace, and observe GH pull-requests triggering plan, and GH commits triggering plan+apply

### Cleanup
```
docker compose --file /opt/tfe/compose.yaml down
docker compose --file /opt/tfe/compose.yaml down --rmi all --volumes
terraform destroy -auto-approve
rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup
```