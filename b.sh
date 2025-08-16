#!/data/data/com.termux/files/usr/bin/bash
# Script tải file GoFile về /sdcard/Download
# Yêu cầu: curl, jq

# Cài đặt nếu thiếu
for pkg in curl jq; do
    if ! command -v $pkg >/dev/null 2>&1; then
        echo "[*] Cài đặt $pkg..."
        pkg install -y $pkg
    fi
done

# Nhập link GoFile
read -p "Nhập link GoFile: " GOFILE_URL

# Lấy contentId từ URL
FILE_ID=$(echo "$GOFILE_URL" | sed -E 's#.*/d/([^/]+).*#\1#')

if [ -z "$FILE_ID" ]; then
    echo "[!] Không lấy được fileId từ link."
    exit 1
fi

echo "[*] File ID: $FILE_ID"

# Lấy thông tin server API
SERVER=$(curl -s https://api.gofile.io/servers | jq -r '.data.servers[0].name')

if [ -z "$SERVER" ] || [ "$SERVER" == "null" ]; then
    echo "[!] Không lấy được server tải."
    exit 1
fi

echo "[*] Server: $SERVER"

# Gọi API getContent để lấy link download
RESPONSE=$(curl -s "https://api.gofile.io/getContent?contentId=$FILE_ID")

if ! echo "$RESPONSE" | grep -q '"status":"ok"'; then
    echo "[!] Lỗi API getContent:"
    echo "$RESPONSE"
    exit 1
fi

# Lấy direct link đầu tiên
DL_URL=$(echo "$RESPONSE" | jq -r '.data.contents[] | .link' | head -n 1)

if [ -z "$DL_URL" ] || [ "$DL_URL" == "null" ]; then
    echo "[!] Không lấy được link tải."
    exit 1
fi

echo "[*] Link tải: $DL_URL"

# Tải file về Download
DEST="/sdcard/Download"
mkdir -p "$DEST"

echo "[*] Đang tải về $DEST ..."
curl -L "$DL_URL" -o "$DEST/$(basename "$DL_URL")"

echo "[✔] Hoàn tất!"
