# Uninstalling the add-on destroys this attachment and revokes Session Manager
# access. The VM template must not manage this role's policies exclusively.
#
# VERIFY: the current AmazonSSMManagedInstanceCore policy allows Session
# Manager (ssmmessages) and ssm:GetDeployablePatchSnapshotForInstance, and it
# does not allow s3:GetObject. This module assumes that is enough for the
# instance to register with Systems Manager and for AWS-RunPatchBaseline to
# install patches over the VM's HTTPS egress. Confirm during the patch test.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = local.instance_role_name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"

  lifecycle {
    precondition {
      condition     = data.tfe_outputs.application.nonsensitive_values.aws_region == var.aws_region
      error_message = "aws_region must match the application output aws_region. The add-on calls Systems Manager in that region."
    }
  }
}
