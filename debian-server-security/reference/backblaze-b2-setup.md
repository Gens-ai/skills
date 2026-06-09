# Backblaze B2 — one-time bucket + write-only key (web UI)

B2 is S3-compatible object storage, pay-as-you-go. Pricing: **$6.95/TB/mo** (= $0.00695/GB/mo), **first 10 GB free, no monthly minimum** — log/DB volumes are effectively free-to-pennies. (This is B2 *Cloud Storage*, NOT the consumer "Computer Backup" product.)

## 1. Account
backblaze.com → sign up / sign in → **B2 Cloud Storage**. Add a payment method (cost is trivial at this volume).

## 2. Bucket (Buckets → Create a Bucket)
- **Name:** e.g. `your-org-logs-n-backup` (globally unique across all of B2 — add a suffix if taken).
- **Files:** Private.
- **Object Lock: ENABLE** ← critical, and it can ONLY be turned on at creation time.
- **Default Encryption:** enable SSE-B2 (free, transparent; rclone needs nothing).
- **Lifecycle:** "Keep all versions of files" (no auto-delete) — logs are tiny and longer retention is the point. (Optional: a custom "delete after 365 days" rule to cap growth.)

## 3. Default retention (after the bucket exists → bucket → Object Lock settings)
B2 does NOT ask for the retention period at creation — set it afterward.
- Default retention: **90 days** (tune to taste).
- Mode: **Governance** — stops the box's key from deleting, while you keep an account-level override. (**Compliance** = nobody, including you, can delete for the window. Maximal but unforgiving.)

## 4. Write-only application key (Application Keys → Add a New Application Key)
- **Name:** e.g. `<hostname>-box` (one key PER server — never share).
- **Allow access to Bucket:** select ONLY this bucket.
- **Type of Access:** **Write Only** (if offered) — gives `listBuckets` + `writeFiles`, no read/list/delete. (If only "Read and Write" exists, that's acceptable: Object Lock still blocks deletes — but Write-Only is stronger.)
- File prefix / Duration: leave blank.
- **Copy the keyID and applicationKey now** — the applicationKey is shown only ONCE.

## 5. Endpoint
On the bucket's page, copy the **Endpoint**: `s3.<region>.backblazeb2.com` (e.g. `s3.us-east-005.backblazeb2.com`). The region digits matter.

## 6. Feed it to the box
```
B2_KEY_ID=<keyID> B2_APP_KEY=<applicationKey> B2_ENDPOINT=s3.<region>.backblazeb2.com \
  bash scripts/setup-b2-rclone.sh
```
Set `B2_BUCKET="b2:<bucket-name>"` in `/etc/server-security/config`.

## 7. Restore key (DO THIS once, store OFF all servers) 🔑
The box keys are write-only and CANNOT restore. Create ONE **Read-Only** application key (scoped to the bucket) and keep it ONLY on your workstation / password manager — never on a server. To restore: configure a local rclone remote with it and `rclone copy b2:<bucket>/<host>/backups/<date>/<bundle> .`.

## Verifying writes (the box can't — it's write-only)
After `setup-b2-rclone.sh` runs its smoke test, check the **B2 web console → Browse Files**: the `_verify/` test object should exist AND show an **Object Lock retention date**. No lock date = default retention wasn't set in step 3.
