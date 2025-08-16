#!/bin/bash
read -p "Nhập link GoFile (vd: https://gofile.io/d/abcdxxx): " GOFILE_URL
FILE_ID=$(echo "$GOFILE_URL" | sed -E 's#.*/d/([^/]+).*#\1#')
DEST_DIR="$HOME/sdcard/Download"
mkdir -p "$DEST_DIR"
API_URL="https://api.gofile.io/getContent"

echo "[*] Đang lấy link tải từ GoFile..."
response=$(curl -s "$API_URL?contentId=$FILE_ID&websiteToken=12345")
if ! echo "$response" | grep -q '"status":"ok"'; then
    echo "[!] Lỗi: Không thể lấy dữ liệu từ GoFile"
    exit 1
fi
links=$(echo "$response" | grep -o '"link":"[^"]*' | cut -d'"' -f4)
names=$(echo "$response" | grep -o '"name":"[^"]*' | cut -d'"' -f4)
while read -r url && read -r name <&3; do
    echo "[*] Đang tải: $name"
    curl -L --output "$DEST_DIR/$name" "$url"
done <<< "$links" 3<<< "$names"

echo "[✓] Hoàn tất. File đã được lưu ở $DEST_DIR"
