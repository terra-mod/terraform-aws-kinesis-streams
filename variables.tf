variable namespace {
  description = "The namespace or service name the streams are created for."
  type        = string
}

variable environment {
  description = "The environment the streams are created for."
  type        = string
}

variable streams {
  description = "A set of stream objects to define Kinesis Streams."
  type = set(map(string))
}

variable use_encryption {
  description = "Whether the streams should be be encrypted using a user-generated KMS key."
  type        = bool
  default     = false
}

variable tags {
  description = "Any additional tags that should be added to taggable resources created by this module."
  type        = map(string)
  default     = {}
}