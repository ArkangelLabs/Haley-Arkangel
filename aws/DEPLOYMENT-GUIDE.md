# Haley Deployment

## Setup (one-time)

```bash
# Create the Lightsail instance
aws cloudformation create-stack \
  --stack-name haley-erpnext \
  --template-body file://aws/cfn-lightsail.yaml \
  --parameters \
    ParameterKey=GitHubRepo,ParameterValue=https://github.com/YOUR_USERNAME/Haley.git

# Wait (~15-20 min)
aws cloudformation wait stack-create-complete --stack-name haley-erpnext

# Get IP
aws cloudformation describe-stacks --stack-name haley-erpnext \
  --query 'Stacks[0].Outputs[?OutputKey==`StaticIpAddress`].OutputValue' --output text
```

## Deploy (every time)

```bash
git push
```

That's it. GitHub Actions will:
1. SSH to the server
2. `git pull` your repo
3. `bench migrate`
4. `bench build`
5. Restart services

## How it works

```
┌─────────────┐     git push      ┌─────────────┐
│   Local     │ ───────────────▶  │   GitHub    │
└─────────────┘                   └──────┬──────┘
                                         │
                                         │ GitHub Actions
                                         │ (SSH + git pull)
                                         ▼
                                  ┌─────────────┐
                                  │  Lightsail  │
                                  │   Server    │
                                  └─────────────┘
```

Server structure:
```
/home/frappe/
├── haley-repo/                    ← git pull happens here
│   └── apps/
│       └── enhanced_kanban_view/
└── frappe-bench/
    └── apps/
        ├── frappe/
        ├── erpnext/
        └── enhanced_kanban_view → symlink to haley-repo
```

## Manual deploy

```bash
ssh ubuntu@<IP>
cd /home/frappe/haley-repo && sudo -u frappe git pull
cd /home/frappe/frappe-bench
sudo -u frappe bench migrate
sudo -u frappe bench build --app enhanced_kanban_view
sudo supervisorctl restart all
```

## Costs

$10/month (Lightsail small_3_0: 2GB RAM, 1 vCPU, 60GB SSD)
