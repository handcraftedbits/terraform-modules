# Create template for Swagger doc
# Create API Gateway definition
# Create permission for API Gateway to call rebuild lambda
# Create API deployment
# Create custom domain name for API
# Create base path mapping for API
# Create Route53 record for custom domain name

data "template_file" "swagger" {
  template = "${file("${path.module}/templates/swagger/rebuild.yaml")}"

  vars {
    lambda_arn = "${aws_lambda_function.rebuild.invoke_arn}"
    region     = "${var.region}"
    site_name  = "${var.site_name}"
  }
}

resource "aws_api_gateway_base_path_mapping" "rebuild" {
  api_id      = "${aws_api_gateway_rest_api.rebuild.id}"
  domain_name = "${aws_api_gateway_domain_name.api.domain_name}"
  stage_name  = "${aws_api_gateway_deployment.rebuild.stage_name}"

  base_path = "webhooks-${var.site_name}"
}

resource "aws_api_gateway_deployment" "rebuild" {
  description       = "Production deployment"
  rest_api_id       = "${aws_api_gateway_rest_api.rebuild.id}"
  stage_description = "Production"
  stage_name        = "production"
}

resource "aws_api_gateway_domain_name" "api" {
  domain_name              = "${var.webhooks_subdomain}.${var.site_name}"
  regional_certificate_arn = "${data.aws_acm_certificate.site.arn}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_rest_api" "rebuild" {
  name        = "${var.site_name}-rebuild"
  description = "Rebuild webhook for ${var.site_name}"

  body = "${data.template_file.swagger.rendered}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_lambda_permission" "rebuild" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.rebuild.function_name}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.rebuild.id}/*/POST/rebuild"
  statement_id  = "AllowExecutionFromAPIGateway"
}

resource "aws_route53_record" "webhooks" {
  zone_id = "${data.aws_route53_zone.site.id}"

  name = "${var.webhooks_subdomain}.${var.site_name}"
  type = "A"

  alias {
    name                   = "${aws_api_gateway_domain_name.api.regional_domain_name}"
    zone_id                = "${aws_api_gateway_domain_name.api.regional_zone_id}"
    evaluate_target_health = false
  }
}
