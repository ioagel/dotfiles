# Cron Job Inventory

This document lists all automated cron jobs running across various servers. The goal is to maintain a clear, up-to-date inventory for operational clarity, troubleshooting, and server migrations.

**Last Updated:** 15/05/2025

---

## Table of Contents

- [Cron Job Inventory](#cron-job-inventory)
  - [Table of Contents](#table-of-contents)
  - [Server: `manager.ad.floulabs.net`](#server-manageradfloulabsnet)
    - [User: `ioangel`](#user-ioangel)
  - [Generic/Utility Scripts Referenced](#genericutility-scripts-referenced)
  - [General Notes \& Best Practices](#general-notes--best-practices)

---

## Server: `manager.ad.floulabs.net`

### User: `ioangel`

| Job Name / Purpose                      | Schedule    | Command / Script Path                                                                                    | Log File(s)                             | Dependencies / Notes                                                                                                                     | Last Reviewed |
| :-------------------------------------- | :---------- | :------------------------------------------------------------------------------------------------------- | :-------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------- | :------------ |
| **Check Expiries & Update Uptime Kuma** | `5 3 * * *` | `/home/ioangel/scripts/check-expiries -w 7 -u -p "https://kuma.www.ad.floulabs.net/api/push/vuWoMVfrNk"` | `/home/ioangel/logs/check-expiries.log` | `curl`, `jq`, Uptime Kuma instance at `manager.ad.floulabs.net`, `~/.item_expirations.txt` file, `/etc/logrotate.d/check-expiries` file. | 15/05/2025    |

---

## Generic/Utility Scripts Referenced

This section can list details for scripts that are used by multiple cron jobs or are complex enough to warrant their own documentation link.

- **Script:** `/home/ioangel/scripts/check-expiries`
  - **Purpose:** Checks for item expirations from a file and optionally pushes status to Uptime Kuma.
  - **Location in Git (if applicable):** `xdg_local/bin/check-expiries`
  - **Key Configuration:** Uses `~/.item_expirations.txt` by default, various command-line flags.

---

## General Notes & Best Practices

- Always use full paths for commands and scripts within cron jobs.
- Redirect both STDOUT and STDERR to a log file (e.g., `>> /path/to/logfile.log 2>&1`).
- Ensure the user running the cron job has the necessary permissions for the script and any files/directories it accesses.
- Regularly review this document and compare it against `crontab -l -u <username>` on each server.
- Consider using a configuration management tool (e.g., Ansible) to manage cron jobs programmatically for better consistency and to make this document a true reflection of reality.
