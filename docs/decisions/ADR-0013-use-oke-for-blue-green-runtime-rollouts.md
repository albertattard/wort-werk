# ADR-0013: Use OKE for Blue-Green Runtime Rollouts

## Status
Accepted

## Context

The current OCI runtime direction was intentionally scoped to a single Container Instance behind an OCI Load Balancer.
That was the right early production step, but it is now the wrong steady-state target for managed overlap deploys.

The new requirement is not just "run on Kubernetes".
It is specifically to replace the single-container runtime with a managed platform that can:

1. deploy a new version without interrupting live traffic,
2. verify application readiness before public cutover,
3. switch traffic between two distinct environments,
4. remove the old environment automatically after a successful cutover, and
5. keep OCI DevOps as the normal release control plane.

The clarified requirement is not "operate two isolated environments".
It is "keep the old version serving traffic until the new version is fully ready, then switch traffic and remove the old version."
That is a blue-green cutover problem, and the simplest clean switch point for it is a stable Kubernetes `Service` inside one production namespace.

## Decision

Adopt Oracle Kubernetes Engine (OKE) as the managed production runtime target for blue-green deployments, and model blue and green as two `Deployment` slots inside one stable production namespace.

The target structure is:

1. One OKE cluster for the application runtime.
2. One production namespace, `wortwerk-prod`.
3. Two application `Deployment` slots in that namespace, `wortwerk-blue` and `wortwerk-green`.
4. One stable application `Service`, `wortwerk-active`, whose selector identifies the live slot.
5. One stable public ingress boundary that targets `wortwerk-active`:
   - direct OCI load balancer-backed service when desired
   - or ingress-nginx for HTTP routing
6. A dedicated private Kubernetes API endpoint subnet instead of reusing the existing DevOps subnet.
7. A dedicated private OKE worker subnet instead of reusing the existing application runtime subnet.
8. Endpoint and worker subnet route tables that include Oracle Services Network access through the service gateway and default outbound internet egress through a NAT gateway.
9. Explicit OKE endpoint and worker subnet security rules for control-plane communication, Oracle services access, and path discovery.
10. A bastion-backed operator access path for private-cluster administration from outside the VCN.
11. OCI DevOps build pipeline for `./mvnw clean verify`, image build, and OCIR push.
12. OCI DevOps deploy pipeline for kubeconfig creation, inactive-slot deployment, readiness checks, `Service` selector switching, and old-slot teardown.

## Consequences

Positive:

- OKE becomes a better fit for managed overlap deploys and future horizontal scaling than a single Container Instance.
- The traffic switch is reduced to one cluster-local selector change instead of an OCI edge reconfiguration step.
- Readiness-gated cutover becomes a first-class deployment behavior instead of an implementation accident.
- OCI DevOps stays the deployment control plane instead of drifting back toward operator-laptop orchestration.
- OKE worker networking is isolated from the existing application runtime subnet, which avoids mixing container-instance assumptions with managed Kubernetes node requirements.
- The Kubernetes API endpoint receives its own private network boundary rather than sharing the DevOps runner subnet.
- Operator access to the private control plane becomes explicit and time-limited instead of relying on accidental direct reachability from a laptop.

Negative:

- The runtime architecture becomes more operationally complex than the original single-container path.
- Automatic deletion of the old slot removes immediate rollback-to-previous-pods convenience.
- One-namespace slots provide less isolation than separate namespaces would.
- The OKE migration needs additional private network infrastructure rather than reusing the existing runtime subnet unchanged.
- The OKE migration also needs explicit subnet-level security rules instead of relying on default VCN behavior.
- Operators need a bastion-backed bootstrap path whenever they administer the private cluster from outside the VCN.

Risks:

- If the rollout script flips the `Service` selector before the target Pods are actually Ready, traffic will move too early.
- If the public ingress path caches or pins endpoints outside Kubernetes service discovery, selector switching may not cut traffic over as expected.
- If OCI DevOps is allowed to bypass readiness gating, OKE will not by itself guarantee zero-downtime cutover.
- If the OKE worker subnet does not include the required private-egress routes, node registration fails and the cluster never becomes deployable.
- If the Kubernetes API endpoint and worker subnets do not expose the required control-plane security rules, node registration fails even when routing is otherwise correct.
- If operator bootstrap depends on direct laptop routing to private addresses, cluster administration fails outside the VCN even when the cluster itself is healthy.

## Alternatives Considered

- Keep Container Instances and add more deployment scripting: rejected because it does not provide the managed Kubernetes runtime target now required.
- Use separate namespaces and switch traffic at the OCI load balancer: rejected as the default because it adds unnecessary moving parts for the clarified requirement.
- Make ingress-nginx the primary slot-switch primitive: rejected as the default because ingress is the public entrypoint, not the cleanest blue-green switch primitive for this requirement.
- Reuse the existing DevOps subnet for the private Kubernetes API endpoint: rejected because it hides OKE control-plane requirements inside an unrelated runner subnet boundary.
- Reuse the existing application runtime subnet for OKE workers: rejected because the container-instance runtime subnet constraints are not a safe substitute for OKE worker-node network requirements.
- Assume direct laptop reachability to the private OKE endpoint: rejected because it breaks private-cluster administration whenever the operator is outside the VCN.
