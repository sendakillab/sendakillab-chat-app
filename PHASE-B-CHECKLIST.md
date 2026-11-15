# Phase B Entry Checklist

Do not start AWS migration until this Git baseline is complete.

- [ ] `chat-app` has its own Git repository
- [ ] `.gitignore` is present
- [ ] `.env` is ignored
- [ ] `.env.example` is committed
- [ ] Phase A source is committed
- [ ] Remote repository is configured
- [ ] `main` is pushed
- [ ] `phase-a-local-mvp` tag is pushed
- [ ] Start script still works
- [ ] Stop script still works
- [ ] Chat flow still works
- [ ] Existing history is still present

Then create:

```powershell
git checkout -b phase-b/aws-mvp
```

Phase B should start from this branch rather than changing the stable Phase A baseline directly.
