# Security Reference Architecture Template

# Introduction:

Databricks has worked with thousands of customers to securely deploy the Databricks platform with appropriate security features to meet their architecture requirements.

This Security Reference Architecture (SRA) repository implements common security features as a unified terraform templates that are typically deployed by our security conscious customers.

# Component Breakdown and Description:

In this section, we break down each of the components that we've included in this Security Reference Architecture.

In various .tf scripts, we have included direct links to the Databricks Terraform documentation. The [official documentation](https://registry.terraform.io/providers/databricks/databricks/latest/docs) can be found here.

## Infrastructure Deployment:

- **Customer-managed VPC**: A [customer-managed VPC](https://docs.databricks.com/administration-guide/cloud-configurations/aws/customer-managed-vpc.html) allows Databricks customers to exercise more control over your network configures to comply with specific cloud security and governance standards that a customer's organization may require.

- **AWS VPC Endpoints for S3, STS, and Kinesis**: Using AWS PrivateLink technology, a VPC endpoint is a service that connects a customer's VPC endpoint to AWS services without traversing public IP addresses. [S3, STS, and Kinesis](https://docs.databricks.com/administration-guide/cloud-configurations/aws/privatelink.html#step-5-add-vpc-endpoints-for-other-aws-services-recommended-but-optional) are best practices for standard enterprise Databricks deployments. Additional endpoints can be configured depending on use case (e.g. Amazon DynamoDB and AWS Glue).


- **Back-end AWS PrivateLink Connectivity**: AWS PrivateLink provides a private network route from one AWS environment to another. [Back-end PrivateLink](https://docs.databricks.com/administration-guide/cloud-configurations/aws/privatelink.html#overview) is configured so that communication between the customer's data plane and Databricks control plane does not traverse public IP addresses. This is accomplished through Databricks specific interface VPC endpoints. Front-end PrivateLink is available as well for customers to ensure users traffic remains over the AWS backbone, however, this is not included in this Terraform template.


- **Scoped-down IAM Policy for the Databricks cross-account role**: A [cross-account role](https://docs.databricks.com/administration-guide/account-api/iam-role.html) is needed for users, jobs, and other third party tools to spin-up Databricks clusters within the customer's data plane environment. This cross-account role can be scoped down to only function within the permitters of the data plane's VPC, subnets, and security group.


- **Restrictive Root Bucket**: Each workspace, prior to creation, registers a [dedicated S3 bucket](https://docs.databricks.com/administration-guide/account-api/aws-storage.html). This bucket is for workspace assets. On AWS, S3 bucket policies can be applied to limit access to the Databricks control plane and the customer data plane.


- **Unity Catalog**:  [Unity Catalog](https://docs.databricks.com/data-governance/unity-catalog/index.html) is a unified governance solution for all data and AI assets including files, tables, and machine learning models. Unity Catalog provides a modern approach to granular access controls with centralized policy, auditing, and lineage tracking, all integrated into your Databricks workflow.


## Post Workspace Deployment:

- **Audit and Billing Log Delivery**: Databricks delivers logs to your S3 buckets. [Audit logs](https://docs.databricks.com/administration-guide/account-settings/audit-logs.html) contain two levels of events workspace-level audit logs with workspace-level events and account-level audit logs with account-level events. In addition to these logs, you can generate additional events by enabling verbose audit logs. [Billable usage logs](https://docs.databricks.com/administration-guide/account-settings/billable-usage-delivery.html) are delivered daily to an AWS S3 storage bucket. There will be a separate CSV file for each workspace. This file contains historical data about the workspace's cluster usage in Databricks Units (DBUs).


- **Service Principals**: [Service principal](https://docs.databricks.com/administration-guide/users-groups/service-principals.html) is an identity that you create in Databricks for use with automated tools, jobs, and applications. It's against best practice to tie production workloads to individual user accounts, and so we recommend configuring these service principals within Databricks. In this template, we create an example service principal.


- **Token Management**: [Personal access tokens](https://docs.databricks.com/dev-tools/api/latest/authentication.html) are used to access Databricks REST APIs in-lieu of passwords. In this template we create an example token, set the maximum time of it. This can be set at an administrative level for all users.


- **Secret Management** Integrating with heterogenous systems requires managing a potentially large set of credentials and safely distributing them across an organization. Instead of directly entering your credentials into a notebook, use [Databricks secrets](https://docs.databricks.com/security/secrets/index.html) to store your credentials and reference them in notebooks and jobs. In this template, we create an example secret.


- **Admin Console Configurations**: There are a number of configurations within the [admin console](https://docs.databricks.com/administration-guide/admin-console.html) that can be controlled to reduce your threat vector. In this example, we use the workspace configurations Terraform template to disable and enable numerous options.


- **Cluster Tags and Pool Tags**: [Cluster and pool tags](https://docs.databricks.com/administration-guide/account-settings/usage-detail-tags-aws.html) allow customers to monitor cost and accurately attribute Databricks usage to your organization's business unit and teams (for chargebacks, for examples). These tags propagate both to detailed DBU usage reports and to AWS EC2 and AWS EBS instances for cost analysis.


# Additional Security Recommendations and Opportunities:
In this section, we break down additional security recommendations and opportunities to maintain a strong security posture that either cannot be configured into this Terraform script or is very specific to individual customers (e.g. SCIM, SSO, Front-End PrivateLink, etc.)


- **Segement Workspaces for Various Levels of Data Seperation**: While Databricks has numerous capabilities for isolating different workloads, such as table ACLs and IAM passthrough for very sensitive workloads, the primary isolation method is to move sensitive workloads to a different workspace. This sometimes happens when a customer has very different teams (for example, a security team and a marketing team) who must both analyze different data in Databricks.


- **Avoid Storing Production Datasets in Databricks File Store**: Because the DBFS root is accessible to all users in a workspace, all users can access any data stored here. It is important to instruct users to avoid using this location for storing sensitive data. The default location for managed tables in the Hive metastore on Databricks is the DBFS root; to prevent end users who create managed tables from writing to the DBFS root, declare a location on external storage when creating databases in the Hive metastore.


- **Single Sign-On, Multi-factor Authentication, SCIM Provisioning**: Most production or enterprise deployments enable their workspaces to use [Single Sign-On (SSO)](https://docs.databricks.com/administration-guide/users-groups/single-sign-on/index.html) and multi-factor authentication (MFA). As users are added, changed, and deleted, we recommended customers integrate [SCIM (System for Cross-domain Identity Management)](https://docs.databricks.com/dev-tools/api/latest/scim/index.html)to their account console to sync these actions.


- **Backup Assets from the Databricks Control Plane**: While Databricks does not offer disaster recovery services, many customers use Databricks capabilities, including the Account API, to create a cold (standby) workspace in another region. This can be done using various tools such as the Databricks [migration tool](https://github.com/databrickslabs/migrate), [Databricks sync](https://github.com/databrickslabs/databricks-sync), or the [Terraform exporter](https://registry.terraform.io/providers/databricks/databricks/latest/docs/guides/experimental-exporter)

- **Regularly Restart Databricks Clusters**: When you restart a cluster, it gets the latest images for the compute resource containers and the VM hosts. It is particularly important to schedule regular restarts for long-running clusters such as those used for processing streaming data. If you enable the compliance security profile for your account or your workspace, long-running clusters are automatically restarted after 25 days. Databricks recommends that admins restart clusters manually during a scheduled maintenance window. This reduces the risk of an auto-restart disrupting a scheduled job.


- **Evaluate Whether your Workflow requires using Git Repos or CI/CD**: Mature organizations often build production workloads by using CI/CD to integrate code scanning, better control permissions, perform linting, and more. When there is highly sensitive data analyzed, a CI/CD process can also allow scanning for known scenarios such as hard coded secrets.



# Getting Started:

1. Clone this Repo 

2. Install [Terraform](https://developer.hashicorp.com/terraform/downloads)

3. Fill out `example.tfvars` and place in `tf` directory

5. CD into `tf`

5. Run `terraform init`

6. Run `terraform validate`

7. From `tf` directory, run `terraform plan -var-file ../example.tfvars`

8. Run `terraform apply -var-file ../example.tfvars`

# Network Diagram

![Architecture Diagram](https://github.com/JDBraun/standard-terraform-example/blob/master/img/Standard%20-%20Network%20Topology.png)