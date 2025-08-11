#!/bin/bash
LINKS=(
    "https://gofile.io/d/2fw6NS"
)

cd "/sdcard/Download" || { echo "[!] Không thể truy cập thư mục Download"; exit 1; }

read -p "Nhập số lượng file cần tải từ mỗi folder: " MAX_FILES

download_gofile_folder() {
    local url="$1"
    local file_id
    file_id=$(echo "$url" | grep -oP '(?<=/d/)[^/]+')

    echo "[*] Lấy danh sách file từ Gofile ($file_id)..."
    json_data=$(curl -s -H "User-Agent: Mozilla/5.0" "https://api.gofile.io/getContent?contentId=${file_id}&token=&websiteToken=websiteToken&cache=true")

    links=($(echo "$json_data" | jq -r '.data.contents[].link'))
    count=0
    for direct_url in "${links[@]}"; do
        ((count++))
        if (( count > MAX_FILES )); then
            break
        fi

        file_name=$(basename "$direct_url" | cut -d'?' -f1)
        echo "[*] Tải: $file_name"
        curl -L --fail -H "User-Agent: Mozilla/5.0" -o "$file_name" "$direct_url"

        if [[ ! -s "$file_name" ]]; then
            echo "[!] Lỗi tải $file_name, file rỗng hoặc bị chặn!"
            rm -f "$file_name"
            continue
        fi

        echo "[*] Cài đặt $file_name..."
        pm install -r "$file_name"
    done
}

for URL in "${LINKS[@]}"; do
    download_gofile_folder "$URL"
done

echo "[*] Hoàn tất tất cả tác vụ!"
