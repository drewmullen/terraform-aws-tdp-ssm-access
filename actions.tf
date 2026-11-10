# Not bound to an action_trigger. A normal apply does not patch the VM.
# TDP lists this as aws_lambda_invoke.patch_now.
#
# Schema checked against hashicorp/aws 6.14.0 (terraform providers schema -json):
# function_name and payload are required. log_type Tail prints the command id
# on the action run. The instance id is read inside the function, not passed here.
action "aws_lambda_invoke" "patch_now" {
  config {
    function_name   = aws_lambda_function.patch_now.function_name
    invocation_type = "RequestResponse"
    log_type        = "Tail"
    payload         = jsonencode({})
  }
}
