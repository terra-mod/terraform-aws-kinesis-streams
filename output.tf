output kinesis_streams {
  description = "A list of maps of the generated Kinesis Streams including the ARNs of the generated IAM Policies."
  value = [for k, v in aws_kinesis_stream.streams : zipmap(
    ["${k}-name", "${k}-arn", "${k}-reader-policy", "${k}-writer-policy"],
    [v.name,v.arn, aws_iam_policy.read_only[k].arn, aws_iam_policy.read_write[k].arn]
  )]
}

output kinesis_stream_arns {
  description = "A map of Kinesis Stream IDs keyed by the name."
  value       = { for k, v in aws_kinesis_stream.streams : k => v.arn }
}

output read_only_iam_policies {
  description = "A map of IAM Policies used for Read access to the Kinesis streams, key by the Stream name."
  value       = { for k, v in aws_iam_policy.read_only : k => v.arn }
}

output writer_iam_policies {
  description = "A map of IAM Policies used for Read & Write access to the Kinesis streams, key by the Stream name."
  value       = { for k, v in aws_iam_policy.read_write : k => v.arn }
}