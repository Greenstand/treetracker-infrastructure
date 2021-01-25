# treetracker-infrastructure

Cloud infrastructure for the treetracker project

## Road Map

https://github.com/orgs/Greenstand/projects/9

Milestone 1 - Near Term:
* Dockerize all microservices
* Set up and standardize automatic semantic versioning on all microservices
* Deploy all static web resources via CDN
* Deploy all microservices into kubernetes
* Mount all microservice APIs on Ambassador (API Gateway)

Milestone 2 - Prepare Test Environment:
* Deploy all services into test environment k8s
* Tweak grafana/prometheus service
* Deploy ELK stack docker created by @Mengchen into dev/test environments
* Connect all microservices logging to ELK stack


## Deploying a New Environment
1. Create a new k8s cluster (./kubernetes terraform)
2. Deploy Ambassador API gateway into this environment
3. Deploy Monitoring - prometheus and grafana
4. Deploy RabbitMQ operator
5. Deploy Sealed Secrets CRD and Controller
