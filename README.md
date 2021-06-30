# Cardano Jima

Cardao Jima, a Cardano stakepool hosted on AWS in Japan.

#### Deploy a new stack

Deploys a complete stack including VPC, internet gateway, EC2 nodes, etc., and bootstraps and configuresour generic Cardano Node docker container to both the relay and producer instances.

See cloudformation-templates/deploy.yml for a complete list of supported parameters.

```
aws cloudformation create-stack --stack-name Jima \
	--region ap-northeast-1 \
	--template-body file://infrastructure.yaml \
	--parameters \
		ParameterKey=RelayNodeInstanceType,ParameterValue=t3.medium \
		ParameterKey=RelayNodeKeyName,ParameterValue=RelayNodes \
		ParameterKey=BlockProducerInstanceType,ParameterValue=t3.large \
		ParameterKey=BlockProducerKeyName,ParameterValue=BlockProducer
```