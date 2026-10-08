# -*- coding: utf-8 -*-
"""Gọi Gemini ảnh qua Vertex AI bằng tài khoản gcloud đã đăng nhập trên máy (không lưu khoá nào trong mã)."""
import base64, json, os, subprocess, sys, urllib.request, urllib.error

BASH = "C:/Program Files/Git/bin/bash.exe"  # gcloud trên máy chỉ có script bash, chạy qua Git Bash
GCLOUD = "/c/Program Files (x86)/Google/Cloud SDK/google-cloud-sdk/bin/gcloud"
PROJECT = os.environ.get("GCP_PROJECT", "")  # đặt biến môi trường GCP_PROJECT = mã project Google Cloud của bạn


def token():
    return subprocess.run([BASH, GCLOUD, "auth", "print-access-token"], capture_output=True, text=True).stdout.strip()


def generate(prompt, model="gemini-2.5-flash-image", location="global", aspect="1:1"):
    host = "aiplatform.googleapis.com" if location == "global" else f"{location}-aiplatform.googleapis.com"
    url = f"https://{host}/v1/projects/{PROJECT}/locations/{location}/publishers/google/models/{model}:generateContent"
    body = {
        "contents": [{"role": "user", "parts": [{"text": prompt}]}],
        "generationConfig": {"responseModalities": ["IMAGE"], "imageConfig": {"aspectRatio": aspect}},
    }
    req = urllib.request.Request(url, json.dumps(body).encode(), {"Authorization": "Bearer " + token(), "Content-Type": "application/json"})
    try:
        r = json.load(urllib.request.urlopen(req, timeout=180))
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"{e.code}: {e.read().decode()[:400]}")
    for c in r.get("candidates", []):
        for p in c.get("content", {}).get("parts", []):
            if "inlineData" in p:
                return base64.b64decode(p["inlineData"]["data"])
    raise RuntimeError("no image: " + json.dumps(r)[:400])


if __name__ == "__main__":
    out = generate(sys.argv[1], *(sys.argv[3:4] or []))
    open(sys.argv[2], "wb").write(out)
    print("saved", sys.argv[2], len(out))
