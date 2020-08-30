OUTPUT_BASE_PATH := $(PWD)/outputs

VPC_JSON_PATH                           := $(OUTPUT_BASE_PATH)/vpc.json
VPC_SUBNETS_FOR_PUBLIC_JSON_PATH        := $(OUTPUT_BASE_PATH)/vpc-subnets-for-public.json
INTERNET_GATEWAY_JSON_PATH              := $(OUTPUT_BASE_PATH)/internet-gateway.json
CUSTOM_ROUTE_TABLE_FOR_PUBLIC_JSON_PATH := $(OUTPUT_BASE_PATH)/custom-route-table-for-public.json
SECURITY_GROUP_FOR_PUBLIC_JSON_PATH     := $(OUTPUT_BASE_PATH)/security-group-for-public.json
INSTANCE_PROFILE_FOR_PUBLIC_JSON_PATH   := $(OUTPUT_BASE_PATH)/instance-profile-for-public.json
IAM_ROLE_FOR_INSTANCE_PROFILE_PUBLIC_JSON_PATH := $(OUTPUT_BASE_PATH)/iam-role-for-instance-profile-public.json
IAM_POLICIES_FOR_ROLE_INSTANCE_PROFILE_PUBLIC_JSON_PATH := $(OUTPUT_BASE_PATH)/iam-policies-for-role-instance-profile-public.json

ASSUME_ROLE_POLICY_FILE_PATH := $(PWD)/ec2-role-trust-policy.json
