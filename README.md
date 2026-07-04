# AWS ALB Path-Based Routing Project

A hands-on AWS project demonstrating **path-based routing** using an Application
Load Balancer (ALB), with backend EC2 instances distributed across multiple
Availability Zones for high availability.

## Architecture

![Architecture Diagram](/architecture-diagram.png)

Requests are routed based on URL path:

| Path         | Target Group   | Instance    | Response      |
|--------------|-----------------|-------------|---------------|
| `/`          | `tg-homepage`   | Instance A  | `Homepage!`   |
| `/images`    | `tg-images`     | Instance B  | `Images!`     |
| `/register`  | `tg-register`   | Instance C  | `Register!`   |

## Components

- **VPC** (`10.0.0.0/16`) with 2 public subnets across 2 Availability Zones
- **Internet Gateway** attached to the VPC, with a public route table
  (`0.0.0.0/0 -> IGW`) associated with both subnets
- **2 Security Groups**:
  - `alb-sg` — allows inbound HTTP (80) from `0.0.0.0/0`
  - `ec2-instances-sg` — allows inbound HTTP (80) **only from `alb-sg`**, and SSH
    (22) restricted to a specific IP (never opened to the internet)
- **3 EC2 instances** (t2.micro, Amazon Linux 2023), each running Nginx via a
  `user_data` bootstrap script — see [`user_data/`](./user_data)
- **3 Target Groups**, each with a health check path matching its instance's
  actual content path (important: `/images/` and `/register/` need explicit
  health check paths — the default `/` will falsely report them unhealthy)
- **1 Application Load Balancer** spanning both AZs, with path-based listener
  rules evaluated in priority order

## Listener Rule Priority

The ALB evaluates rules in order (lowest priority number first) and stops at
the first match:

| Priority | Condition                          | Action                  |
|----------|-------------------------------------|--------------------------|
| 10       | Path = `/images`, `/images/*`       | Forward → `tg-images`   |
| 20       | Path = `/register`, `/register/*`   | Forward → `tg-register` |
| Default  | (no match)                          | Forward → `tg-homepage` |

## How to Deploy

1. Create the VPC, subnets (2 AZs), Internet Gateway, and public route table
2. Create the two security groups (`alb-sg`, `ec2-instances-sg`)
3. Launch 3 EC2 instances (t2.micro), one per AZ pairing as shown in the
   diagram, using the corresponding script from [`user_data/`](./user_data)
   as the instance's user data
4. Create 3 target groups with the health check paths noted above, and
   register each instance to its matching target group
5. Create the ALB (Internet-facing, spanning both subnets/AZs), attach
   `alb-sg`, and set the default listener action to forward to `tg-homepage`
6. Add the two additional listener rules for `/images` and `/register` per
   the priority table above
7. Verify: hit the ALB's DNS name at `/`, `/images/`, and `/register/` and
   confirm each returns the correct response

## Verification

Tested via both browser and `curl` against the ALB's public DNS name:

```bash
curl http://<alb-dns-name>/
curl http://<alb-dns-name>/images/
curl http://<alb-dns-name>/register/
```

Each returned the expected instance-specific response, confirming the ALB
correctly evaluates path conditions and routes to the right target group.

## Debugging Notes (real issues hit during this build)

- **SSH connection timeouts**: root-caused to the public subnets not being
  associated with the custom route table containing the `0.0.0.0/0 -> IGW`
  route. Subnets not explicitly associated with a route table silently fall
  back to the VPC's default "main" route table, which has no internet route —
  the instance has a public IP and looks fine in the console, but nothing can
  reach it. Fixed by explicitly associating both subnets with the public
  route table.
- **Target groups stuck on health check failures**: caused by health check
  paths defaulting to `/`, which doesn't exist on the `/images` and
  `/register` instances. Fixed by setting each target group's health check
  path to match its instance's actual content path.



## Repo Structure

```
.
├── README.md
├── diagrams/
│   ├── architecture-diagram.svg
│   └── architecture-diagram.png
├── user_data/
│   ├── instance-a-homepage.sh
│   ├── instance-b-images.sh
│   └── instance-c-register.sh

```
