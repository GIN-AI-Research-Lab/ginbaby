# Build bản web mới và để máy chủ phục vụ ngay (người dùng chỉ cần tải lại trang).
$ErrorActionPreference = 'Continue'
$env:Path = "F:\dev\flutter\bin;$env:Path"
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$app = Split-Path -Parent $PSScriptRoot
Set-Location $app

# tạo bản tranh cho chế độ tối từ assets/art (nếu có Python + numpy + Pillow)
$dark = Join-Path $app '..\design\tool\make_dark_art.py'
if (Test-Path $dark) { python $dark | Out-Null }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
flutter build web --release --no-wasm-dry-run --no-web-resources-cdn --dart-define=BUILD=$stamp 2>&1 | ForEach-Object { "$_" } | Select-Object -Last 5
if ($LASTEXITCODE -ne 0) { throw "build lỗi" }

# Service worker của Flutter không còn hỗ trợ ngoại tuyến: thay bằng sw.js riêng (tạo từ web/sw.template.js).
Set-Content -Path "$app\build\web\version.json" -Value "{`"build`":`"$stamp`"}" -Encoding ascii
python "$app\tool\make_sw.py" $stamp

# bảo đảm máy chủ không-cache đang chạy trên cổng 8090
$listening = Get-NetTCPConnection -LocalPort 8090 -State Listen -ErrorAction SilentlyContinue
if (-not $listening) {
  Start-Process -WindowStyle Hidden -FilePath python -ArgumentList "`"$app\tool\serve.py`"", '8090'
  Start-Sleep -Seconds 2
}
"Đã cập nhật bản $stamp"
