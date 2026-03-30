# reMarkable Cloud Authentication (One-Time Setup)

## Steps

1. Open https://my.remarkable.com/device/desktop/connect in a browser
2. Log in with your reMarkable account
3. Copy the 8-character code shown
4. Run:

```bash
RMAPI_CONFIG=~/.remarkable-loop/.rmapi rmapi
```

5. Paste the code when prompted
6. Done. The token persists in `~/.remarkable-loop/.rmapi`.

## Verify

```bash
RMAPI_CONFIG=~/.remarkable-loop/.rmapi rmapi ls /
```

You should see your reMarkable folder structure.

## If It Breaks

reMarkable may invalidate tokens after firmware updates. If `rmapi` stops working:
1. Delete `~/.remarkable-loop/.rmapi`
2. Repeat the steps above
