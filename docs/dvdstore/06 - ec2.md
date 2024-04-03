# ec2 with terraform

The current version is the minimum viable product, a basic EC2 instance with security group and public IP address, ready to host the web application like on a regular web hosting.

For temporary, testing purposes the web server will use plain text http instead of ssl encryption. This of course will be reconfigured as I figure out how to set up the dns, tls, etc.

Every resource related to the EC2 service is in the project name/terraform.ec2.tf

## Operating system of the project

In general I have Linux experience so the server will also use Linux as operating system.

I will use Amazon Linux 2 as the base distribution, I'm more interested in learning about AWS specific software and I hope it have better integration than any other general distribution. My other preferences were Rocky Linux (as RHEL compatible distro) and Ubuntu.

Additionally I choose version 2 over version 2023 as the latter one is pretty new and for example doesn't contains ansible yet. Based on the faq, features like ansible will come sometime in the future, but I prefer stable, well tested, documented versions over shiny new.

## search for image id

We will need to define the image id in terraform. The easier way is to open the ami catalog in the EC2 service web page and it will display recommended images.

Additionally we can search for images via cli, a good filter is recommended as amazon have more than 10.000 images in one region.

```bash
aws ec2 describe-images --owners self amazon --filters "Name=description,Values=Amazon Linux 2*202304*x86_64*"
```

part of json output:

```bash
"ImageId": "ami-0cbfcdb45dcced1ca",
...
"Description": "Amazon Linux 2 Kernel 5.10 AMI 2.0.20230404.0 x86_64 HVM gp2",
```

The image id is needed in the terraform code.

## instance family

For testing purposes I choose t3.medium instance, it will provide 2 vcpu and 4gb memory, this will be sufficient.

The t3 family is unlimited by default this means the cpu usage for medium size is capped 20% by default and if the server is using more than that for a time then it will cost additional money.

- The base instance price is ~0.04$ / hour.
- The extra cpu usage is 0.05$ / cpu / hour.
- The total cost can be between ~0.4-0.14$ / hour which is around 15-50 huf.

Alternative instance types:

- t3a
  - same x86_64 architecture but with AMD CPU, the price is almost the same so I didn't bother with it.
- t4g
  - this is arm architecture, I'm not sure I won't run into various issues with non x86 architecture so I skip it
  - in 2023 there is a free 750 hour trial period for t4g.small (2 cpu, 2gb ram) instances but the cost will be negligible for me
