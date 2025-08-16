#!/usr/bin/env bash
# ================================
# GoFile Downloader (Public files)
# Tải toàn bộ file từ link GoFile public về /sdcard/Download
# Tự động cài curl + jq nếu thiếu
# ================================

set -euo pipefail

# ==========================
# Auto install dependencies
# ==========================
for pkg in curl jq; do
  if ! command -v $pkg >/dev/null 2>&1; then
    echo "[*] Đang cài $pkg..."
    if command -v pkg >/dev/null 2>&1; then
      pkg install -y $pkg
    elif command -v apt >/dev/null 2>&1; then
      sudo apt update && sudo apt install -y $pkg
    elif command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update && sudo apt-get install -y $pkg
    else
      echo "[!] Không tìm thấy pkg/apt để cài $pkg. Vui lòng cài thủ công."
      exit 1
    fi
  fi
done

# ==========================
# Nhận link GoFile
# ==========================
ARG=${1:-}
if [[ -z "$ARG" ]]; then
  echo "Cách dùng: $0 <link GoFile hoặc contentId>"
  exit 1
fi

# Lấy contentId từ link hoặc giữ nguyên nếu chỉ là ID
ID="${ARG##*/}"; ID="${ID%%\?*}"

DEST="$HOME/sdcard/Download/$ID"
mkdir -p "$DEST"

echo "[*] Lấy website token..."
WT="$(curl -fsSL 'https://gofile.io/dist/js/alljs.js' | tr -d '\n' \
     | sed -n 's/.*wt[[:space:]]*:[[:space:]]*"\([^"]\+\)".*/\1/p')"
if [[ -z "${WT}" ]]; then
  echo "[!] Không lấy được website token"
  exit 1
fi

echo "[*] Tạo guest token..."
GUEST="$(curl -fsSL 'https://api.gofile.io/createAccount' | jq -r '.data.token')"

API_URL="https://api.gofile.io/getContent?contentId=${ID}&wt=${WT}&cache=true"
[[ -n "$GUEST" ]] && API_URL="${API_URL}&token=${GUEST}"

echo "[*] Lấy metadata..."
RESP="$(curl -fsSL "$API_URL")"

if ! echo "$RESP" | jq -e '.status=="ok"' >/dev/null 2>&1; then
  echo "[!] Lỗi: Không thể lấy dữ liệu từ GoFile"
  echo "---- Phản hồi ----"
  echo "$RESP" | head -c 2000; echo
  exit 1
fi

# Lấy danh sách file
mapfile -t NAMES < <(jq -r '.data.contents | to_entries[] | select(.value.type=="file") | .value.name' <<<"$RESP")
mapfile -t LINKS < <(jq -r '.data.contents | to_entries[] | select(.value.type=="file") | .value.link' <<<"$RESP")

if ((${#LINKS[@]}==0)); then
  echo "[!] Không tìm thấy file nào trong link."
  exit 1
fi

echo "[*] Bắt đầu tải về: $DEST"
for i in "${!LINKS[@]}"; do
  name="${NAMES[$i]:-file_$i}"
  link="${LINKS[$i]}"
  echo "↓ $name"
  curl -fL --retry 3 --retry-delay 2 \
    -H "Cookie: accountToken=${GUEST}" \
    -o "$DEST/$name" "$link"
done

echo "✅ Hoàn tất. File đã được lưu ở $DEST"
echo "👉 Nếu Termux báo permission, hãy chạy: termux-setup-storage"
