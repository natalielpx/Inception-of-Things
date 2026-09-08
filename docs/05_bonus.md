# Part Bonus - GitLab

## Prerequisites

### Resources

GitLab calls for a certain amount of resources:

- Verify VM has enough resources (min 4GB RAM, 2 CPUs — resize if needed)
Personally I used:

While my allocated resources are lower than recommended, it all worked out in the end. I suspect it is because our infrastructure load is minimal. Feel free to allocate the recommended amount of resources, though the 42 stations might not always be generous enough in these aspects.

### Helm

https://helm.sh/docs/intro/install/

```jsx
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh
```

### PostgreSQL

https://docs.gitlab.com/charts/advanced/external-db/external-omnibus-psql/

`/etc/gitlab/gitlab.rb`

i’ll just use AUTH_CIDR_ADDRESS=172.19.0.0/16

```yaml
# Change the address below if you do not want PG to listen on all available addresses
postgresql['listen_address'] = '0.0.0.0'
# Set to approximately 1/4 of available RAM.
postgresql['shared_buffers'] = "512MB"
# This password is: `echo -n '${password}${username}' | md5sum - | cut -d' ' -f1`
# The default username is `gitlab`
postgresql['sql_user_password'] = "DB_ENCODED_PASSWORD"
# Configure the CIDRs for MD5 authentication
postgresql['md5_auth_cidr_addresses'] = ['AUTH_CIDR_ADDRESSES']
# Configure the CIDRs for trusted authentication (passwordless)
postgresql['trust_auth_cidr_addresses'] = ['127.0.0.1/24']

## Configure gitlab_rails
gitlab_rails['auto_migrate'] = false
gitlab_rails['db_username'] = "gitlab"
gitlab_rails['db_password'] = "DB_PASSSWORD"

## Disable everything else
sidekiq['enable'] = false
puma['enable'] = false
registry['enable'] = false
gitaly['enable'] = false
gitlab_workhorse['enable'] = false
nginx['enable'] = false
prometheus_monitoring['enable'] = false
redis['enable'] = false
gitlab_kas['enable'] = false
```

```yaml
# Reconfigure package
gitlab-ctl reconfigure

# Check processes 
gitlab-ctl status
# Excpected output
# run: logrotate: (pid 4856) 1859s; run: log: (pid 31262) 77460s
# run: postgresql: (pid 30562) 77637s; run: log: (pid 30561) 77637s
```

### Redis

## **Install GitLab**

https://www.stellarhosted.com/gitlab/kubernetes/

### Phase 2 — GitLab namespace + deployment

Create `gitlab` namespace in the cluster

```jsx
kubectl create namespace gitlab
```

- Add GitLab's official Helm chart repo
- Configure `values.yaml` — critical settings:
    - Disable unnecessary components (Registry, Pages, etc.) to save RAM
    - Set it to run locally (no external domain, use `localhost` or a local IP)
    - Disable TLS or use self-signed certs
- Deploy via Helm into the `gitlab` namespace
- Wait for pods to be ready (can take 5–15 min)
- Access GitLab UI and retrieve the root password

---

### Phase 3 — GitLab configuration

- Create a GitLab user/group
- Create a new repository mirroring your GitHub one
- Push your `deployment.yaml` and config files to it
- Generate an access token for Argo CD

---

### Phase 4 — Argo CD reconfiguration

- Add your local GitLab repo as a repository in Argo CD (via token or SSH)
- Update your Argo CD `Application` manifest to point to GitLab instead of GitHub
- Verify Argo CD syncs successfully from GitLab

---

### Phase 5 — Validate the full flow

- Change the app version in your GitLab repo (`v1` → `v2`)
- Confirm Argo CD detects and syncs the change
- Confirm the pod updates and `curl localhost:8888` returns the new version

---

### Phase 6 — Cleanup + repo structure

- Move all scripts and configs into the `bonus/` folder
    - `bonus/scripts/` — install script (Docker, K3d, Helm, GitLab, Argo CD)
    - `bonus/confs/` — all manifests and `values.yaml`
- Ensure the install script is runnable from scratch for the defense