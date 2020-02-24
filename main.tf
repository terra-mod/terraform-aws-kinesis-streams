/**
 * # AWS Kinesis Streams
 *
 * This module creates one or more Kinesis Streams based on the set of objects passed from the `streams` input variable.
 *
 * Each Kinesis Stream has the two IAM Policies generated which allow access to Read and Write to the Kinesis Stream and
 * the policies should be attached to the IAM Roles of any Consumers or Producers.
 *
 * Encryption is not enabled by default, but should be used in a production environment. If the `use_encryption` input
 * variable is set to true, a user-generated KMS Master key will be created for each Stream and the IAM Policies will
 * provide proper access to Consumers and Producers to decrypt or generate data for that KMS Key.
 *
 * ### Usage
 *
 *      module streams {
 *        source = "{source}"
 *
 *        environment    = "prod"
 *        namespace      = "events"
 *        use_encryption = true
 *
 *        streams = [
 *          {
 *            name = "log-events"
 *          },
 *          {
 *            name             = "auction-events"
 *            shard_count      = 2
 *            retention_period = 168
 *          },
 *          {
 *            name                      = "model-events"
 *            shard_count               = 1
 *            retention_period          = 24
 *            enforce_consumer_deletion = false
 *          }
 *        ]
 *      }
 */

terraform {
  required_version = "~> 0.12"
}

locals {
  // Sets default values for the streams
  stream_defaults = {
    retention_period          = "24"
    shard_count               = "1"
    enforce_consumer_deletion = "true",
    shard_level_metrics       = "IncomingBytes, OutgoingBytes"
  }

  // Set the default tags that should always be included - this is merged
  // on top of user defined tags, so conventions cannot be accidentally overwritten by user supplied tags.
  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Namespace   = var.namespace
  })

  // Set default options for the streams and merge any overrides on top.
  streams = { for stream in var.streams : stream.name => merge(local.stream_defaults, stream) }

  // Create a set for the KMS Keys, only when use_encryption is true.
  kms_keys = toset([for stream in var.streams : stream.name if var.use_encryption == true])
}

/**
 * Generate a KMS Encryption key for the streams when `use_encryption` is requested.
 */
resource aws_kms_key key {
  for_each = local.kms_keys

  description = "Encryption key for kinesis stream ${var.namespace}-${each.value}-stream"
  tags        = local.tags
}

/**
 * Create a Kinesis Stream for each item in the streams input variable.
 */
resource aws_kinesis_stream streams {
  for_each = local.streams

  name        = "${var.namespace}-${each.key}-stream"
  shard_count = lookup(each.value, "shard_count")

  retention_period          = lookup(each.value, "retention_period")
  enforce_consumer_deletion = lookup(each.value, "enforce_consumer_deletion")

  # For now, keeping the metrics to a set value, this could be configurable later.
  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  encryption_type = var.use_encryption ? "KMS" : "NONE"
  kms_key_id      = var.use_encryption ? aws_kms_key.key[each.key].id : null

  tags = local.tags
}

/**
 * Create an IAM Policy that grants Read Only access to the Stream - used for Consumers.
 */
resource aws_iam_policy read_only {
  for_each = local.streams

  name        = "${var.namespace}-${each.key}-read-only"
  path        = "/kinesis-streams/${var.namespace}/"
  description = "Allows Read Only access to ${aws_kinesis_stream.streams[each.key].name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeLimits",
          "kinesis:DescribeStream",
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:SubscribeToShard",
        ]
        Resource = [
          aws_kinesis_stream.streams[each.key].arn
        ]
      }
      ], var.use_encryption ? [{
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = aws_kms_key.key[each.key].arn
    }] : [])
  })
}

/**
 * Create an IAM Policy that grants Read and Write access to the Stream - used for Producers.
 */
resource aws_iam_policy read_write {
  for_each = toset(keys(local.streams))

  name        = "${var.namespace}-${each.key}-read-write"
  path        = "/kinesis-streams/${var.namespace}/"
  description = "Allows Read Only access to ${aws_kinesis_stream.streams[each.key].name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeLimits",
          "kinesis:DescribeStream",
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:SubscribeToShard",
          "kinesis:PutRecord*"
        ]
        Resource = [
          aws_kinesis_stream.streams[each.key].arn
        ]
      }
      ], var.use_encryption ? [{
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.key[each.key].arn
    }] : [])
  })
}