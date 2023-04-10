# vpc with terraform

- The current version is the minimum viable product, a basic EC2 instance with security group and public IP address, ready to host the web application like on a regular web hosting.
- For temporary, testing purposes the web server will use plain text http instead of ssl encryption. This of course will be reconfigured as I figure out how to set up the dns, tls, etc.
- Every resource related to the VPC service is in the project name/terraform.vpc.tf
- Initially I use the default vpc with public ip address for the ec2 instance, further network configuration, security hardening comes later.

## Security groups

The project security group simply allows incoming ssh and http access to manage and serve content, and allow all outgoing connection.
