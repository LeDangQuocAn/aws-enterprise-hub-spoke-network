# [Project Title]

## Executive Summary

This report presents the architectural design of EduCloud's AWS enterprise network using the Top-Down Network Design methodology. EduCloud, an EdTech startup, is migrating 100% of its infrastructure to AWS and requires a secure, scalable, and centrally governed network that can reliably serve students nationwide while enabling secure operations for the DevOps team.

The proposed solution is a multi-AZ hub-and-spoke architecture centered on AWS Transit Gateway (TGW), with strict network segmentation into five dedicated VPCs (Ingress, Egress, App, Shared Services, and Management/DMZ). The design prioritizes security, high availability, operational simplicity, and automation through Terraform, Terraform Cloud, and GitHub Actions.

---

## 1. Methodology: Top-Down Network Design

This project follows a four-phase top-down approach:

1. Phase 1: Business and technical requirements
2. Phase 2: Logical network design
3. Phase 3: Physical and implementation design
4. Phase 4: Testing and optimization

This sequence ensures business goals drive technical choices, rather than selecting tools first and attempting to retrofit requirements later.

---

## 2. Phase 1 - Business and Technical Requirements

### 2.1 Business Context

EduCloud is migrating all workloads to AWS to support national-scale student access, improve service reliability, and modernize operations. The network must support continuous growth while maintaining centralized governance and strong security controls.

### 2.2 Primary Business Drivers

| Driver | Why It Matters |
|---|---|
| Nationwide service availability | Learning services must remain reachable for geographically distributed users. |
| Security and trust | Student and internal platform data must be protected under strict access boundaries. |
| Operational agility | Small engineering team needs repeatable, automated infrastructure workflows. |
| Future growth | Network must scale without major redesign as new services are added. |

### 2.3 Technical Goals

| Goal | Architectural Intent |
|---|---|
| High Availability | Deploy across multiple Availability Zones to reduce single-AZ failure impact. |
| Blast-radius reduction | Segment workloads by function across separate VPCs and route domains. |
| Centralized routing | Use TGW as a single routing control plane for spoke VPCs. |
| IaC automation | Manage infrastructure through Terraform and policy-friendly CI/CD. |

---

## 3. Phase 2 - Logical Network Design

### 3.1 Chosen Architecture Pattern: Hub-and-Spoke

The network uses hub-and-spoke with AWS Transit Gateway as the hub.

### 3.2 Why Hub-and-Spoke Instead of Full-Mesh VPC Peering

| Criteria | Hub-and-Spoke (Chosen) | Full-Mesh VPC Peering |
|---|---|---|
| Route management | Centralized and policy-oriented at TGW | Distributed and increasingly complex per peering pair |
| Scalability | Add spokes with predictable operational effort | Connection growth trends toward $O(n^2)$ |
| Governance | Strong central control of association/propagation | Harder to enforce consistent controls globally |
| Future extensibility | Easier integration with on-prem and VPN models | Less suitable for enterprise-scale transit patterns |

Architectural justification: Hub-and-spoke reduces operational complexity and supports long-term growth without exploding routing overhead.

### 3.3 Network Segmentation Model (5 VPCs)

| VPC | Logical Role | Architectural Justification |
|---|---|---|
| Ingress VPC | Internet entry point with ALB and WAF | Filters and terminates untrusted traffic before east-west/internal access. |
| Egress VPC | Central outbound internet path via NAT Gateways | Simplifies egress governance and partner IP allowlisting. |
| App VPC | Private application and database workloads | Eliminates direct internet exposure for core systems. |
| Shared Services VPC | Internal shared tools (CI/CD runners, monitoring, platform services) | Avoids duplicating common services across application VPCs. |
| DMZ/Management VPC | Administrative/control-plane access zone | Isolates management traffic and access tooling from workload planes. |

### 3.4 IP Addressing Strategy

- Supernet: `10.10.0.0/16`
- Non-overlapping subnet allocation per VPC using variable-sized blocks (`/24`, `/22`, `/21`) according to expected growth per domain.
- Dedicated `/28` subnets in each AZ are reserved for TGW attachments.

Architectural justification:
- Non-overlapping CIDR planning prevents route ambiguity and simplifies future interconnectivity.
- Variable block sizing aligns IP allocation with actual workload growth to reduce renumbering risk.
- Dedicated TGW attachment subnets improve routing control and align with AWS best-practice operational patterns.

