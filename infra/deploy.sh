#!/bin/bash
set -e

REGION="eu-west-1"
STACK_PREFIX="detection-api"
KEY_PAIR_NAME="${1:-}"

echo "=============================================="
echo "  Object Detection API - Deploy"
echo "  Region: ${REGION}"
echo "=============================================="

if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI not installed."
    exit 1
fi

echo ""
echo "[1/6] Checking credentials..."
aws sts get-caller-identity --region ${REGION} > /dev/null 2>&1 || {
    echo "ERROR: AWS credentials not configured."
    exit 1
}
echo "OK"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
echo "[2/6] Deploying Network..."
aws cloudformation deploy \
    --template-file "${SCRIPT_DIR}/network.yaml" \
    --stack-name "${STACK_PREFIX}-network" \
    --region ${REGION} \
    --capabilities CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset
echo "Done"

echo ""
echo "[3/6] Deploying Security..."
aws cloudformation deploy \
    --template-file "${SCRIPT_DIR}/security.yaml" \
    --stack-name "${STACK_PREFIX}-security" \
    --region ${REGION} \
    --capabilities CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset
echo "Done"

echo ""
echo "[4/6] Deploying Elastic IP..."
aws cloudformation deploy \
    --template-file "${SCRIPT_DIR}/eip.yaml" \
    --stack-name "${STACK_PREFIX}-eip" \
    --region ${REGION} \
    --capabilities CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset
echo "Done"

echo ""
echo "[5/6] Deploying EC2..."
EC2_PARAMS=""
if [ -n "${KEY_PAIR_NAME}" ]; then
    EC2_PARAMS="--parameter-overrides KeyPairName=${KEY_PAIR_NAME}"
fi

aws cloudformation deploy \
    --template-file "${SCRIPT_DIR}/ec2.yaml" \
    --stack-name "${STACK_PREFIX}-ec2" \
    --region ${REGION} \
    --capabilities CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset \
    ${EC2_PARAMS}
echo "Done"

echo ""
echo "[6/6] Deploying API Gateway..."
aws cloudformation deploy \
    --template-file "${SCRIPT_DIR}/api-gateway.yaml" \
    --stack-name "${STACK_PREFIX}-api-gateway" \
    --region ${REGION} \
    --capabilities CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset
echo "Done"

echo ""
echo "=============================================="
echo "  Deployment Complete"
echo "=============================================="

PUBLIC_IP=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_PREFIX}-ec2" \
    --region ${REGION} \
    --query "Stacks[0].Outputs[?OutputKey=='PublicIP'].OutputValue" \
    --output text)

API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_PREFIX}-ec2" \
    --region ${REGION} \
    --query "Stacks[0].Outputs[?OutputKey=='APIEndpoint'].OutputValue" \
    --output text)

HTTPS_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_PREFIX}-api-gateway" \
    --region ${REGION} \
    --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" \
    --output text)

echo ""
echo "Public IP:  ${PUBLIC_IP}"
echo "HTTP:       ${API_ENDPOINT}"
echo ""
echo "HTTPS (use this): ${HTTPS_ENDPOINT}"
echo ""
echo "Health: ${HTTPS_ENDPOINT}/health"
echo ""
echo "API starting... wait 5-10 min then check health endpoint."
