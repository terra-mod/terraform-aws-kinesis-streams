# AWS Kinesis Streams

This module creates one or more Kinesis Streams based on the set of objects passed from the `streams` input variable.

Each Kinesis Stream has the two IAM Policies generated which allow access to Read and Write to the Kinesis Stream and  
the policies should be attached to the IAM Roles of any Consumers or Producers.

Encryption is not enabled by default, but should be used in a production environment. If the `use_encryption` input  
variable is set to true, a user-generated KMS Master key will be created for each Stream and the IAM Policies will  
provide proper access to Consumers and Producers to decrypt or generate data for that KMS Key.

### Usage

     module streams {  
       source = "{source}"

       environment    = "prod"  
       namespace      = "events"  
       use_encryption = true

       streams = [
         {  
           name = "log-events"  
         }, 
         {  
           name             = "click-events"  
           shard_count      = 2  
           retention_period = 168  
         },  
         {  
           name                      = "conversion-events"  
           shard_count               = 1  
           retention_period          = 24  
           enforce_consumer_deletion = false  
         }  
       ]  
     }

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| environment | The environment the streams are created in. | `string` | n/a | yes |
| platform | The namespace or service name the streams are created for. | `string` | n/a | yes |
| streams | A set of stream objects to define Kinesis Streams. | `set(map(string))` | n/a | yes |
| tags | Any additional tags that should be added to taggable resources created by this module. | `map(string)` | `{}` | no |
| use\_encryption | Whether the streams should be be encrypted using a user-generated KMS key. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| kinesis\_stream\_arns | A map of Kinesis Stream IDs keyed by the name. |
| kinesis\_streams | A list of maps of the generated Kinesis Streams with the ARNs of their generated IAM Policies. |
| read\_only\_iam\_policies | A map of IAM Policies used for Read access to the Kinesis streams, key by the Stream name. |
| writer\_iam\_policies | A map of IAM Policies used for Read & Write access to the Kinesis streams, key by the Stream name. |

