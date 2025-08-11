#!/bin/bash
LINKS=(
    "https://gofile.io/d/abc123"
    "https://gofile.io/d/xyz456"
)

cd "/sdcard/Download" || { echo "[!] Không thể truy cập thư mục Download"; exit 1; }

# Hỏi số lượng file cần tải
read -p "Nhập số lượng file cần tải từ mỗi folder: " MAX_FILES

download_gofile_folder() {
    local url="$1"
    local file_id
    file_id=$(echo "$url" | grep -oP '(?<=/d/)[^/]+')

    echo "[*] Lấy danh sách file từ Gofile ($file_id)..."
    json_data=$(curl -s "https://api.gofile.io/getContent?contentId=${file_id}&token=&websiteToken=websiteToken&cache=true")

    # Lấy danh sách link direct
    links=($(echo "$json_data" | grep -oP '(?<="link":")[^"]+'))

    count=0
    for direct_url in "${links[@]}"; do
        ((count++))
        if (( count > MAX_FILES )); then
            break
        fi

        file_name=$(basename "$direct_url" | cut -d'?' -f1)
        echo "[*] Tải: $file_name"
        curl -L -o "$file_name" "$direct_url"

        echo "[*] Cài đặt $file_name..."
        pm install -r "$file_name"
    done
}

for URL in "${LINKS[@]}"; do
    download_gofile_folder "$URL"
done

echo "[*] Hoàn tất tất cả tác vụ!"
