# ADR-0009: Use Private Networking for OCI Runtime

## Status
Accepted

## Context

Wort-Werk currently exposes a stable public endpoint through an OCI Load Balancer, but the runtime container instance still receives a public IP address. That makes the application tier directly internet-addressable even though the intended public entrypoint is the Load Balancer. The runtime also depends on OCI Vault at startup to resolve the database password, so removing the public IP cannot break OCI service access.

## Decision

Adopt the following OCI runtime networking model:

1. Keep the OCI Load Balancer on a public subnet with the reserved public IP.
2. Place the Wort-Werk container instance on a dedicated private subnet.
3. Do not assign public IP addresses to runtime container instance VNICs.
4. Route runtime access to required OCI regional services through private OCI networking instead of container public internet exposure.

## Consequences

Positive:
- The application tier is no longer directly reachable from the public internet.
- Public ingress is forced through the Load Balancer, which is the intended traffic control point.
- Runtime secret retrieval can remain available without weakening the network boundary.

Negative:
- Foundation networking becomes more complex because runtime and load balancer concerns now require separate subnet roles.
- Private OCI service access must be configured correctly or runtime startup can fail.

Risks:
- If a future runtime dependency requires unrestricted public internet egress, additional outbound design work such as a NAT path may be required.

## Alternatives Considered

- Keep the container instance in the current public subnet and simply disable public IP assignment: better than the current state, but weaker and less explicit than a dedicated private application subnet.
- Keep the container instance public and rely only on NSGs: rejected because it leaves an unnecessary internet-facing surface on the application tier.
