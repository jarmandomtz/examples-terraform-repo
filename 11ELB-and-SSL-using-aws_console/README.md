# Usage of ELB
On the deployment, we are going to change the Apache by ELB service

When to use NLB
- If you need to manage TCP connections or you need to control the public IP of your balancer instead. You cannot use SSL feature with this type of balancer

Example adding user authentication using Auth0 [here](./UserAuthenticationWithAuth0.md)

## Configuration using AWS Console

Steps required,
- Modify SG on EC2 instance, open to the CIDR
- Create ALB and connect to the EC2 instance
- Test using the ALB DNS
- Remove Apache from the EC2 instance
- Install the SSL certificate

Steps in Detail,
- Modify SG on EC2 instance, open to the CIDR
AWS Console -> EC2 Console -> Select EC2 instance -> Security -> Select Security Group -> Edit Inbound rules
source: 172.31.0.0/16

- Create ALB and connect to the EC2 instance
AWS Console -> ELB Console -> Create Balancer
  Name: break-the-monolith
  Type: Internet-facing
  VPC: Out VPC
  AZ: us-east-1a, us-east-1b and Next

  Select: Create a new security group
  Name: break-the-monolith-sg
  Rule: Custom TCP, TCP, 80, 0.0.0.0/0, ::/0 # Open to the IPv4 and IPv6 world
  Next
 
  Target group: new target group
  Name: break-the-monolith
  Protocol: http
  Port: 8080
  Target type: instance
  Healt check
    Protocol: HTTP
    Path: /visits

  Instances
    Select EC2 instance and click Add to registered on port 8080

  Instace should become healty on the ELB
- Test using the ALB DNS
  curl -h http://break-the-monolith-[ALBId].us-east-1.elb.amazonaws.com/visits

- Remove Apache from the EC2 instance

```js
%> ssh -i .ssh/id_key ec2-user@app.esausi.com
% app> sudo yum remove httpd

```
   Modification on on terraform module/main.tf
   * Cancel apache installation
   * Delete Inbound rule on 80 port

- Install the SSL certificate
AWS Console -> AWS Certificate Manager Console -> Provision certificates
  Request a certificate: Request a public certificate and Next

  Add domain names
    esausi.com
    *.esausi.com  and Next

 Validation
   DNS validation and Review

 Create record in Route 53 button and Create button

 In less than a minute, status of new SSL certificate will be issued and will become available for use
 Now it is possible to add the new certificate to your balancer and use an SSL listener

Open the SG on ALB for the port 443
  AWS Console -> ELB Console -> Select ALB -> Select the SG -> Inbound rules -> Edit Inbound rules
   Add: HTTPS, TCP, 443, 0.0.0.0/0, ::/0
  
  Listerners tab, Add listener
    Procol-Port: HTTPS-443
    Default action: Forward to "break-the-monolith"
    Default SSL Certificate: From ACM - Select created certificate

### ALB vs NLB
NLB is designed to handle tens of millions of request per second while maintaining high througput at ultra-low latency, with no effort on the customer's part. As a result, no pre-warm is needed.

ALB instead follows the same rules as CLB.

NLB doesn't require pre-warming. However, CLB and ALB still need it.

## Test app on security URL

```js
%> curl -h https://app-elb.esausi.com/visits

```

