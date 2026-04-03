# OCI IaC Layout

Wort-Werk OCI Terraform is split into two stacks.

- `foundation/`: one-time or infrequent environment provisioning
- `runtime/`: frequent application rollout by image tag

Apply order:
1. foundation
2. runtime
