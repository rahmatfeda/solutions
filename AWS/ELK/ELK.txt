You are asked to build an Elasticsearch cluster and Kibana server in cloud (AWS) to collect logs.

Please consider following questions when you design the solution.

    How to provision the cluster in 30 miniutes
        I will add the code on how to provision ES on AWS.
    How to scale up or down the cluster
        AWS will scale it.
    How to prevent unauthorized access to the cluster
        ES support AWS IAM based Access control and for Kibana we need to use other solution such as proxy.
    How to ship logs from application to the elasticsearch cluster
        AWS support to put the ES within your VPC so your application can access privately using normal http methods (get,put,delete,...) with correct defined authentication and permision, which we have defined in the IAM Role access policy for Elasticsearch
    What about if the applications are running in multiple regions, (one system in us-east-1 and one system in us-west-2)
        since in this solution we use AWS managed ES - AWS support to place Elastic network interface with the VPC in different regions.
Design your solution in detail, estimate the effort required. Please implement part of the solution designed above, commit it into a repo and share it with us.

currently almost for all Database services there are three ways to provision and use in the industry:

1- locally deploy ELK cluster in AWS
2- use thirdparty managed ELK
3- AWS managed ELK and Kibana services

to decide which is solution is better depends on use case and application, each of above options has it's own pros and cons. I wil choose AWS managed ELK cluster just for it that it will require minimum deployment and mnanagement effort and for small to medium busniess it will be cost effective.
Amazon Elasticsearch Service Provide all above requirement above such as scalebility, monitoring, security and etc...


