#!/bin/bash
set -e

REGION="eu-west-1"
STACK_PREFIX="detection-api"

echo "=============================================="
echo "  Object Detection API - AWS Cleanup"
echo "  Region: ${REGION}"
echo "=============================================="
echo ""
echo "This will delete EC2, security groups, and networking resources."
echo "The Elastic IP will be kept."
echo ""
read -p "Continue? (y/N): " confirm

if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI not installed."
    exit 1
fi

echo ""
echo "[1/4] Deleting API Gateway Stack..."
if aws cloudformation describe-stacks --stack-name "${STACK_PREFIX}-api-gateway" --region ${REGION} > /dev/null 2>&1; then
    aws cloudformation delete-stack \
        --stack-name "${STACK_PREFIX}-api-gateway" \
        --region ${REGION}
    echo "Waiting..."
    aws cloudformation wait stack-delete-complete \
        --stack-name "${STACK_PREFIX}-api-gateway" \
        --region ${REGION}
    echo "Done"
else
    echo "Skipped (not found)"
fi

echo ""
echo "[2/4] Deleting EC2 Stack..."
if aws cloudformation describe-stacks --stack-name "${STACK_PREFIX}-ec2" --region ${REGION} > /dev/null 2>&1; then
    aws cloudformation delete-stack \
        --stack-name "${STACK_PREFIX}-ec2" \
        --region ${REGION}
    echo "Waiting..."
    aws cloudformation wait stack-delete-complete \
        --stack-name "${STACK_PREFIX}-ec2" \
        --region ${REGION}
    echo "Done"
else
    echo "Skipped (not found)"
fi

echo ""
echo "[3/4] Deleting Security Stack..."
if aws cloudformation describe-stacks --stack-name "${STACK_PREFIX}-security" --region ${REGION} > /dev/null 2>&1; then
    aws cloudformation delete-stack \
        --stack-name "${STACK_PREFIX}-security" \
        --region ${REGION}
    echo "Waiting..."
    aws cloudformation wait stack-delete-complete \
        --stack-name "${STACK_PREFIX}-security" \
        --region ${REGION}
    echo "Done"
else
    echo "Skipped (not found)"
fi

echo ""
echo "[4/4] Deleting Network Stack..."
if aws cloudformation describe-stacks --stack-name "${STACK_PREFIX}-network" --region ${REGION} > /dev/null 2>&1; then
    aws cloudformation delete-stack \
        --stack-name "${STACK_PREFIX}-network" \
        --region ${REGION}
    echo "Waiting..."
    aws cloudformation wait stack-delete-complete \
        --stack-name "${STACK_PREFIX}-network" \
        --region ${REGION}
    echo "Done"
else
    echo "Skipped (not found)"
fi

echo ""
echo "=============================================="
echo "  Cleanup Complete"
echo "=============================================="
