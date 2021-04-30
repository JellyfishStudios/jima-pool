# Jima
Jima, a Cardano stakepool hosted on AWS in Japan.

#### Deploy a new stack (green)

aws cloudformation create-stack --stack-name Jima \
	--region ap-northeast-1 \
	--template-body file://infrastructure.yaml \
	--parameters \
		ParameterKey=RelayNodeInstanceType,ParameterValue=t3.medium \
		ParameterKey=RelayNodeKeyName,ParameterValue=RelayNodes \
		ParameterKey=BlockProducerInstanceType,ParameterValue=t3.large \
		ParameterKey=BlockProducerKeyName,ParameterValue=BlockProducer \
		ParameterKey=CardanoNodeBootstrap,ParameterValue=$(bootstrap/cardanonode.sh)