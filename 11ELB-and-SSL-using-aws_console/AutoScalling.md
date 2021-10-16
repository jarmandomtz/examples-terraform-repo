# AutoScalling application

For enable the autoscaling capability on our web app running over EC2, it is required give autoscaling capabilities to every layer of the app,
- Balancer
- Web application
- Database

## AutoScaling web app

For allow Autoscaling works in our Web app, it is required to kmove the files to a central service and not keep it on the instance,
- EFS: NFS mounted directly to the EC2 instance
- S3: Object storage designed to deliver 99.9x9% durability

When we need to scale up, it is better to crate an image with all the software and configuration files installed, and then insert the parameter or the configuration files that need to be pased at runtime to the user_data

Steps for create an image,
- Stop the EC2 instance
- Properties -> Image -> Create image
  Image name: break-the-monolith
  Image description: the image will be use in a launch configuration

  In a short period of time, our 8Gb image will be ready

Scallable application ![App](./imgs/app01.png)

## Setup autoscaling in AWS EC2

Objects required,
- Launch configuration
- Auto scaling group

Click on Auto scaling groups option and an automatic wizard will then start to create the necessary resources
**Launch configuration**
  My AMIs: Select image previously created and Next
  Name: break-the-monolith 

**Auto Scalling group**
  Group name: break-the-monolith
  Group size: start with 1
  Network: Chose the VPC
  Subnet: Chose any set of subnets

- Security group
  Chose the EC2 instance SG

- Key pair
  Use our previously created Key pair

- Create auto scaling group
**Scaling policies**
We are going to create policies following this conditions,
  - If the CPU usage is below 70% for more than 5 minutes, add 1 instance
  - If the CPU usage is lower than 40% for more than 5 minutes, remove 1 instance
  - Create two alarms and asociate this to the ASG
    ![alarms](./imgs/alarms01.png)
  Select: Use scaling policies to adjust the capacity ot this group

   ![policies](./imgs/policies01.png)

**Modifying the Auto Scaling Group**
Launch configuratio is read only, changes just in a new object.
Auto Scaling group is editable. 

We need to modify the Auto Scaling group because we want each instance to be registered to the target group associated with our ALB
Target group: break-the-monolith
Min: 2

**Remove the manually created instance from the balancer**
ELB -> Targets -> Edit -> Select Instance -> Remove

At this point, the configuration of the Auto Scale is complete and you now have an application that satisfies the requirements of scalability and reliability.

## Questions

Is it always convenient to break a monolith into a multi-level application?
R. In case of scaling requirements were vertical scaling does not cover the requirements or is too expensive to accomplish.

What are the differences between the multi-level approach and the microservices/serverless approach?
R. Multi-level approach is using resources always on, microservices/serverles are ondemand

Can it be difficult moving from software installed in a virtual machine to as a service components? 
R. If it is part of the existing runtimes on AWS, is just a matter of move the executable

Can a load balancer manage any spike of traffic without any intervention?
R. No, it is required to configure AutoScaling functionality

Can I save money using Certificate Manager instead of a classic SSL certification authority?
R. Sure, CM is free

Why is it important to span the resources in multiple AZs?
R. Improve the availability and failover of the application

## Further reading

Spring Boot, MySQL, JPA, Hibernate Restful CRUD API Tutorial: https://www.callicoder.com/spring-boot-rest-api-tutorial-with-mysql-jpa-hibernate/ the tutorial used to create our playground. 
Serverless is cheaper, not simpler: https://medium.freecodecamp.org/serverless-is-cheaper-not-simpler-a10c4fc30e49 