# 2-Tier-Archtecture Project Documentation

---

## Table of Contents

1. [Introduction](#introduction)
2. [Project Overview](#project-overview)
3. [Architecture Design](#architecture-design)
    - [Overall Architecture](#overall-architecture)
    - [VPC and Networking](#vpc-and-networking)
    - [Security Groups](#security-groups)
    - [EC2 Instances](#ec2-instances)
    - [Application Load Balancer (ALB)](#application-load-balancer-alb)
    - [RDS Database](#rds-database)
    - [NAT Gateway and Internet Access](#nat-gateway-and-internet-access)
4. [User Flow and System Interaction](#user-flow-and-system-interaction)
5. [Deployment Workflow](#deployment-workflow)
    - [Terraform Setup](#terraform-setup)
    - [CI/CD with GitHub Actions](#cicd-with-github-actions)
6. [Under the Hood: Component Integration](#under-the-hood-component-integration)
7. [Challenges and Solutions](#challenges-and-solutions)
8. [Future Enhancements](#future-enhancements)
9. [Frequently Asked Questions (FAQ)](#frequently-asked-questions-faq)
10. [Conclusion](#conclusion)

---

## Introduction

This project demonstrates the design, deployment, and automation of a scalable, resilient, and secure two-tier web architecture on AWS. It leverages key AWS services integrated using Infrastructure as Code (IaC) with Terraform and automates the deployment pipeline using GitHub Actions. The aim is to provide a comprehensive understanding of how each component fits into the overall architecture, their interactions, and the underlying theory.

---

## Project Overview

The goal of this project is to:

- Build a secure and scalable two-tier architecture suitable for web applications.
- Automate the deployment of AWS resources using Terraform, ensuring repeatability and consistency.
- Implement a Continuous Integration/Continuous Deployment (CI/CD) pipeline for the application code deployment.
- Address and document challenges encountered during the development process.
- Provide in-depth explanations of the components, their integration, and the user flow to enhance understanding.

### **Key Features**

- **Networking**: Creation of a Virtual Private Cloud (VPC) with public and private subnets, Internet Gateway, NAT Gateways, and route tables to establish secure and efficient networking.
- **Security**: Implementation of security groups to control traffic between components, enhancing the security posture.
- **Database Layer**: Deployment of a Multi-AZ RDS MySQL database with credentials securely managed via AWS Systems Manager (SSM) Parameter Store.
- **Web/Application Layer**: EC2 instances hosting NGINX web server, configured through a Launch Template and balanced via an Application Load Balancer (ALB).
- **CI/CD Pipeline**: Implementation of a fully automated deployment pipeline using GitHub Actions for both infrastructure and application code.

---

## Architecture Design

### Overall Architecture

The architecture follows a classic two-tier model, consisting of:

1. **Presentation Tier (Web Layer)**: Public-facing EC2 instances running NGINX, serving web content and handling user requests.
2. **Data Tier (Database Layer)**: A private RDS MySQL database securely storing application data.

An Application Load Balancer (ALB) sits in front of the EC2 instances to distribute incoming traffic and provide high availability. The architecture is designed within a VPC to ensure network isolation and security.

**Diagram Overview (textual representation):**

```
Internet
   |
   |---> Application Load Balancer (Public Subnets)
           |
           |---> EC2 Instances (Web/App Servers in Public Subnets)
                   |
                   |---> RDS MySQL Database (Private Subnets)
```

### VPC and Networking

#### Components:

1. **Virtual Private Cloud (VPC)**:

   - **CIDR Block**: `10.0.0.0/16`
   - **Purpose**: Provides an isolated virtual network for AWS resources, allowing control over IP addressing, subnets, route tables, and network gateways.

2. **Subnets**:

   - **Public Subnets**: Two subnets spread across different Availability Zones (AZs) for high availability.

     - **CIDR Blocks**: Defined in `var.public_subnet_cidrs` (e.g., `10.0.1.0/24`, `10.0.2.0/24`).
     - **Purpose**: Host resources that need direct access to the internet, such as the ALB and EC2 instances.
     - **Configuration**:

       - `map_public_ip_on_launch`: `true` (Automatically assigns public IPs to instances launched in these subnets).
       - **Availability Zones**: Dynamically assigned using available AZs.

   - **Private Subnets**: Two subnets in different AZs.

     - **CIDR Blocks**: Defined in `var.private_subnet_cidrs` (e.g., `10.0.3.0/24`, `10.0.4.0/24`).
     - **Purpose**: Host resources that should not be directly accessible from the internet, such as the RDS database.
     - **Configuration**:

       - **Availability Zones**: Same as public subnets to ensure high availability.

3. **Internet Gateway (IGW)**:

   - **Purpose**: Enables resources within public subnets to communicate with the internet.
   - **Integration**: Attached to the VPC and routes traffic from public subnets to the internet.

4. **NAT Gateways**:

   - **Purpose**: Allows instances in private subnets to access the internet securely.
   - **Configuration**:

     - **Elastic IPs**: Each NAT Gateway is associated with an Elastic IP (EIP).
     - **High Availability**: One NAT Gateway per Availability Zone for fault tolerance.
     - **Placement**: Deployed in public subnets.

5. **Route Tables**:

   - **Public Route Table**:

     - **Routes**: Directs internet-bound traffic from public subnets to the IGW.
     - **Association**: Associated with all public subnets.

   - **Private Route Tables**:

     - **Routes**: Directs internet-bound traffic from private subnets to the NAT Gateway in the same AZ.
     - **Association**: Each private subnet has its own route table associated with the NAT Gateway in the same AZ.

**Integration and Flow**:

- **Public Subnets**: Allow EC2 instances and the ALB to receive and send traffic to the internet via the IGW.
- **Private Subnets**: Provide a secure environment for the RDS database, shielding it from direct internet access.
- **NAT Gateways**: Ensure private resources can access external services (e.g., for updates) without exposing them to incoming internet traffic.
- **High Availability**: Using multiple NAT Gateways in different AZs avoids single points of failure and reduces latency.

### Security Groups

Security groups are virtual firewalls that control inbound and outbound traffic at the instance level.

#### Web Layer Security Group (`web_sg`):

- **Purpose**: Controls traffic for EC2 instances hosting the application.
- **Inbound Rules**:

  - **HTTP (Port 80)**: Allow traffic from anywhere (`0.0.0.0/0`).
  - **HTTPS (Port 443)**: Allow traffic from anywhere (`0.0.0.0/0`).
  - **SSH (Port 22)**: Allow traffic from a specific IP (e.g., your public IP) for secure management access.

- **Outbound Rules**:

  - **All Traffic**: Allow all outbound traffic to any destination (`0.0.0.0/0`).

#### Database Layer Security Group (`db_sg`):

- **Purpose**: Controls traffic for the RDS database.
- **Inbound Rules**:

  - **MySQL/Aurora (Port 3306)**: Allow traffic from instances associated with `web_sg`. This ensures that only the web servers can access the database.

- **Outbound Rules**:

  - **All Traffic**: Allow all outbound traffic to any destination (`0.0.0.0/0`).

**Security Considerations**:

- By restricting inbound database traffic to the web security group, we prevent unauthorized access from other sources.
- Outbound rules are set to allow all traffic to enable the database to perform necessary operations like backups or updates.

### EC2 Instances

#### Components:

1. **IAM Instance Profile**:

   - **Purpose**: Allows EC2 instances to assume an IAM role, granting permissions to access AWS services (e.g., SSM Parameter Store).
   - **Configuration**: An IAM role is created and attached to the EC2 instances via an instance profile.

2. **Key Pair**:

   - **Purpose**: Enables secure SSH access to EC2 instances.
   - **Creation**: A key pair is created and imported into AWS using the `aws_key_pair` resource.
   - **Usage**: The private key is kept securely on the local machine; the public key is uploaded to AWS.

3. **Launch Template and EC2 Module**:

   - **AMI**: Amazon Linux 2 (`ami-0c02fb55956c7d316`).
   - **Instance Type**: `t2.micro` (configurable based on needs).
   - **Subnet Assignment**: Instances are launched in public subnets.
   - **Security Groups**: Associated with `web_sg`.
   - **User Data**: A script to install NGINX and configure the web server upon instance launch.

4. **Auto Scaling Group (Future Enhancement)**:

   - While not currently implemented, the architecture allows for easy integration of an Auto Scaling Group for dynamic scaling.

#### How It Works:

- **Web Server Setup**: Instances automatically install and configure NGINX upon launch using user data scripts.
- **IAM Role**: Instances can securely access AWS services (e.g., retrieve secrets from SSM Parameter Store) without hardcoding credentials.
- **SSH Access**: Restricted to a specific IP address for security; key pair ensures encrypted connections.

### Application Load Balancer (ALB)

#### Components:

1. **Load Balancer**:

   - **Type**: Application Load Balancer (Layer 7).
   - **Scheme**: Internet-facing (accessible from the internet).
   - **Subnets**: Deployed in public subnets for internet-facing access.
   - **Security Groups**: Associated with `web_sg` to allow HTTP/HTTPS traffic.

2. **Target Group**:

   - **Target Type**: Instance.
   - **Protocol**: HTTP.
   - **Port**: 80.
   - **Health Checks**: Configured to monitor the health of instances by checking the root path (`/`).

3. **Listener**:

   - **Port**: 80.
   - **Protocol**: HTTP.
   - **Rules**: Directs incoming requests to the target group.

4. **Target Group Attachment**:

   - **Resource**: `aws_lb_target_group_attachment`.
   - **Purpose**: Dynamically registers EC2 instances with the target group.
   - **Configuration**:

     ```hcl
     resource "aws_lb_target_group_attachment" "ec2_targets" {
       count            = length(module.ec2.instance_ids)
       target_group_arn = module.alb.target_group_arn
       target_id        = module.ec2.instance_ids[count.index]
       port             = 80
     }
     ```

#### How It Works:

- **Traffic Distribution**: ALB distributes incoming HTTP requests across multiple EC2 instances in the target group.
- **Dynamic Registration**: As EC2 instances are created or terminated, they are automatically registered or deregistered with the target group.
- **Health Monitoring**: ALB performs health checks to ensure traffic is only routed to healthy instances.

**Traffic Flow**:

1. **Client Request**: A user accesses the application via the ALB's DNS name or a domain name pointing to it.
2. **Load Balancing**: The ALB receives the request and forwards it to one of the healthy EC2 instances based on the load balancing algorithm.
3. **Web Server Response**: The EC2 instance processes the request and sends the response back to the ALB.
4. **Response Delivery**: The ALB sends the response back to the user's browser.

### RDS Database

#### Components:

1. **Amazon RDS MySQL Instance**:

   - **Engine**: MySQL 8.0.
   - **Multi-AZ Deployment**: Provides high availability and automatic failover between AZs.
   - **Instance Class**: `db.m5.large` (adjustable based on performance requirements).
   - **Storage**:

     - **Allocated Storage**: 20 GB (initial size).
     - **Max Allocated Storage**: 100 GB (allows for auto-scaling storage as needed).

   - **Security**: Placed in private subnets with no public access (`publicly_accessible = false`).
   - **Parameter Group**: Uses default MySQL 8.0 parameter group.

2. **DB Subnet Group**:

   - **Purpose**: Defines which subnets the RDS instance can use (private subnets).
   - **Configuration**: Includes all private subnets.

3. **Credentials Management**:

   - **AWS SSM Parameter Store**:

     - **Purpose**: Securely stores database username and password.
     - **Retrieval**: Credentials are fetched in Terraform using `data "aws_ssm_parameter"` resources with decryption.

#### How It Works:

- **Data Security**: The RDS instance is isolated in private subnets, accessible only from the EC2 instances within the VPC.
- **High Availability**: Multi-AZ deployment ensures that a standby replica in a different AZ can take over in case of primary instance failure.
- **Secure Access**: Only EC2 instances with the appropriate security group (`web_sg`) can access the database on port 3306.
- **Credential Management**: Database credentials are securely stored and managed via SSM Parameter Store, avoiding hardcoding sensitive information.

### NAT Gateway and Internet Access

#### Components:

1. **Elastic IPs (EIPs)**:

   - **Purpose**: Provide static public IP addresses for the NAT Gateways.
   - **Configuration**: One EIP per NAT Gateway.

2. **NAT Gateways**:

   - **Purpose**: Allows instances in private subnets to access the internet for updates and external communications.
   - **Configuration**:

     - **High Availability**: One NAT Gateway per Availability Zone.
     - **Placement**: Deployed in public subnets.
     - **Association**: Each private subnet routes traffic through the NAT Gateway in the same AZ.

3. **Private Route Tables**:

   - **Purpose**: Routes outbound internet traffic from private subnets through the NAT Gateways.
   - **Configuration**:

     - **Routes**: `0.0.0.0/0` pointing to the NAT Gateway.
     - **Association**: Each private subnet has its own route table.

#### How It Works:

- **Outbound Internet Access**: Instances in private subnets send outbound traffic to the NAT Gateway, which forwards it to the internet.
- **Inbound Traffic Restriction**: NAT Gateways do not allow inbound traffic from the internet to private subnets, ensuring security.
- **High Availability**: By deploying NAT Gateways in each AZ, the architecture avoids single points of failure and reduces latency.

**Why Multiple NAT Gateways?**

- **Fault Tolerance**: If one AZ experiences an outage, the NAT Gateway in another AZ ensures continued internet access for resources in that AZ.
- **Reduced Latency and Costs**: Keeping NAT Gateways in the same AZ as the private subnets avoids cross-AZ data transfer costs and reduces latency.

---

## User Flow and System Interaction

Understanding the user flow is crucial to comprehending how the system components work together to serve user requests.

### Step-by-Step User Interaction:

1. **User Access**:

   - A user opens a web browser and enters the application's URL (e.g., `http://myapp.example.com`).
   - The DNS resolves the domain to the ALB's public IP address.

2. **Request Handling by ALB**:

   - The user's HTTP request reaches the ALB.
   - The ALB checks its listener rules to determine where to route the request.

3. **Load Balancing to EC2 Instances**:

   - Based on the load balancing algorithm (round-robin, least connections, etc.), the ALB selects a healthy EC2 instance from the target group.
   - The ALB forwards the request to the chosen EC2 instance over port 80.

4. **Processing by EC2 Instance**:

   - The EC2 instance receives the request via NGINX.
   - NGINX may serve static content directly or forward the request to an application server.

5. **Database Interaction**:

   - If the application needs to retrieve or store data, it connects to the RDS MySQL database.
   - The connection is made over the private network within the VPC, ensuring security.
   - Credentials are securely retrieved from SSM Parameter Store.

6. **Response Generation**:

   - The EC2 instance generates the appropriate response (e.g., an HTML page, JSON data).
   - NGINX serves the response back to the client via the ALB.

7. **Response Delivery**:

   - The ALB receives the response from the EC2 instance.
   - The ALB sends the response back to the user's browser.

### Under the Hood Details:

- **Session Management**:

  - If the application maintains user sessions, session data can be stored in the database or managed through other services.

- **Security Measures**:

  - **SSH Access**: Restricted to specific IP addresses for management purposes.
  - **IAM Roles**: EC2 instances use IAM roles to securely access AWS services without hardcoded credentials.

- **High Availability**:

  - **Multi-AZ Deployment**: Resources like RDS and NAT Gateways are spread across multiple AZs.
  - **Load Balancing**: ALB automatically distributes traffic, improving availability and scalability.
  - **Automatic Failover**: In case of instance failure, ALB routes traffic to other healthy instances.

- **Outbound Internet Access**:

  - **Private Subnets**: Instances can access the internet via NAT Gateways for updates or external communications.
  - **NAT Gateways**: Ensure secure outbound traffic without exposing private instances to inbound internet traffic.

---

## Deployment Workflow

### Terraform Setup

Terraform is used to define and provision the infrastructure in a consistent and repeatable manner.

1. **Backend Configuration**:

   - **State Storage**: Terraform state files are stored in an S3 bucket to allow collaboration and state sharing.
   - **State Locking**: DynamoDB table is used for state locking to prevent concurrent modifications.

2. **Terraform Modules**:

   - **Modularization**: Code is organized into reusable modules for each component (VPC, EC2, ALB, RDS).
   - **Benefits**: Improves code readability, maintainability, and reusability.

3. **Initialization and Validation**:

   - `terraform init`: Initializes the working directory, downloads providers, and sets up the backend.
   - `terraform validate`: Validates the configuration files for syntax correctness.

4. **Planning and Deployment**:

   - `terraform plan`: Creates an execution plan, showing what actions Terraform will take.
   - `terraform apply`: Executes the plan to provision the resources in AWS.

5. **Resource Configuration Highlights**:

   - **VPC and Subnets**: Defined with CIDR blocks and availability zones.
   - **Security Groups**: Configured with specific inbound and outbound rules.
   - **EC2 Instances**:

     - **IAM Instance Profile**: Allows instances to assume roles.
     - **Key Pair**: Created and used for SSH access.
     - **Launch Template**: Automates instance configuration.

   - **Load Balancer**:

     - **Module**: Configures the ALB, target groups, listeners, and security groups.
     - **Target Group Attachment**: Registers EC2 instances with the ALB.

   - **RDS Database**:

     - **Module**: Configures the RDS instance with parameters fetched from SSM Parameter Store.
     - **DB Subnet Group**: Ensures RDS uses private subnets.

   - **NAT Gateways and Route Tables**:

     - **Elastic IPs**: Allocated for NAT Gateways.
     - **NAT Gateways**: Deployed in public subnets.
     - **Private Route Tables**: Configured to route traffic through NAT Gateways.

### CI/CD with GitHub Actions

GitHub Actions is used to automate the deployment pipeline for both infrastructure and application code.

1. **Infrastructure as Code (IaC) Workflow**:

   - **Trigger**: Pushing code to the `main` branch triggers the workflow.
   - **Actions**:

     - **Validation**: Runs `terraform validate` to check for syntax errors.
     - **Planning**: Executes `terraform plan` to create an execution plan.
     - **Approval**: Optional manual approval step can be added before applying changes.
     - **Deployment**: Runs `terraform apply` to provision or update resources.

2. **Application Deployment**:

   - **Build and Test**: Compiles and tests application code (if applicable).
   - **Deployment Script**:

     - Uses `scp` or other methods to transfer application files to EC2 instances.
     - **Alternative**: Use AWS CodeDeploy or configuration management tools like Ansible for more robust deployment.

3. **Security and Credentials**:

   - **Secrets Management**: AWS credentials and other secrets are stored securely in GitHub Secrets.
   - **IAM Roles**: Use of IAM roles and policies to restrict permissions to only what is necessary.

4. **Error Handling and Notifications**:

   - **Logging**: Workflow logs provide detailed output for debugging.
   - **Notifications**: Can be integrated with email, Slack, or other tools to notify on build failures or successes.

---

## Under the Hood: Component Integration

Understanding the integration between components is key to appreciating the system's design.

### Networking Integration

- **VPC and Subnets**: The VPC provides a network boundary. Subnets partition the network into public and private zones.
- **Routing**:

  - **Public Subnets**: Route internet-bound traffic via the IGW.
  - **Private Subnets**: Route internet-bound traffic via the NAT Gateways.

- **Security Groups and Network ACLs**:

  - Control inbound and outbound traffic at the instance and subnet level.
  - Ensure only authorized traffic flows between components.

### EC2 and ALB Integration

- **Target Group Attachment**:

  - EC2 instances are registered with the ALB's target group using `aws_lb_target_group_attachment`.
  - Health checks ensure that only healthy instances receive traffic.

- **Security Groups**:

  - The EC2 instances' security group allows traffic from the ALB's security group.
  - The ALB's security group allows inbound traffic from the internet on port 80.

### EC2 and RDS Integration

- **Database Connectivity**:

  - EC2 instances connect to the RDS instance using the endpoint provided by RDS.
  - Security groups allow inbound traffic to RDS from the EC2 instances.

- **Credential Management**:

  - Database credentials are securely retrieved from SSM Parameter Store by the application running on EC2 instances.

### NAT Gateways and Internet Access

- **Outbound Traffic from Private Subnets**:

  - Instances in private subnets route internet-bound traffic through the NAT Gateways.
  - Each private subnet is associated with a route table pointing to the NAT Gateway in the same AZ.

- **High Availability**:

  - Multiple NAT Gateways ensure that if one AZ fails, resources in other AZs can still access the internet.

### High Availability and Fault Tolerance

- **Multi-AZ Deployment**:

  - Resources like RDS and NAT Gateways are spread across multiple AZs.

- **Load Balancing**:

  - ALB automatically distributes traffic, improving availability and scalability.

- **Automatic Failover**:

  - In case of instance failure, ALB routes traffic to other healthy instances.

- **Resilient Networking**:

  - Multiple NAT Gateways and route tables prevent single points of failure in internet connectivity.

---

## Challenges and Solutions

### Challenge 1: Invalid BASE64 Encoding for `user_data`

**Issue**:

- The launch template failed to execute the `user_data` script due to improper BASE64 encoding.

**Solution**:

- Used Terraform's `base64encode` function to correctly encode the `user_data` script.
- Ensured that the script is properly formatted and encoded before being passed to the launch template.

**Explanation**:

- AWS expects the `user_data` field to be base64-encoded.
- Incorrect encoding leads to errors during instance initialization.

### Challenge 2: Replacing EC2 Instances on Every Apply

**Issue**:

- EC2 instances were being replaced on every `terraform apply` due to changes in security group IDs.

**Explanation**:

- Terraform considers certain resource attributes as immutable.
- Changing these attributes requires resource replacement.
- Dynamically generating security groups or modifying them caused Terraform to replace associated resources.

**Solution**:

- Defined fixed security group IDs and managed security group rules separately.
- By keeping the security group ID constant, Terraform did not detect changes that required resource replacement.
- Used `aws_security_group_rule` resources to manage rules without recreating security groups.

**Result**:

- Prevented unnecessary instance replacement, saving time and avoiding potential downtime.

### Challenge 3: No Registered Targets in ALB

**Issue**:

- The ALB's target group had no registered targets, so traffic was not being routed to EC2 instances.

**Solution**:

- Implemented the `aws_lb_target_group_attachment` resource in Terraform.
- Dynamically registered EC2 instances with the ALB's target group.

**Code Example**:

```hcl
resource "aws_lb_target_group_attachment" "ec2_targets" {
  count            = length(module.ec2.instance_ids)
  target_group_arn = module.alb.target_group_arn
  target_id        = module.ec2.instance_ids[count.index]
  port             = 80
}
```

**Explanation**:

- Loops through EC2 instance IDs to attach each one to the target group.
- Ensures that as instances are added or removed, the target group is updated accordingly.

**Result**:

- The ALB successfully routed traffic to the registered EC2 instances.
- Health checks could now monitor instance health, enhancing reliability.

---

## Future Enhancements

1. **Monitoring and Alerts**:

   - **Implement CloudWatch**: Set up detailed monitoring for EC2, RDS, and ALB.
   - **Create Alarms**: Trigger notifications for metrics like CPU utilization, memory usage, disk space, or unhealthy instances.
   - **Integrate with AWS SNS**: Send alerts via email or SMS for critical events.

2. **Auto Scaling**:

   - **EC2 Auto Scaling Group (ASG)**: Automatically adjust the number of instances based on demand.
   - **Scaling Policies**: Define policies for scaling out (adding instances) and scaling in (removing instances) based on metrics.

3. **Enhanced Security**:

   - **SSL/TLS Termination**: Implement HTTPS by adding SSL certificates to the ALB.
   - **Web Application Firewall (WAF)**: Protect against common web exploits and attacks.
   - **IAM Roles and Policies**: Fine-tune permissions for AWS resources.

4. **Comprehensive CI/CD**:

   - **Infrastructure Pipeline**: Automate Terraform execution with approval gates.
   - **Application Deployment Tools**: Use AWS CodeDeploy, Ansible, or Docker for more robust deployment processes.
   - **Rollback Mechanisms**: Implement strategies to revert to previous stable states in case of failures.

5. **Infrastructure Refactoring**:

   - **Terraform Modules**: Refactor code into reusable, parameterized modules for better organization.
   - **Version Control**: Tag releases and maintain versioned infrastructure code.

6. **Cost Optimization**:

   - **Reserved Instances or Savings Plans**: Reduce costs for long-running instances.
   - **Right-Sizing Resources**: Monitor resource utilization to choose appropriate instance types.

7. **Database Enhancements**:

   - **Read Replicas**: Improve read performance by adding read replicas.
   - **Backup and Recovery**: Implement automated backups and test recovery procedures.

---

## Frequently Asked Questions (FAQ)

**Q1: Why use multiple NAT Gateways instead of one?**

**A**: Using multiple NAT Gateways, one per Availability Zone (AZ), enhances fault tolerance and reduces latency. If an AZ becomes unavailable, resources in other AZs can still access the internet through their local NAT Gateway. Additionally, this avoids cross-AZ data transfer costs and improves performance.

---

**Q2: Why are the EC2 instances placed in public subnets while the RDS is in private subnets?**

**A**: EC2 instances serving web content need to be accessible from the internet, hence they are in public subnets. The RDS database does not need to be directly accessible from the internet and is placed in private subnets to enhance security by limiting exposure.

---

**Q3: What is the purpose of the NAT Gateways in this architecture?**

**A**: NAT Gateways enable instances in private subnets to initiate outbound traffic to the internet (e.g., for software updates) while preventing inbound traffic from the internet to those instances.

---

**Q4: How does the Application Load Balancer improve application availability?**

**A**: The ALB distributes incoming traffic across multiple instances, ensuring that if one instance fails, others can handle the load. It also performs health checks to route traffic only to healthy instances, improving reliability.

---

**Q5: How are database credentials securely managed?**

**A**: Credentials are stored in AWS SSM Parameter Store, which provides secure, hierarchical storage for configuration data management. Access is controlled via IAM roles and policies, allowing EC2 instances to retrieve credentials securely.

---

**Q6: How do EC2 instances in public subnets access the RDS in private subnets?**

**A**: EC2 instances and RDS are within the same VPC, allowing them to communicate over private IP addresses. Security groups are configured to allow traffic from the EC2 instances to the RDS on the necessary port.

---

**Q7: Can this architecture handle sudden spikes in traffic?**

**A**: Currently, the architecture can handle moderate fluctuations. Implementing Auto Scaling Groups (ASGs) and scaling policies would enable the system to automatically adjust to sudden spikes in traffic.

---

**Q8: How is security enforced between components?**

**A**: Security is enforced using security groups and network ACLs that define inbound and outbound traffic rules. Resources in private subnets are not accessible from the internet, and least privilege principles are applied to IAM roles and policies.

---

**Q9: What are the benefits of Multi-AZ deployment for RDS?**

**A**: Multi-AZ deployment provides enhanced availability and durability by automatically replicating data to a standby instance in a different AZ. In case of an infrastructure failure, RDS can failover to the standby without manual intervention.

---

**Q10: Why is an IAM Instance Profile used for EC2 instances?**

**A**: An IAM Instance Profile allows EC2 instances to assume an IAM role, granting them permissions to access AWS services securely (e.g., SSM Parameter Store). This avoids hardcoding credentials and enhances security.

---

## Conclusion

This project demonstrates the implementation of a robust, scalable, and secure two-tier architecture on AWS, utilizing Infrastructure as Code with Terraform and automating deployments with GitHub Actions. By integrating detailed explanations from the `main.tf` configuration, we gain a comprehensive understanding of each component's role, how they interact, and the underlying theory. Future enhancements can further optimize the architecture for production workloads, improve scalability, security, and operational efficiency.

---