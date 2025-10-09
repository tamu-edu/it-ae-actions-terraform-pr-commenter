ARG TERRAFORM_VERSION=1.0.6
FROM hashicorp/terraform:${TERRAFORM_VERSION}

RUN apk add --no-cache -q \
    bash \
    curl \
    perl \
    jq
 
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
