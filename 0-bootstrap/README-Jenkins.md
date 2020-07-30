# 0-bootstrap - deploying a Jenkins-compatible environment

The purpose of this step is to bootstrap a GCP organization, creating all the required resources & permissions to start using the Cloud Foundation Toolkit (CFT). This step also guides you on how to configure a CICD project to host a Jenkins Agent, which connects to your existing Jenkins Master infrastructure & your own Git repos (which might live on-prem). The Jenkins Agent will run CICD pipelines for foundations code in subsequent stages.

Another CICD option is to use Cloud Build & Cloud Source Repos. If you don't have a Jenkins implementation and don't want one, then we recommend you to [use the Cloud Build module](./README.md) instead.

## Overview

The objective of the instructions below is to configure the infrastructure that allows you to run CICD deployments for the next stages (`1-org, 2-environments, 3-networks, 4-projects`) using Jenkins. The infrastructure consists in two Google Cloud Platform projects (`cft-seed` and `prj-cicd`) and VPN configuration to connect to your on-prem environment.

It is a best practice to have two separate projects here (`cft-seed` and `prj-cicd`) for separation of concerns. On one hand, `cft-seed` stores terraform state and has the Service Account able to create / modify infrastructure. On the other hand, the deployment of that infrastructure is coordinated by Jenkins, which is implemented in `prj-cicd` and connected to your Master on-prem.

**After following the instructions below, you will have:**
- The `cft-seed` project, which contains:
  - Terraform state bucket
  - Custom Service Account used by Terraform to create new resources in GCP
- The `prj-cicd` project, which contains:
  - GCE Instance for the Jenkins Agent, connected to your current Jenkins Master using SSH.
  - VPC to connect the Jenkins GCE Instance to
  - FW rules to allow communication over port 22
  - VPN connection with on-prem (or where ever your Jenkins Master is located)
  - Custom service account `sa-jenkins-agent-gce@prj-cicd-xxxx.com` for the GCE instance. This service account is granted the access to generate tokens on the Terraform custom service account in the `seed` project
