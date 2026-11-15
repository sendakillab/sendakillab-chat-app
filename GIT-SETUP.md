# SendakilLab Git Setup

Recommended model: **one Git repository per SendakilLab project**.

Current repository root:

```text
C:\MyLab\sendakillab\projects\chat-app
```

Future projects can have their own repositories:

```text
C:\MyLab\sendakillab\projects\project-02
C:\MyLab\sendakillab\projects\project-03
```

## 1. Check Git

```powershell
git --version
```

## 2. Enter the project

```powershell
cd C:\MyLab\sendakillab\projects\chat-app
```

## 3. Copy these baseline files into the project root

- `.gitignore`
- `.env.example`
- `README.md`

Do not overwrite a README you want to keep without reviewing it first.

## 4. Confirm secrets are ignored

```powershell
git check-ignore .env
```

Expected output:

```text
.env
```

Also check what Git would see:

```powershell
git status
```

Confirm these are NOT staged:

- `.env`
- logs
- Flutter `build`
- `.dart_tool`
- model files
- Docker data
- database runtime data

## 5. Initialize Git

```powershell
git init
git branch -M main
```

If your Git identity is not already configured:

```powershell
git config --global user.name "YOUR NAME"
git config --global user.email "YOUR EMAIL"
```

## 6. First commit

```powershell
git add .
git status
```

Review the staged files carefully.

Then:

```powershell
git commit -m "Phase A local MVP baseline"
```

## 7. Create a remote repository

Recommended: create a **private** GitHub/GitLab/Bitbucket repository named something like:

```text
sendakillab-chat-app
```

Do not initialize the remote with another README if your local repo already has one.

## 8. Connect the remote

Example:

```powershell
git remote add origin https://github.com/YOUR_ACCOUNT/sendakillab-chat-app.git
git remote -v
```

## 9. Push Phase A baseline

```powershell
git push -u origin main
```

## 10. Create a Phase A tag

After confirming the push:

```powershell
git tag -a phase-a-local-mvp -m "Stable Phase A local MVP"
git push origin phase-a-local-mvp
```

This gives you a clean restore point before AWS changes.

## Suggested development branches for Phase B

```powershell
git checkout -b phase-b/aws-mvp
```

Later feature branches could be:

```text
feature/aws-ec2
feature/flutter-web-deploy
feature/rds
feature/vllm
```

## Daily workflow

Before changes:

```powershell
git pull
git status
```

After changes:

```powershell
git add .
git commit -m "Describe the change"
git push
```

## Important

Never commit:

- `.env`
- passwords
- AWS access keys
- model files
- Docker Desktop data
- PostgreSQL data volumes
- large generated build output
