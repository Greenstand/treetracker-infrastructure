# What is BotKube?
A Slack bot that monitors k8s resources in the cluster. There is a BotKube agent that needs to be deployed in the cluster in order to use this Slack bot. It will post notifications in a configured slack channel when a resource is updated (created, destroyed, patched, change in health state, etc).

## Official Documentation
https://www.botkube.io/

# Installing BotKube in a k8s cluster
- Prequisite: Add Slack bot to Slack organization (see official documentation)
- Create the botkube namespace:  
`kubectl create ns botkube`
- Using helm 3, run this command:  
`helm install --version v0.12.0 botkube --namespace botkube  
  --set communications.slack.enabled=true 
  --set communications.slack.channel=<SLACK_CHANNEL_NAME>
  --set communications.slack.token=<SLACK_API_TOKEN_FOR_THE_BOT>
  --set config.settings.clustername=<CLUSTER_NAME>
  --set config.settings.kubectl.enabled=<ALLOW_KUBECTL>
  --set image.repository=infracloudio/botkube 
  --set image.tag=v0.12.0 
  infracloudio/botkube`