**Note:** these instructions do not indicate how to create a Jenkins Master. To deploy a Jenkins Master, you should follow one of the available user guides about [Jenkins in GCP](https://cloud.google.com/jenkins).

#### If you don't want to use Jenkins

**If you don't have a Jenkins implementation and don't want one**, then we recommend you to [use the Cloud Build module](./README.md) instead.

## Requirements

Please see the **[requirements](./modules/jenkins-agent/README.md#Requirements)** of Software, Infrastructure and Permissions before following the instructions below.

## Instructions

You arrived to these instructions because you are using the `jenkins_bootstrap` to run the 0-bootstrap step instead of `cloudbuild_bootstrap`. Please follow the indications below:
- Make sure you cover all the [requirements](./modules/jenkins-agent/README.md#Requirements) of Software, Infrastructure and Permissions before following the instructions below.

### I. Setup your environment
  - Required information:
     - Access to the Jenkins Master host to run `ssh-keygen` command
     - Access to the Jenkins Master Web UI
     - [SSH Agent Jenkins plugin](https://plugins.jenkins.io/ssh-agent) installed in your Jenkins Master
     - Private IP address for the Jenkins Agent: usually assigned by your network administrator. You will use this IP for the GCE instance that will be created in the `cicd` GCP Project in step [II. Create the SEED and CICD projects using Terraform](#II.-Create-the-SEED-and-CICD-projects-using-Terraform).
     - Access to create five Git repositories, one for each directory in this [monorepo](https://github.com/terraform-google-modules/terraform-example-foundation) (`0-bootstrap, 1-org, 2-environments, 3-networks, 4-projects`). These are usually private repositories that might be on-prem.

1. Generate a SSH key pair. In the Jenkins Master host, use the `ssh-keygen` command to generate a SSH key pair.
   - You will need this key pair to enable authentication between the Master and Agent. Although the key pair can be generated in any linux machine, it is recommended not to copy the secret private key from one host to another, so you probably want to do this in the Jenkins Master host command line.

    - Note the `ssh-keygen` command uses the `-N` option to protect the private key with a password. In this example, we are using `-N ""` which means we are not setting a password to protect this private key.
        ```
        SSH_LOCAL_CONFIG_DIR="$HOME/.ssh"
        JENKINS_USER="jenkins"
        JENKINS_AGENT_NAME="AgentGCE1"
        SSH_KEY_FILE_PATH="$SSH_LOCAL_CONFIG_DIR/$JENKINS_USER-${JENKINS_AGENT_NAME}_rsa"

        mkdir "$SSH_LOCAL_CONFIG_DIR"
        ssh-keygen -t rsa -m PEM -N "" -C $JENKINS_USER -f $SSH_KEY_FILE_PATH
        cat $SSH_KEY_FILE_PATH
        ```

    - You will see an output similar to this:
      ```
      -----BEGIN RSA PRIVATE KEY-----
            copy your private key
              from BEGIN to END
        And configure a new
        Jenkins Agent in the Web UI
      -----END RSA PRIVATE KEY-----
      ```

1. Configure a new SSH Jenkins Agent in the Jenkins Master’s Web UI. You need the following information:
    - [SSH Agent Jenkins plugin](https://plugins.jenkins.io/ssh-agent/) installed in your Master
    - SSH private key you just generated in the previous step
    - Passphrase that protects the private key (if you used the `-N ""` option)
    - Jenkins Agent’s private IP address (usually assigned by your Network Administrator)

1. Create five individual Git repositories in your Git server
    - This might be a task delegated to your infrastructure team.
    - Note that although this infrastructure code is distributed to you as a [monorepo](https://github.com/terraform-google-modules/terraform-example-foundation), you will store the code in five different repositories, one for each directory:
        - `./0-bootstrap, ./1-org, ./2-environments, ./3-networks, ./4-projects`
    - For simplicity, let's name your five repositories:
        - `YOUR_NEW_REPO-0-bootstrap, YOUR_NEW_REPO-1-org, YOUR_NEW_REPO-2-environments, YOUR_NEW_REPO-3-networks, YOUR_NEW_REPO-4-projects`
    - Towards the end of these instructions, you will configure automatic pipelines in Jenkins to deploy new code pushed to four of your repos (`YOUR_NEW_REPO-1-org, YOUR_NEW_REPO-2-environments, YOUR_NEW_REPO-3-networks, YOUR_NEW_REPO-4-projects`).
    - However, **there is no automatic pipeline needed for `YOUR_NEW_REPO-0-bootstrap`**
    - In this section we work with your repository that is a copy of the directory `./0-bootstrap` (`YOUR_NEW_REPO-0-bootstrap`)

1. Clone this mono-repository:
    ```
    git clone https://github.com/terraform-google-modules/terraform-example-foundation
    ```

1. Clone the repository you created to host the `0-bootstrap` directory:
    ```
    git clone <YOUR_NEW_REPO-0-bootstrap>
    ```

1. Change to freshly cloned repo and change to non master branch:
    ```
    cd <YOUR_NEW_REPO-0-bootstrap>
    git checkout -b my-0-bootstrap
    ```

1. Copy contents of foundation to the new repo (modify accordingly based on your current directory):
    ```
    cp -R ../terraform-example-foundation/0-bootstrap/* .
    ```

1. Activate the Jenkins module and disable the Cloud Build module:
    1. Comment-out the `cloudbuild_bootstrap` module in `./main.tf`
    1. Comment-out the `cloudbuild_bootstrap` outputs in `./outputs.tf`
    1. Un-comment the `jenkins_bootstrap` module in `./main.tf`
    1. Un-comment the `jenkins_bootstrap` variables in `./variables.tf`
    1. Un-comment the `jenkins_bootstrap` outputs in `./outputs.tf`

1. Rename `terraform.example.tfvars` to `terraform.tfvars` and update the file with values from your environment:
    ```
    # Rename file
    mv terraform.example.tfvars terraform.tfvars
    ```
    - One of the value to supply is the **public SSH key** you generated in the first step (variable `jenkins_agent_gce_ssh_pub_key`). Please note this is **not the secret private key**. The public SSH key can be in your repository code. Show the public key using `cat "${SSH_KEY_FILE_PATH}.pub"`, you will have to copy / paste it in the the `terraform.tfvars` file.

1. Commit changes and push to the `my-0-bootstrap` branch in your repository `YOUR_NEW_REPO-0-bootstrap`:
    ```
    git add .
    git commit -m "Your message - Bootstrap configuration using jenkins_module"
    git push --set-upstream origin my-0-bootstrap
    ```

    - Reminder: towards the end of these instructions, you will configure automatic pipelines in Jenkins to deploy new code pushed to four of your repos (`YOUR_NEW_REPO-1-org, YOUR_NEW_REPO-2-environments, YOUR_NEW_REPO-3-networks, YOUR_NEW_REPO-4-projects`). However, **there is no automatic pipeline needed for `YOUR_NEW_REPO-0-bootstrap`**.

### II. Create the SEED and CICD projects using Terraform

- Required information:
  - Terraform version 0.12.24 - See [Requirements](#requirements) section for more details.
  - Private IP address for the Jenkins Agent (this might be supplied by your Network administrator - the example variables use "10.2.0.0"). This private IP will be reachable through the VPN connection that you will create later.

1. Get the appropriate credentials: run the following command with an account that has the [necessary permissions](./modules/jenkins-agent/README.md#Permissions).
    ```
    gcloud auth application-default login
    ```
    1. Open the link in your browser and accept.

1. Run terraform commands.
    - After the credentials are configured, we will create the `cft-seed` project (which contains the GCS state bucket and Terraform custom service account) and the `prj-cicd` project (which contains the Jenkins Agent, its custom service account and where we will add VPN configuration)
    - **Use Terraform 0.12.24** to run the terraform script with the commands below:
    - **WARNING: Make sure you have commented-out the `cloudbuild_bootstrap` module and enabled the `jenkins_bootstrap` module in the `./main.tf` file**
    ```
    terraform init
    terraform plan
    terraform apply
    ```
    - The Terraform script will take about 10 to 15 minutes. Once it finishes, note that communication between on-prem and the `prj-cicd` project won’t happen yet - you will configure the VPN network connectivity in step [III. Create VPN connection](#III.-Create-VPN-connection).

1. Move Terraform State to the GCS bucket created in the seed project
    - Run this command to copy the `backend.tf` file and update the GCS bucket name. Replace the `TF_STATE_GCS_BUCKET_NAME` with the name of your bucket (you can run `terraform output` to find these values).
    ```
    TF_STATE_GCS_BUCKET_NAME=`(terraform output gcs_bucket_tfstate)`
    mv backend.tf.example backend.tf
    sed -i "s/UPDATE_ME/$TF_STATE_GCS_BUCKET_NAME/" backend.tf
    ```

   **If using MacOS:**
    ```
    TF_STATE_GCS_BUCKET_NAME=`(terraform output gcs_bucket_tfstate)`
    mv backend.tf.example backend.tf
    sed -i ".bak" "s/UPDATE_ME/$TF_STATE_GCS_BUCKET_NAME/" backend.tf
    rm backend.tf.bak
    ```

1. Re-run `terraform init` and agree to copy state to gcs when prompted
    ```
    terraform init
    ```
    - (Optional) Run `terraform apply` to verify state is configured correctly. You can confirm the terraform state is now in that bucket by visiting the bucket url in your seed project.

1. Commit changes and push to the `my-0-bootstrap` branch in your repository `YOUR_NEW_REPO-0-bootstrap`:
    ```
    git add backend.tf
    git commit -m "Your message - Terraform Backend configuration using GCS"
    git push
    ```

### III. Create VPN connection
- Required information:
  - From previous step (you can run `terraform output` to find these values):
    - CICD project ID
    - Default region (see it in the `variables.tf` file or in `terraform.tfvars` if you changed it)
    - Jenkins Agent VPC name, which was created in the `prj-cicd` project
    - Terraform State bucket name, which was created in the `cft-seed` project
  - Usually, from your network administrator:
    - On-prem VPN public IP Address
    - Jenkins Master’s network CIDR (the example code uses "10.1.0.0/24")
    - Jenkins Agent network CIDR (the example code uses "10.2.0.0/24")
    - VPN PSK (pre-shared secret key)

- Here you will configure a VPN Network tunnel to enable connectivity between the `prj-cicd` project and your on-prem environment. Learn more about [how to deploy a VPN tunnel in GCP](https://cloud.google.com/network-connectivity/docs/vpn/how-to).

1. Supply the required values for the bash variables below:
    ```
    DEFAULT_REGION="us-central1"
    ONPREM_VPN_PUBLIC_IP_ADDRESS="x.x.x.x"
    JENKINS_MASTER_NETWORK_CIDR="10.1.0.0/24"
    JENKINS_AGENT_NETWORK_CIDR="10.2.0.0/24"
    JENKINS_AGENT_VPC_NAME="vpc-b-jenkinsagents"
    CICD_PROJECT_ID=`(terraform output cicd_project_id)`

    # New VPN variables
    VPN_PSK_SECRET="my-secret"
    CICD_VPN_PUBLIC_IP_NAME="cicd-vpn-external-static-ip"
    CICD_VPN_NAME="vpn-from-onprem-to-cicd"
    ```

1. Reserve an `EXTERNAL` IP address for the VPN in the `prj-cicd` project (Your network administrator will need this IP address):
    ```
    # Reserve a new external IP for the VPN in the cicd project
    gcloud compute addresses create $CICD_VPN_PUBLIC_IP_NAME \
    --project="${CICD_PROJECT_ID}" --region="${DEFAULT_REGION}"

    gcloud compute addresses list  --project="${CICD_PROJECT_ID}" \
   | grep $CICD_VPN_PUBLIC_IP_NAME
   ```

1. The above command showed the `EXTERNAL` static IP address that has been reserved for your VPN in the `prj-cicd` project. **You need to do two things with this IP Address:**
    1. Inform your Network administrator of the IP address so they configure the on-prem side of the VPN tunnel.
    1. Set the variable below with the IP address you just obtained so you can create the GCP side of the VPN tunnel in the `cicd` project:
        ```
        # New VPN variables
        CICD_VPN_PUBLIC_IP_ADDRESS="x.x.x.x"
        ```

1. We now have all the necessary information to create the VPN in the `cicd` project.
    ```
    # Create the new VPN gateway
    gcloud compute --project $CICD_PROJECT_ID \
      target-vpn-gateways create $CICD_VPN_NAME \
      --region $DEFAULT_REGION \
      --network $JENKINS_AGENT_VPC_NAME

    # Create the forwarding rules
    gcloud compute --project $CICD_PROJECT_ID \
      forwarding-rules create "${CICD_VPN_NAME}-rule-esp" \
      --region $DEFAULT_REGION \
      --address $CICD_VPN_PUBLIC_IP_ADDRESS \
      --ip-protocol "ESP" \
      --target-vpn-gateway $CICD_VPN_NAME

    gcloud compute --project $CICD_PROJECT_ID \
      forwarding-rules create "${CICD_VPN_NAME}-rule-udp500" \
      --region $DEFAULT_REGION \
      --address $CICD_VPN_PUBLIC_IP_ADDRESS \
      --ip-protocol "UDP" --ports "500" \
      --target-vpn-gateway $CICD_VPN_NAME

    gcloud compute --project $CICD_PROJECT_ID \
      forwarding-rules create "${CICD_VPN_NAME}-rule-udp4500" \
      --region $DEFAULT_REGION \
      --address $CICD_VPN_PUBLIC_IP_ADDRESS \
      --ip-protocol "UDP" --ports "4500" \
      --target-vpn-gateway $CICD_VPN_NAME

    # Create a Route-Based VPN tunnel
    gcloud compute --project $CICD_PROJECT_ID \
      vpn-tunnels create "${CICD_VPN_NAME}-tunnel-1" \
      --region $DEFAULT_REGION \
      --peer-address $ONPREM_VPN_PUBLIC_IP_ADDRESS \
      --shared-secret $VPN_PSK_SECRET  \
      --ike-version "2" \
      --local-traffic-selector="0.0.0.0/0" \
      --remote-traffic-selector="0.0.0.0/0" \
      --target-vpn-gateway $CICD_VPN_NAME

    # Create the necessary Route
    gcloud compute --project $CICD_PROJECT_ID \
      routes create "${CICD_VPN_NAME}-tunnel-1-route-1" \
      --network $JENKINS_AGENT_VPC_NAME \
      --next-hop-vpn-tunnel "${CICD_VPN_NAME}-tunnel-1" \
      --next-hop-vpn-tunnel-region $DEFAULT_REGION \
      --destination-range $JENKINS_MASTER_NETWORK_CIDR
    ```

  - Assuming your network administrator already configured the on-prem end of the VPN, the CICD end of the VPN might show the message `First Handshake` for around 5 minutes.
  - When the VPN is ready, the status will show `Tunnel is up and running`. At this point, your Jenkins Master (on-prem) and Jenkins Agent (in `prj-cicd` project) must have network connectivity through the VPN.

1. Connect to the SSH Agent and test a pipeline using the Jenkins Web UI:
    1. Connect to the [SSH Agent](https://plugins.jenkins.io/ssh-agent) and troubleshoot network connectivity if needed.
    1. Test that your Master can deploy a pipeline to the Jenkins Agent in GCP (you can test by running with a simple `echo "Hello World"` project / job) from the Jenkins Web UI.

### IV. Configure the Git repositories and Multibranch Pipeline in your Jenkins Master

- **Note:** this section is considered out of the scope of this document, since there are multiple options on how to configure the Git repositories and **Multibranch Pipeline** in your Jenkins Master. Here we provide some guidance that you should keep in mind while completing this step. Visit the [Jenkins website](http://jenkins.io) for more information, there are plenty of Jenkins Plugins that could help with the task.

1. Create Multibranch pipelines for your new repos (`YOUR_NEW_REPO-1-org, YOUR_NEW_REPO-2-environments, YOUR_NEW_REPO-3-networks, YOUR_NEW_REPO-4-projects`).
    - **DO NOT configure an automatic pipeline for your `YOUR_NEW_REPO-0-bootstrap` repository**

1. Assuming your new Git repositories are private, you may need to configure new credentials In your Jenkins Master web UI, so it can connect to the repositories.
1. You will need to configure a "**Multibranch Pipeline**" for each one of the repositories. Note that the `Jenkinsfile` and `tf-wrapper.sh` files use **the `$BRANCH_NAME` environment variable, which is only available in Multibranch Pipelines** in Jenkins.
1. You will also want to configure automatic triggers in each one of the Jenkins Multibranch Pipelines, unless you want to run the pipelines manually from the Jenkins Web UI after each commit to your repositories.

## Contributing

Refer to the [contribution guidelines](../CONTRIBUTING.md) for
information on contributing to this module.