---

## 4. Phase 3 - Physical and Implementation Design

### 4.1 Core AWS Services

| Service | Purpose in Design |
|---|---|
| AWS Transit Gateway | Central hub for VPC-to-VPC and external connectivity routing. |
| VPCs | Security and functional segmentation boundaries. |
| Internet Gateway (IGW) | Public internet access path for designated public segments. |
| NAT Gateway | Controlled outbound internet access for private workloads. |

### 4.2 Security Architecture Decisions

Decision: Use AWS Systems Manager (SSM) Session Manager instead of traditional bastion hosts exposed via public SSH.

Why this decision was made:
- Removes need to open inbound port 22 from the internet.
- Reduces attack surface by avoiding public IP dependency for admin access.
- Provides identity-centric and auditable remote access through AWS-native controls.
- Better aligns with least-privilege and modern cloud security practices.

### 4.3 Automation and Delivery Stack

| Component | Design Role | Why It Was Chosen |
|---|---|---|
| Terraform (modular) | Declarative infrastructure provisioning | Repeatability, versioned change control, and reusable modules. |
| Terraform Cloud | Remote state, locking, and secure variable management | Prevents state drift/corruption and supports team collaboration. |
| GitHub Actions | CI/CD execution for plan/apply workflows | Standardized validation pipeline on pull requests and main branch. |

---

## 5. Phase 4 - Testing and Optimization (Future Scope)

### 5.1 Functional Validation Target

Expected traffic path for private application workloads:

`App VPC -> TGW -> Egress VPC -> NAT Gateway -> Internet`

Validation objective:
- Confirm outbound internet connectivity from private workloads without exposing private subnets directly to the internet.

### 5.2 Cost Optimization Strategy

For academic/lab usage patterns, infrastructure can be de-provisioned outside working hours using Terraform destroy workflows to reduce hourly TGW and NAT Gateway charges.

Rationale:
- TGW and NAT incur recurring hourly costs even at low traffic volume.
- Scheduled lifecycle management provides cost control while preserving IaC reproducibility.

---

## 6. Final Architecture Diagram

```text
                               +----------------------+
                               |     Internet Users   |
                               +----------+-----------+
                                          |
                                          v
                               +----------------------+
                               |   Ingress VPC (DMZ)  |
                               |   ALB + WAF Layer    |
                               +----------+-----------+
                                          |
                                          v
                               +----------------------+
                               | AWS Transit Gateway  |
                               |        (Hub)         |
                               +----+----+----+----+--+
                                    |    |    |    |
          +-------------------------+    |    |    +-------------------------+
          |                              |    |                              |
          v                              v    v                              v
   +-------------------+        +-------------------+        +------------------------+
   |     App VPC       |        |    Egress VPC     |        | Shared Services VPC    |
   |  Private Apps     |        |   NAT Gateways    |        | CI/CD, Monitoring      |
   |  Databases        |        |   Internet Exit   |        | Internal Tools         |
   +---------+---------+        +---------+---------+        +------------------------+
             |                             |
             |                             v
             |                    +----------------------+
             |                    |   Internet Egress    |
             |                    +----------------------+
             |
             v
   +------------------------+
   |  DMZ/Management VPC    |
   |  SSM Session Manager   |
   |  Admin Access Zone     |
   +------------------------+

   Transit Gateway attachments use dedicated /28 subnets in each AZ
   to keep routing control explicit and operationally clean.
```

---

## 7. Key Architectural Justifications (Summary)

1. Hub-and-spoke with TGW was selected for centralized governance, lower routing complexity, and enterprise scalability.
2. Five-VPC segmentation reduces blast radius and enforces clear trust boundaries between traffic types.
3. Dedicated ingress and egress planes improve security posture and policy control over internet flows.
4. Private App VPC design protects core workloads by default.
5. SSM Session Manager replaces SSH bastions to reduce exposed attack surface.
6. Terraform + Terraform Cloud + GitHub Actions establish a secure, auditable, and repeatable delivery pipeline.

---

## 8. Conclusion

The EduCloud network architecture is intentionally designed from requirements to implementation, following Top-Down Network Design principles. The resulting model supports high availability, secure segmentation, centralized control, and operational automation, while remaining extensible for later phases such as advanced routing policy, on-premises integration, and full validation testing.

This report provides the architectural foundation for iterative implementation and optimization across subsequent project milestones.
