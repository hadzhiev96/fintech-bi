# Learning Log

## Session 1 — Environment Setup

### Docker

```powershell
docker run --name fintech-db -e POSTGRES_PASSWORD=admin123 -e POSTGRES_USER=analyst -e POSTGRES_DB=fintech -p 5432:5432 -d postgres:15
```
**What it does:** Creating an postgress db image with docker. Setting credentials and port.

---

```powershell
docker ps
```
**What it does:** Provides overview of running docker containers

---

### Git & GitHub

```powershell
git init
```
**What it does:** initializing git repo locally 

---

```powershell
git remote add origin https://github.com/hadzhiev96/fintech-bi.git
```
**What it does:** connecting local repo to remote one

---

```powershell
git pull origin main --allow-unrelated-histories
```
**What it does:** syncronizing local and remote repos, the additional specifications are required due the repos being crated independently one of another 

---

```powershell
git add LEARNING_LOG.md
```
**What it does:** adding files to the staging area, waiting to be commited

---

```powershell
git commit -m "initial commit: add learning log"
```
**What it does:** commiting files from the staging area

---

```powershell
git push origin main
```
**What it does:** uploading files to the remote repo, specifying which branch exactly

---

```powershell
git pull origin main --rebase
```
**What it does:** pulling everything from the remote repo and putting my files on top of it

---

```powershell
git branch -m master main
```
**What it does:** renaming my branch

---

```powershell
git push origin main --force
```
**What it does:** --force tells GitHub "ignore whatever you have, replace it with exactly what I'm sending you." Normally Git rejects a push if the remote has commits your local doesn't — it protects you from overwriting someone else's work. Force bypasses that protection.