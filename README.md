# Terraform KCC Demo 

This tutorial walks you through using [Terraform](https://www.terraform.io/) to manage Google Cloud resources backed by GCP's [Config Connector](https://cloud.google.com/config-connector/docs/overview).


## Purpose

Config Connector is often viewed as a Terraform competitor as both tools can be used to manage Google Cloud resources. Terraform leverages HCL and the [google cloud terraform provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs) to manage resources while Config Connector leverages Kubernetes Custom Resource Definitions.

When comparing these tools it helps to think of Config Connector as an alternative API for managing GCP resources based on Kubernetes CRDs. So why would anyone want to use it? Config Connector exposes a data model that allows you to support multiple configuration frontends such as Terraform or [Helm](https://helm.sh/), and in some ways, Config Connector provides a much tighter contract between cloud resources and configuration tools that declare them.

Terraform is a general purpose configuration management tool and can be used to manage resources outside of Config Connector's scope. Users will have the option of leveraging the right provider, [kubernetes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/guides/getting-started) in the case of Config Connector, or [google cloud](https://registry.terraform.io/providers/hashicorp/google/latest/docs) in the case of GCP standard API, for managing GCP resources.

## Tutorial

This tutorial will setup the following Google Cloud resources:

* `redisinstance-sample` cloud redis instance
* `demo_network` compute network

Clone the tutorial git repo:

```
git clone https://github.com/kelseyhightower/terraform-kcc-demo.git
```

### Provision a GKE Cluster and Install Config Connector

```
cd terraform-kcc-demo
```

Create a GKE Cluster with the [Config Connector GKE addon](https://cloud.google.com/config-connector/docs/how-to/install-upgrade-uninstall#installing_the) enabled:

```
./bin/create-cluster
```

Generate the config connector configuration:

```
./bin/configure-config-connector
```

Configure the config connector:

```
kubectl apply -f configconnector.yaml
```

Configure the default namespace to create GCP resource in the active project:

```
PROJECT_ID=$(gcloud config get-value project)
```

```
kubectl annotate namespace default \
  cnrm.cloud.google.com/project-id=${PROJECT_ID}
```

Verify the config connector installation:

```
kubectl wait -n cnrm-system \
  --for=condition=Ready pod --all
```

> Output
```
pod/cnrm-controller-manager-0 condition met
pod/cnrm-deletiondefender-0 condition met
pod/cnrm-resource-stats-recorder-766c746b86-8v4h4 condition met
pod/cnrm-webhook-manager-5b8968c555-p57n9 condition met
pod/cnrm-webhook-manager-5b8968c555-z8qtn condition met
```

### Using Terraform

With the config connector installed and configured we can now leverage Terraform as a front end to create a redis instance.

List the current set of redis instances:

```
gcloud redis instances list --region us-west1
```

> Output
```
Listed 0 items.
```

Change into the terraform directory:

```
cd terraform
```

Run terraform init to ensure the `google` and `kubernetes-alpha` provider are installed:

```
terraform init
```

> Output
```
Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/google...
- Finding latest version of hashicorp/kubernetes-alpha...
- Installing hashicorp/google v3.46.0...
- Installed hashicorp/google v3.46.0 (signed by HashiCorp)
- Installing hashicorp/kubernetes-alpha v0.2.1...
- Installed hashicorp/kubernetes-alpha v0.2.1 (signed by HashiCorp)
...
```

Review the Terraform config:

```
cat redis-instance.tf 
```

Apply the Terraform config:

```
terraform apply -auto-approve --target google_compute_network.demo_network
```

> Output

```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

> Due to a bug in the kubernetes provider we need to create the google compute network first

```
terraform plan
```

```
terraform apply -auto-approve
```

> Output
```
google_compute_network.demo_network: Refreshing state... [id=projects/hightowerlabs/global/networks/demo-network]
kubernetes_manifest.redis_instance: Creating...
kubernetes_manifest.redis_instance: Creation complete after 0s

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

```
kubectl get redisInstances
```

> Output
```
NAME                   AGE
redisinstance-sample   40s
```

```
gcloud redis instances list --region us-west1
```

> Output
```
INSTANCE_NAME         VERSION    REGION    TIER   SIZE_GB  HOST  PORT  NETWORK       RESERVED_IP  STATUS    CREATE_TIME
redisinstance-sample  REDIS_4_0  us-west1  BASIC  16       -     6379  demo-network               CREATING  2020-11-06T08:07:19
```

## Cleaning Up

The clean up script will delete the following resources:

* `redisinstance-sample` cloud redis instance
* `demo_network` compute network

Run the clean up script:

```
bin/cleanup
```

> Output

```
destroying terraform resources...

Destroy complete! Resources: 1 destroyed.
```
